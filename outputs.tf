output "rds_endpoint" {
  value = aws_db_instance.keycloak-database-engine.endpoint
}

output "alb_endpoint" {
  value = aws_alb.keycloak-load-balancer.dns_name
}

output "alb_zone_id" {
  value = aws_alb.keycloak-load-balancer.zone_id
}
