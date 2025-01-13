terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  required_version = ">= 1.1.8"
}

locals {
  vpc_id = var.networking_module.vpc_id
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "${var.cloudwatch_module.log_group_prefix}/app"
  retention_in_days = var.cloudwatch_module.log_group_retention_in_days
  kms_key_id        = var.cloudwatch_module.kms_arn
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# TODO(P2): Limit number of iamges kept:
# https://engineering.finleap.com/posts/2020-02-20-ecs-fargate-terraform/

resource "aws_iam_role" "ecs_task" {
  name = "${var.project}-${var.environment}-ecs-task-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
  # See https://aws.amazon.com/blogs/containers/new-using-amazon-ecs-exec-access-your-containers-fargate-ec2/
  # for policy required for exec action
  inline_policy {
    name = "s3_policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "s3:ListAllMyBuckets"
          ],
          "Effect" : "Allow",
          "Resource" : "*"
        },
        {
          "Action" : "s3:*",
          "Effect" : "Allow",
          "Resource" : ["${aws_s3_bucket.app.arn}", "${aws_s3_bucket.app.arn}/*"]
        }
      ]
    })
  }

  inline_policy {
    name   = "efs_policy"
    policy = local.efs_access_policy
  }

  inline_policy {
    name   = "lambda_policy"
    policy = local.lambda_access_policy
  }
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# TODO(P1): Add ECR and SSM permissions
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
# Role to delegate permissions to ECS
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project}-${var.environment}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
      }
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
  # maybe https://sysadmins.co.za/difference-with-ecs-task-and-execution-iam-roles-on-aws/ for kms
  inline_policy {
    name = "ssm_param_policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:GetParameters",
            "kms:Decrypt",
          ],
          "Resource" : "*" # TODO(P2)
        }
      ]
    })
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_ecs_cluster" "this" {
  name = "${var.project}-${var.environment}-ecs-cluster"
  configuration {
    # Only affects execute-command sessions
    execute_command_configuration {
      kms_key_id = var.cloudwatch_module.kms_arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.app.name
      }
    }
  }
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  # TODO log_configuration
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE"]
}

locals {
  container_name         = "${var.project}-${var.environment}-app-container"
  task_definition_family = "${var.project}-${var.environment}-app-task-def"
  // Default AZ for the db and app. AWS may change AZ if default goes down.
  one_zone_az_name             = var.networking_module.one_zone_az_name
  one_zone_public_subnet_id    = var.networking_module.one_zone_public_subnet_id
  container_port               = tostring(var.ecr_module.geomatch_app_container_port)
  container_port_num           = tonumber(local.container_port)
  app_efs_volume_name          = "${var.project}-${var.environment}-efs-volume"
  app_efs_container_mount_path = "/data/efs" # in container
  gm_container_url             = "${var.ecr_module.geomatch_app_ecr_repo_url}:${var.geomatch_version}"
}

resource "aws_ecs_task_definition" "this" {
  family = local.task_definition_family
  container_definitions = jsonencode([
    {
      "name" : local.container_name,
      "image" : local.gm_container_url
      "essential" : true,
      # TODO consider limiting DNS to AWS if only network ability
      # needed is S3
      "portMappings" : [
        {
          "hostPort" : local.container_port_num,
          "containerPort" : local.container_port_num,
          "protocol" : "tcp"
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.app.name,
          "awslogs-region" : var.aws_region,
          "awslogs-stream-prefix" : var.geomatch_version,
          "awslogs-datetime-format" : "\\[%Y-%m-%d %H:%M:%S%L\\]"
        }
      },
      "healthCheck" : {
        "command" : ["CMD-SHELL", "if [ \"$SKIP_HEALTHCHECK\" = \"true\" ]; then exit 0; else curl -f http://localhost:${local.container_port}/health/ || exit 1; fi"],
        "retries" : 5,
        "interval" : 60,
        "startPeriod" : 3,
        "timeout" : 5,
      },
      # TODO(P2): Recieve extra env var as input using template
      "environment" : [
        {
          "name" : "SKIP_HEALTHCHECK",
          "value" : "false"
        },
        {
          "name" : "GEOMATCH_DATABASE_HOST",
          "value" : aws_db_instance.this.address
        },
        {
          "name" : "AWS_REGION",
          "value" : var.aws_region
        },
        {
          "name" : "S3_BUCKET",
          "value" : aws_s3_bucket.app.bucket
        },
        {
          "name" : "GEOMATCH_VERSION",
          "value" : var.geomatch_version
        },
        {
          "name" : "GEOMATCH_GITHUB_REPO",
          "value" : var.github_geomatch_app_repo
        },
        {
          "name" : "CONTAINER_PORT",
          "value" : local.container_port
        },
        {
          "name" : "EFS_DIR",
          "value" : local.app_efs_container_mount_path
        },
        {
          "name" : "R_LAMBDA_NAME",
          "value" : local.r_lambda_name
        },
        {
          "name" : "EMAIL_SENDER_DOMAIN",
          "value" : var.ses_module.sender_domain
        },
        {
          "name" : "EMAIL_HOST",
          "value" : var.ses_module.smtp_host
        },
        {
          "name" : "EMAIL_HOST_USER",
          "value" : var.ses_module.smtp_host_user
        },
        {
          "name" : "EMAIL_HOST_PASSWORD",
          "value" : var.ses_module.smtp_host_password
        },
        {
          "name" : "COGNITO_REGION",
          "value" : var.cognito_module.cognito_region
        },
        {
          "name" : "COGNITO_CLIENT_ID",
          "value" : var.cognito_module.cognito_client_id
        },
        {
          "name" : "COGNITO_USER_POOL_ID",
          "value" : var.cognito_module.cognito_user_pool_id
        },
        {
          "name" : "COGNITO_CLIENT_SECRET",
          "value" : var.cognito_module.cognito_client_secret
        },
        {
          "name" : "COGNITO_REDIRECT_URI",
          "value" : var.cognito_module.cognito_redirect_uri
        },
        {
          "name" : "COGNITO_APP_DOMAIN",
          "value" : var.cognito_module.cognito_app_domain
        },
        {
          "name" : "COGNITO_AUTHORIZATION_ENDPOINT",
          "value" : var.cognito_module.cognito_authorization_endpoint
        },
        {
          "name" : "COGNITO_ALLOW_DOMAIN",
          "value" : var.cognito_module.cognito_allow_domain
        },           
      ],
      "secrets" : [
        {
          "name" : "BLS_API_KEY",
          "valueFrom" : data.aws_ssm_parameter.bls_api_key.arn
        },
        {
          "name" : "GITHUB_ACTION_TOKEN",
          "valueFrom" : data.aws_ssm_parameter.github_action_token.arn
        },
        {
          "name" : "GEOMATCH_DATABASE_PASSWORD",
          "valueFrom" : data.aws_ssm_parameter.db_password.arn
        },
        {
          "name" : "GEOMATCH_DATABASE_USERNAME",
          "valueFrom" : data.aws_ssm_parameter.db_username.arn
        },
        {
          "name" : "GEOMATCH_DATABASE_NAME",
          "valueFrom" : data.aws_ssm_parameter.db_name.arn
        },
        {
          "name" : "GEOMATCH_DATABASE_PORT",
          "valueFrom" : data.aws_ssm_parameter.db_port.arn
        },
        {
          "name" : "APP_HOSTS",
          "valueFrom" : data.aws_ssm_parameter.django_app_hosts.arn
        },
        # Passed to GitHub secrets and to the app container so both
        # can run ECS tasks.
        # TODO: this causes a cycle
        # {
        #   "name" : "ECS_RUN_CONFIG",
        #   "valueFrom" : aws_ssm_parameter.ecs_run_task_config.arn
        # },
        {
          "name" : "RUN_R_REMOTELY",
          "valueFrom" : data.aws_ssm_parameter.run_r_remotely.arn
        },
        {
          "name" : "DJANGO_SECRET_KEY",
          "valueFrom" : data.aws_ssm_parameter.django_secret_key.arn
        },
        {
          "name" : "DJANGO_SETTINGS_MODULE",
          "valueFrom" : data.aws_ssm_parameter.django_settings_module.arn
        },
        {
          "name" : "ERROR_EMAIL",
          "valueFrom" : data.aws_ssm_parameter.django_error_email.arn
        },
      ],
      # The below are specified because otherwise AWS will silently write these
      # which will cause a diff during the next 'terraform apply'
      "cpu" : 0,
      "volumesFrom" : [],
      "mountPoints" : [
        {
          "sourceVolume" : local.app_efs_volume_name,
          "containerPath" : local.app_efs_container_mount_path,
          "readOnly" : false
        }
      ]
    }
  ])
  volume {
    name = local.app_efs_volume_name
    efs_volume_configuration {
      file_system_id     = var.efs_module.file_system_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.this.id
        iam             = "ENABLED"
      }
    }
  }
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  cpu    = var.app_cpu
  memory = var.app_memory

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_ecs_service" "this" {
  name                 = "${var.project}-${var.environment}-ecs-service"
  launch_type          = "FARGATE"
  cluster              = aws_ecs_cluster.this.id
  task_definition      = aws_ecs_task_definition.this.arn
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    # security_groups = [aws_security_group.allow_internal.id]
    # Public subnet becuase Fargate 1.4 needs outbound connections to AWS resources:
    # https://stackoverflow.com/questions/61265108/aws-ecs-fargate-resourceinitializationerror-unable-to-pull-secrets-or-registry
    subnets          = [local.one_zone_public_subnet_id]
    assign_public_ip = true

    // Do we need both security groups here?
    // This is from https://dev.to/thnery/create-an-aws-ecs-cluster-using-terraform-g80
    security_groups = [
      aws_security_group.app.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = local.container_name
    container_port   = local.container_port_num
  }

  depends_on = [aws_lb_listener.https, aws_lb_listener.http]
}

resource "aws_security_group" "db" {
  name   = "${var.project}-${var.environment}-db-sg"
  vpc_id = local.vpc_id

  ingress {
    from_port       = tonumber(data.aws_ssm_parameter.db_port.value)
    to_port         = tonumber(data.aws_ssm_parameter.db_port.value)
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  // TODO(P3): Limit egress?
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "app" {
  name   = "${var.project}-${var.environment}-app-sg"
  vpc_id = local.vpc_id

  // TODO(P1): Limit ingress to app port and ssh
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    // "This allows traffic based on the private IP addresses
    // of the resources associated with the specified security group."
    security_groups = [aws_security_group.alb.id]
  }

  // TODO(P1): Limit egress to db, email, efs, and S3
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "alb" {
  name   = "${var.project}-${var.environment}-alb-sg"
  vpc_id = local.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    // TODO(P1): Limit or remove?
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  // TODO(P1): Limit to app security group (health check port and container_port)
  // See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-update-security-groups.html#security-group-recommended-rules
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Project     = var.project
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

// "If you're using Application Load Balancers, then cross-zone load balancing is always turned on."
// We only run in one AZ, but use all public subnets anyway.
resource "aws_alb" "this" {
  name                       = "${var.project}-${var.environment}-alb"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = data.aws_subnets.public.ids
  security_groups            = [aws_security_group.alb.id]
  enable_deletion_protection = true
  # TODO(P1): remove if polling
  idle_timeout = 60 * 40

  # TODO access logs (although Django already collects this)

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "this" {
  name        = "${var.project}-${var.environment}-target-group"
  port        = local.container_port_num
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/health/"
    unhealthy_threshold = "2"
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_alb.this.id
  port              = "443"
  protocol          = "HTTPS"
  // TODO Make this default to subdomain.geomatch.org cert in ssl.tf
  certificate_arn = data.aws_acm_certificate.this.arn
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.this.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# resource "aws_lb_listener_certificate" "staging" {
#   listener_arn    = aws_lb_listener.https.arn
#   certificate_arn = aws_acm_certificate.example.arn
# }

resource "aws_db_parameter_group" "this" {
  name   = "${var.project}-${var.environment}-db-parameter-group"
  family = "postgres14"

  parameter {
    name  = "rds.log_retention_period"
    value = var.db_log_retention
  }
}

# An RDS subnet group has to have multiple AZs / subnets,
# even though RDS itself is single-AZ
resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db-group"
  subnet_ids = data.aws_subnets.private.ids

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_db_instance" "this" {
  identifier                 = replace("${var.project}-${var.environment}-db", "-", "")
  instance_class             = var.db_instance_class
  allocated_storage          = 20
  max_allocated_storage      = 1000
  storage_type               = "gp2"
  engine                     = "postgres"
  engine_version             = "14"
  auto_minor_version_upgrade = true
  skip_final_snapshot        = true
  availability_zone          = local.one_zone_az_name
  multi_az                   = false
  backup_retention_period    = 35
  storage_encrypted          = true
  parameter_group_name       = aws_db_parameter_group.this.name
  # TODO unfortunately I couldn't find a setting in AWS for changing
  # the cloudwatch log group for RDS. But ideally this would use the same
  # group as the server task (`project.environment`)
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]


  // database information
  db_name  = data.aws_ssm_parameter.db_name.value
  username = data.aws_ssm_parameter.db_username.value
  password = data.aws_ssm_parameter.db_password.value
  port     = tonumber(data.aws_ssm_parameter.db_port.value)

  // This is the private subnets
  db_subnet_group_name = aws_db_subnet_group.this.name

  vpc_security_group_ids = [aws_security_group.db.id]

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
