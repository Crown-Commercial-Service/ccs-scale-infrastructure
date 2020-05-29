output "vpc_id" {
  value = aws_vpc.SCALE-Services.id
}

output "public_web_subnet_ids" {
  value = values(aws_subnet.SCALE-AZ-WEB-Public)[*].id
}

output "private_app_subnet_ids" {
  value = values(aws_subnet.SCALE-AZ-APP-Private)[*].id
}

output "private_db_subnet_ids" {
  value = values(aws_subnet.SCALE-AZ-DB-Private)[*].id
}
