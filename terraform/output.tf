output "test_curl" {
  value = "curl https://www.cloudreach.com --head --proxy ${aws_lb.main.dns_name}:${var.port}"
}

output "iam_role" {
  value = aws_iam_role.ecs_execution_role.arn
}

output "nlb_arn" {
  value = aws_lb.main.arn
}

output "nlb_hostname" {
  value = aws_lb.main.dns_name
}

output "service_name" {
  value = aws_ecs_service.service.name
}