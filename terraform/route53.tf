data "aws_route53_zone" "gameofhackers" {
  name         = "gameofhackers.fr."
  private_zone = false
}

resource "aws_route53_record" "web" {
  zone_id = data.aws_route53_zone.gameofhackers.zone_id
  name    = "gameofhackers.fr"
  type    = "A"
  ttl     = 60
  records = [aws_eip.web.public_ip]
}