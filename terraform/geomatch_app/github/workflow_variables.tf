/* -------------------------------------------------------------------------- */
/*                                     ECS                                    */
/* -------------------------------------------------------------------------- */

# resource "github_actions_variable" "aws_github_action_terraform_" {
#   count           = var.ecs_module == null ? 0 : 1
#   repository       = local.repo_name 
#   variable_name    = "AWS_ACTION_VAR_TERRAFORM_CURRENT_VERSION"
#   value            =  
# }
