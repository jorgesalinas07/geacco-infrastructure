# SSL Certificate
resource "aws_acm_certificate" "ssl_certificate" {
  domain_name               = terraform.workspace == "stg" ? var.stg_domain_name : var.prod_domain_name
  #subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# # SSL Certificate validation
# resource "aws_acm_certificate_validation" "cert_validation" {
#   depends_on = [
#     aws_route53_zone.geacco_zone,
#     aws_route53_record.geacco_record
#   ]
#   certificate_arn = aws_acm_certificate.ssl_certificate.arn
# }

resource "aws_route53_zone" "geacco_zone" {
  name = terraform.workspace == "stg" ? var.stg_domain_name : var.prod_domain_name
}

resource "aws_route53_record" "geacco_record" { //performance_main_record
  zone_id = aws_route53_zone.geacco_zone.zone_id
  name    = terraform.workspace == "stg" ? var.stg_domain_name : var.prod_domain_name
  type    = "A"

  alias {
    name                   = aws_lb.base_project_alb.dns_name
    zone_id                = aws_lb.base_project_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "geacco_main_record" { //performance_record
  #allow_overwrite = true
  name            = tolist(aws_acm_certificate.ssl_certificate.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.ssl_certificate.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.ssl_certificate.domain_validation_options)[0].resource_record_type
  zone_id         = aws_route53_zone.geacco_zone.zone_id
  ttl             = 60
}
