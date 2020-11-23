resource "aws_ssm_parameter" "db_username" {
  name        = "/db/username"
  value       = "ptodo"
  type        = "String"
  description = "database user name"
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/db/password"
  value       = "secret"
  type        = "SecureString"
  description = "database user password"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "github_token" {
  name        = "/github/token"
  value       = "secret"
  type        = "SecureString"
  description = "Private Access Token"

  lifecycle {
    ignore_changes = [value]
  }
}
