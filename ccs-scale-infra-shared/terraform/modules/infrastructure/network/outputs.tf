output "lb_private_arn" {
  value = aws_lb.private.arn
}

output "lb_private_db_arn" {
  value = aws_lb.private_db.arn
}

output "lb_public_arn" {
  value = aws_lb.public.arn
}

output "lb_public_alb_arn" {
  value = aws_lb.public_alb.arn
}

output "vpc_link_id" {
  value = aws_api_gateway_vpc_link.link.id
}

output "lb_private_dns" {
  value = aws_lb.private.dns_name
}

output "lb_private_db_dns" {
  value = aws_lb.private_db.dns_name
}

output "lb_public_dns" {
  value = aws_lb.public.dns_name
}

output "lb_public_alb_dns" {
  value = aws_lb.public_alb.dns_name
}

output "lb_public_alb_listner_arn" {
  value = aws_lb_listener.port_80.arn
}
