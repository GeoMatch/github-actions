output "route_table_id" {
  value = aws_route_table.this.id
}

output "ecs_task_execution_iam_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_iam_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.this.arn
}
