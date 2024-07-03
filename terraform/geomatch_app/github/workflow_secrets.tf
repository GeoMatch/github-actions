/* -------------------------------------------------------------------------- */
/*                                   Common                                   */
/* -------------------------------------------------------------------------- */

resource "github_actions_secret" "region" {
  repository      = local.repo_name
  secret_name     = "AWS_REGION"
  plaintext_value = var.aws_region
}

/* -------------------------------------------------------------------------- */
/*                                     ECR                                    */
/* -------------------------------------------------------------------------- */

resource "github_actions_secret" "aws_github_action_build_role_arn" {
  repository      = local.repo_name
  secret_name     = "AWS_GITHUB_ACTION_BUILD_ROLE_ARN"
  plaintext_value = aws_iam_role.github_action_build.arn
}

resource "github_actions_secret" "geomatch_ecr_container_port" {
  repository      = local.repo_name
  secret_name     = "AWS_GEOMATCH_ECR_CONTAINER_PORT"
  plaintext_value = var.ecr_module.geomatch_app_container_port
}

resource "github_actions_secret" "geomatch_ecr_repo_url" {
  repository      = local.repo_name
  secret_name     = "AWS_GEOMATCH_ECR_REPO_URL"
  plaintext_value = var.ecr_module.geomatch_app_ecr_repo_url
}

# resource "github_actions_secret" "geomatch_sagemaker_ecr_repo_url" {
#   repository      = local.repo_name
#   secret_name     = "AWS_GEOMATCH_SAGEMAKER_ECR_REPO_URL"
#   plaintext_value = var.sagemaker_ecr_module.geomatch_app_ecr_repo_url
# }

resource "github_actions_secret" "geomatch_ecr_repo_name" {
  repository      = local.repo_name
  secret_name     = "AWS_GEOMATCH_ECR_REPO_NAME"
  plaintext_value = var.ecr_module.geomatch_app_ecr_repo_name
}

resource "github_actions_secret" "geomatch_docker_build_args" {
  repository      = local.repo_name
  secret_name     = "GEOMATCH_DOCKER_BUILD_ARGS"
  plaintext_value = join("\n", [for arg in var.docker_build_args : "${arg.name}=${arg.value}"])
}

/* -------------------------------------------------------------------------- */
/*                                     ECS                                    */
/* -------------------------------------------------------------------------- */

resource "github_actions_secret" "aws_github_action_terraform_plan_role_arn" {
  count           = var.ecs_module == null ? 0 : 1
  repository      = local.repo_name
  secret_name     = "AWS_GITHUB_ACTION_TERRAFORM_PLAN_ROLE_ARN"
  plaintext_value = aws_iam_role.github_action_terraform_plan[0].arn
}

resource "github_actions_secret" "aws_github_action_terraform_ecs_deploy_role_arn" {
  count           = var.ecs_module == null ? 0 : 1
  repository      = local.repo_name
  secret_name     = "AWS_GITHUB_ACTION_TERRAFORM_ECS_DEPLOY_ROLE_ARN"
  plaintext_value = aws_iam_role.github_action_terraform_apply_ecs[0].arn
}

resource "github_actions_secret" "aws_github_action_ecs_run_task_role_arn" {
  count           = var.ecs_module == null ? 0 : 1
  repository      = local.repo_name
  secret_name     = "AWS_GITHUB_ACTION_ECS_RUN_TASK_ROLE_ARN"
  plaintext_value = aws_iam_role.github_action_ecs_run_task[0].arn
}

resource "github_actions_secret" "geomatch_ssm_ecs_run_task_config_name" {
  count           = var.ecs_module == null ? 0 : 1
  plaintext_value = var.ecs_module == null ? "" : var.ecs_module.ssm_ecs_run_task_config_name
  repository      = local.repo_name
  secret_name     = "AWS_GEOMATCH_ECS_RUN_TASK_CONFIG_SSM_NAME"
}

resource "github_actions_secret" "geomatch_ssm_new_user_password_name" {
  count           = var.ecs_module == null ? 0 : 1
  plaintext_value = var.ecs_module == null ? "" : var.ecs_module.ssm_new_user_password_name
  repository      = local.repo_name
  secret_name     = "AWS_GEOMATCH_NEW_USER_PASSWORD_SSM_NAME"
}

resource "github_actions_secret" "geomatch_service_name" {
  count           = var.ecs_module == null ? 0 : 1
  plaintext_value = var.ecs_module == null ? "" : var.ecs_module.ecs_service_name
  repository      = local.repo_name
  secret_name     = "AWS_GEOMATCH_SERVICE_NAME"
}

resource "github_actions_secret" "geomatch_ecs_container_name" {
  count           = var.ecs_module == null ? 0 : 1
  plaintext_value = var.ecs_module == null ? "" : var.ecs_module.app_container_name
  repository      = local.repo_name
  secret_name     = "AWS_GEOMATCH_ECS_CONTAINER_NAME"
}

resource "github_actions_secret" "geomatch_task_family_name" {
  count           = var.ecs_module == null ? 0 : 1
  plaintext_value = var.ecs_module == null ? "" : var.ecs_module.ecs_task_def_family
  repository      = local.repo_name
  secret_name     = "AWS_GEOMATCH_TASK_FAMILY_NAME"
}

# TODO(P3): Pass all subnets and security groups
resource "github_actions_secret" "geomatch_task_security_group" {
  count           = var.ecs_module == null ? 0 : 1
  plaintext_value = var.ecs_module == null ? "" : var.ecs_module.ecs_task_security_group
  repository      = local.repo_name
  secret_name     = "AWS_GEOMATCH_TASK_SECURITY_GROUP"
}

resource "github_actions_secret" "geomatch_task_subnet" {
  count           = var.ecs_module == null ? 0 : 1
  plaintext_value = var.ecs_module == null ? "" : var.ecs_module.ecs_task_subnet
  repository      = local.repo_name
  secret_name     = "AWS_GEOMATCH_TASK_SUBNET"
}

resource "github_actions_secret" "action_secrets" {
  for_each        = { for secret in var.extra_secrets : secret.name => secret }
  repository      = local.repo_name
  secret_name     = each.value.name
  plaintext_value = each.value.value
}
