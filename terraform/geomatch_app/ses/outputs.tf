output "smtp_host" {
  value = "email-smtp.${var.aws_region}.amazonaws.com"
}

output "smtp_host_user" {
  sensitive = true
  value = aws_iam_access_key.ses_smtp.id
}

output "smtp_host_password" {
  sensitive = true
  value     = aws_iam_access_key.ses_smtp.ses_smtp_password_v4
}

output "sender_domain" {
  value     =  var.sender_domain
}