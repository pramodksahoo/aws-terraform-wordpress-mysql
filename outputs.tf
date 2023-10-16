output "alb_dns_name" {
  value = aws_lb.my_alb.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.my_db.endpoint
}
