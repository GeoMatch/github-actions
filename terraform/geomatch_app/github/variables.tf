variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "state_bucket_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "github_geomatch_app_repo" {
  type        = string
  description = "e.g. org_name/repo_name"
}

variable "ecr_module" {
  sensitive = true
  type = object({
    geomatch_app_container_port = number
    geomatch_app_ecr_repo_url   = string
    geomatch_app_ecr_repo_name  = string
    geomatch_app_ecr_repo_arn   = string
  })
}

variable "ecs_module" {
  sensitive = true
  type = object({
    ecs_task_iam_arn             = string
    ecs_task_execution_iam_arn   = string
    ssm_ecs_run_task_config_arn  = string
    ssm_ecs_run_task_config_name = string
    ssm_new_user_password_arn    = string
    ssm_new_user_password_name   = string
    ecs_cluster_arn              = string
    ecs_service_name             = string
    ecs_task_def_family          = string
    ecs_task_subnet              = string
    ecs_task_security_group      = string
    app_container_name           = string
    ssm_geomatch_version_ecs_arn = string
    r_lambda_arn                 = string
    lambda_exec_iam_arn          = string
  })
  default = null
}

# TODO source from separate ssm module output
variable "ssm_name_prefix" {
  type        = string
  description = "should be '/{project}/{environment}'"
}

variable "docker_build_args" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Extra build args to pass to 'docker build'."
  default     = []
}

variable "extra_secrets" {
  description = "List of extra GitHub Action Secrets to include"
  sensitive = true
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
