
output "web_host" {
  value="${aws_instance.web.public_dns}"
}