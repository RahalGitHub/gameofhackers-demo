#------------------------------------------
# Amazon Cognito - User Pool

resource "aws_cognito_user_pool" "gameofhackers" {
  name = "gameofhackers-users"

  username_attributes = [
    "email"
  ]

  auto_verified_attributes = [
    "email"
  ]

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  tags = {
    Name    = "gameofhackers-users"
    Project = "gameofhackers"
  }
}

#------------------------------------------
# Cognito App Client

resource "aws_cognito_user_pool_client" "gameofhackers" {
  name         = "gameofhackers-web-client"
  user_pool_id = aws_cognito_user_pool.gameofhackers.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
}

#------------------------------------------
# Outputs

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.gameofhackers.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.gameofhackers.id
}