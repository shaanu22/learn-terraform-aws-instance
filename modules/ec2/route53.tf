data "aws_route53_zone" "hosted_zone" {
  name = var.domain_name
}

resource "aws_route53_record" "site_domain" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name                   = aws_lb.custom-elb.dns_name
    zone_id                = aws_lb.custom-elb.zone_id
    evaluate_target_health = true
  }
}
