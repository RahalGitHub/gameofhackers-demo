resource "aws_iam_role" "r53_devops" {
  name = "gameofhackers-r53-devops"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "r53_certbot" {
  name = "gameofhackers-r53-certbot-dns01"
  role = aws_iam_role.r53_devops.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DiscoverHostedZones"
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListHostedZonesByName"
        ]
        Resource = "*"
      },
      {
        Sid      = "ReadDNSRecords"
        Effect   = "Allow"
        Action   = "route53:ListResourceRecordSets"
        Resource = data.aws_route53_zone.gameofhackers.arn
      },
      {
        Sid      = "CheckDNSChanges"
        Effect   = "Allow"
        Action   = "route53:GetChange"
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Sid      = "ManageLetsEncryptChallenges"
        Effect   = "Allow"
        Action   = "route53:ChangeResourceRecordSets"
        Resource = data.aws_route53_zone.gameofhackers.arn

        Condition = {
          "ForAllValues:StringEquals" = {
            "route53:ChangeResourceRecordSetsRecordTypes" = ["TXT"]
            "route53:ChangeResourceRecordSetsActions" = [
              "CREATE",
              "UPSERT",
              "DELETE"
            ]
            "route53:ChangeResourceRecordSetsNormalizedRecordNames" = [
              "_acme-challenge.gameofhackers.fr",
              "_acme-challenge.www.gameofhackers.fr"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "r53_devops" {
  name = "gameofhackers-r53-devops"
  role = aws_iam_role.r53_devops.name
}