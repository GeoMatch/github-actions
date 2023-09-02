# ------------ NOTICE --------------
# When adding new SSM params here, add them to the output
# of the module instead of relying on a data source in another place.


# We only store this in SSM for bookkeeping purposes.
# Depend on the geomatch_version variable instead of this.
resource "aws_ssm_parameter" "geomatch_version_ecs" {
  name        = "${var.ssm_name_prefix}/ECS_GEOMATCH_VERSION"
  type        = "String"
  value       = var.geomatch_version
  description = <<EOT
  DO NOT MODIFY. This corresponds to the Docker tag of the current version in production.
  EOT
  overwrite   = true

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}


resource "aws_ssm_parameter" "ecs_run_task_config" {
  name        = "${var.ssm_name_prefix}/ECS_RUN_TASK_CONFIG"
  type        = "String"
  overwrite   = true
  description = "Info about the ECS cluster needed to run an ECS task within the cluster. (i.e. for migrations)"
  value = jsonencode({
    "AWS_REGION"                         = var.aws_region
    "AWS_GEOMATCH_ECS_LOG_STREAM_PREFIX" = "${var.geomatch_version}/${local.container_name}"
    "AWS_GEOMATCH_ECS_LOG_GROUP_NAME"    = aws_cloudwatch_log_group.app.name
    "AWS_GEOMATCH_ECS_CONTAINER_NAME"    = local.container_name
    "AWS_GEOMATCH_CLUSTER_ARN"           = aws_ecs_cluster.this.arn
    "AWS_GEOMATCH_SERVICE_NAME"          = aws_ecs_service.this.name
    "AWS_GEOMATCH_TASK_DEF_ARN"          = aws_ecs_task_definition.this.arn
    "AWS_GEOMATCH_TASK_SUBNET"           = local.one_zone_public_subnet_id
    "AWS_GEOMATCH_TASK_SECURITY_GROUP"   = aws_security_group.app.id
  })

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}


resource "random_password" "db" {
  length  = 16
  special = false
}

locals {
  ssm_name_db_pw = "${var.ssm_name_prefix}/DB_PASSWORD"
}

resource "aws_ssm_parameter" "db_password" {
  name      = local.ssm_name_db_pw
  type      = "SecureString"
  value     = random_password.db.result
  overwrite = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}


data "aws_ssm_parameter" "db_password" {
  name = local.ssm_name_db_pw
  depends_on = [
    aws_ssm_parameter.db_password
  ]
}

resource "random_password" "new_user_password" {
  length  = 12
  special = false
}

locals {
  ssm_name_new_user_password = "${var.ssm_name_prefix}/NEW_USER_PASSWORD"
}

resource "aws_ssm_parameter" "new_user_password" {
  name        = local.ssm_name_new_user_password
  type        = "SecureString"
  value       = random_password.new_user_password.result
  description = "Password to use when creating a new user. Ideally only used for initial admin user creation."
  overwrite   = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "new_user_password" {
  name = local.ssm_name_new_user_password
  depends_on = [
    aws_ssm_parameter.new_user_password
  ]
}

locals {
  ssm_name_db_user = "${var.ssm_name_prefix}/DB_USERNAME"
}

resource "aws_ssm_parameter" "db_username" {
  name      = local.ssm_name_db_user
  type      = "String"
  value     = replace("${var.project}${var.environment}dbuser", "-", "")
  overwrite = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "db_username" {
  name = local.ssm_name_db_user
  depends_on = [
    aws_ssm_parameter.db_username
  ]
}


locals {
  ssm_name_db_name = "${var.ssm_name_prefix}/DB_NAME"
}

resource "aws_ssm_parameter" "db_name" {
  name      = local.ssm_name_db_name
  type      = "String"
  value     = replace("${var.project}${var.environment}db", "-", "")
  overwrite = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "db_name" {
  name = local.ssm_name_db_name
  depends_on = [
    aws_ssm_parameter.db_name
  ]
}

locals {
  ssm_name_db_port = "${var.ssm_name_prefix}/DB_PORT"
}

resource "aws_ssm_parameter" "db_port" {
  name      = local.ssm_name_db_port
  type      = "String"
  value     = 5432
  overwrite = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}


data "aws_ssm_parameter" "db_port" {
  name = local.ssm_name_db_port
  depends_on = [
    aws_ssm_parameter.db_port
  ]
}



locals {
  ssm_name_app_hosts = "${var.ssm_name_prefix}/DJANGO_APP_HOSTS"
}

resource "aws_ssm_parameter" "django_app_hosts" {
  name      = local.ssm_name_app_hosts
  type      = "StringList"
  value     = "${var.geomatch_subdomain}.geomatch.org"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "django_app_hosts" {
  name = local.ssm_name_app_hosts
  depends_on = [
    aws_ssm_parameter.django_app_hosts
  ]
}

resource "random_password" "django_key" {
  length  = 32
  special = false
}

locals {
  ssm_name_django_secret_key = "${var.ssm_name_prefix}/DJANGO_SECRET_KEY"
}

resource "aws_ssm_parameter" "django_secret_key" {
  name      = local.ssm_name_django_secret_key
  type      = "SecureString"
  value     = random_password.django_key.result
  overwrite = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "django_secret_key" {
  name = local.ssm_name_django_secret_key
  depends_on = [
    aws_ssm_parameter.django_secret_key
  ]
}


locals {
  ssm_name_django_settings_module = "${var.ssm_name_prefix}/DJANGO_SETTINGS_MODULE"
}

resource "aws_ssm_parameter" "django_settings_module" {
  name      = local.ssm_name_django_settings_module
  type      = "String"
  value     = "geomatch.settings.production"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "django_settings_module" {
  name = local.ssm_name_django_settings_module
  depends_on = [
    aws_ssm_parameter.django_settings_module
  ]
}

locals {
  ssm_name_django_error_email     = "${var.ssm_name_prefix}/DJANGO_ERROR_EMAIL"
  ssm_name_django_email_host      = "${var.ssm_name_prefix}/DJANGO_EMAIL_HOST"
  ssm_name_django_email_host_user = "${var.ssm_name_prefix}/DJANGO_EMAIL_HOST_USER"
  ssm_name_django_email_host_pw   = "${var.ssm_name_prefix}/DJANGO_EMAIL_HOST_PASSWORD"
}

resource "aws_ssm_parameter" "django_error_email" {
  name      = local.ssm_name_django_error_email
  type      = "String"
  value     = "error@example.com"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "django_error_email" {
  name = local.ssm_name_django_error_email
  depends_on = [
    aws_ssm_parameter.django_error_email
  ]
}

resource "aws_ssm_parameter" "django_email_host" {
  name      = local.ssm_name_django_email_host
  type      = "String"
  value     = "smtp.stanford.edu"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "django_email_host" {
  name = local.ssm_name_django_email_host
  depends_on = [
    aws_ssm_parameter.django_email_host
  ]
}

resource "aws_ssm_parameter" "django_email_host_user" {
  name      = local.ssm_name_django_email_host_user
  type      = "SecureString"
  value     = "user"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "django_email_host_user" {
  name = local.ssm_name_django_email_host_user
  depends_on = [
    aws_ssm_parameter.django_email_host_user
  ]
}


resource "aws_ssm_parameter" "django_email_host_password" {
  name      = local.ssm_name_django_email_host_pw
  type      = "SecureString"
  value     = "password"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "django_email_host_password" {
  name = local.ssm_name_django_email_host_pw
  depends_on = [
    aws_ssm_parameter.django_email_host_password
  ]
}

locals {
  ssm_name_run_r_remotely = "${var.ssm_name_prefix}/RUN_R_REMOTELY"
}

resource "aws_ssm_parameter" "run_r_remotely" {
  name        = local.ssm_name_run_r_remotely
  type        = "String"
  value       = "False"
  description = "Whether to run R remotely or locally. If True, R will be run on the R Lambda. If False, R will be run on the Django app."
  overwrite   = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "run_r_remotely" {
  name = local.ssm_name_run_r_remotely
  depends_on = [
    aws_ssm_parameter.run_r_remotely
  ]
}
