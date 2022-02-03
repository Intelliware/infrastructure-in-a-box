output "site_url" {
  description = "The url at which to access the site"
  value = aws_alb.iiab_load_balancer.dns_name
}