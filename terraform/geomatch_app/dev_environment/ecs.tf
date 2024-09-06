locals {
  name_prefix = "${var.project}-${var.environment}-${var.name}"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/${local.name_prefix}"
  retention_in_days = var.cloudwatch_module.log_group_retention_in_days
  kms_key_id        = var.cloudwatch_module.kms_arn
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-role"
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

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "s3" {
  name = "${local.name_prefix}-s3-policy"
  role = aws_iam_role.ecs_task.id

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
      # TODO: support readonly var option:
      {
        "Action" : "s3:*",
        "Effect" : "Allow",
        "Resource" : flatten([
          for s3_name, s3_config in var.s3_configs : [
            s3_config.arn,
            "${s3_config.arn}/*"
          ]
        ])
      }
    ]
  })
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
# Role to delegate permissions to ECS
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name_prefix}-ecs-task-execution-role"
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
  name = "${local.name_prefix}-ecs-cluster"
  configuration {
    # Only affects execute-command sessions
    execute_command_configuration {
      kms_key_id = var.cloudwatch_module.kms_arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.this.name
      }
    }
  }
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

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
  container_name         = "${local.name_prefix}-container"
  task_definition_family = "${local.name_prefix}-task-def"
  // Default AZ for the db and app. AWS may change AZ if default goes down.
  container_port     = tostring(var.container_port)
  container_port_num = tonumber(var.container_port)
  gm_container_url   = "${var.ecr_repo_url}:${var.ecr_tag}"
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
          "awslogs-group" : aws_cloudwatch_log_group.this.name,
          "awslogs-region" : var.aws_region,
          "awslogs-stream-prefix" : var.ecr_tag,
          "awslogs-datetime-format" : "\\[%Y-%m-%d %H:%M:%S%L\\]"
        }
      },
      "healthCheck" : {
        "command" : ["CMD-SHELL", "if [ \"${tostring(var.health_check_skip)}\" = \"true\" ]; then exit 0; else curl -f http://localhost:${local.container_port}${var.health_check_path} || exit 1; fi"],
        "retries" : 5,
        "interval" : 60,
        "startPeriod" : 3,
        "timeout" : 5,
      },
      "environment" : flatten(concat([
        {
          "name" : "AWS_REGION",
          "value" : var.aws_region
        },
        {
          "name" : "CONTAINER_PORT",
          "value" : local.container_port
        },
        ],
        [
          for name, s3 in var.s3_configs : {
            name  = s3.bucket_name_env_var
            value = s3.bucket_name
          }
        ],
      var.ecs_environment_variables)),
      "secrets" : concat([
        # {
        #   "name" : "APP_HOSTS",
        #   "valueFrom" : data.aws_ssm_parameter.django_app_hosts.arn
        # }
      ], var.ecs_secrets),
      # The below are specified because otherwise AWS will silently write these
      # which will cause a diff during the next 'terraform apply'
      "cpu" : 0,
      "volumesFrom" : [],
      "mountPoints" : [
        for name, ap in aws_efs_access_point.this : {
          containerPath = ap.tags["MountPath"]
          sourceVolume  = ap.tags["VolumeName"]
          readOnly      = lower(ap.tags["ReadOnly"]) == "true" ? true : false
        }
      ]
    }
  ])

  dynamic "volume" {
    for_each = aws_efs_access_point.this

    content {
      name = volume.value.tags["VolumeName"]

      efs_volume_configuration {
        file_system_id     = volume.value.file_system_id
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = volume.value.id
          iam             = "ENABLED"
        }
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
  name                 = "${var.project}-${var.environment}-${var.name}-ecs-service"
  launch_type          = "FARGATE"
  cluster              = aws_ecs_cluster.this.id
  task_definition      = aws_ecs_task_definition.this.arn
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets          = [aws_subnet.ecs.id]
    assign_public_ip = false

    security_groups = flatten(concat(
      [
        aws_security_group.ecs.id,
      ],
      [
        for efs_name, efs_config in var.efs_configs : [
          efs_config.mount_target_sg_id
        ]
      ]
    ))
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = local.container_name
    container_port   = local.container_port_num
  }

  depends_on = [aws_lb_listener.https, aws_lb_listener.http]
}
