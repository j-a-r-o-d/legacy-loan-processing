# VPC Endpoints for Systems Manager (SSM) on private EC2 instances
# Required per AWS best practice: https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-setting-up-vpc.html
# These allow SSM Agent to communicate without relying on NAT Gateway.

# Security group for VPC interface endpoints (allows HTTPS from private subnets)
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.project_name}-${var.environment}-vpce-"
  description = "Security group for VPC interface endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-vpce-sg"
    }
  )
}

# SSM endpoint (com.amazonaws.region.ssm)
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-ssm-vpce" })
}

# SSM Messages endpoint (com.amazonaws.region.ssmmessages) — required for Session Manager
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-ssmmessages-vpce" })
}

# EC2 Messages endpoint (com.amazonaws.region.ec2messages) — required for SSM Agent
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-ec2messages-vpce" })
}

# S3 Gateway endpoint — required for SSM Agent updates and script downloads
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id, aws_route_table.public.id]

  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-s3-vpce" })
}

# CloudWatch Logs endpoint — required for CloudWatch Agent log streaming
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-logs-vpce" })
}

# CloudWatch Monitoring endpoint — required for CloudWatch Agent metrics
resource "aws_vpc_endpoint" "monitoring" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-monitoring-vpce" })
}

# Secrets Manager endpoint — required for configure-application.ps1 credential retrieval
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-secretsmanager-vpce" })
}

# CodeDeploy endpoint — required for CodeDeploy agent communication
resource "aws_vpc_endpoint" "codedeploy" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.codedeploy"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-codedeploy-vpce" })
}

# CodeDeploy Commands endpoint — required for CodeDeploy agent to receive deployment commands
resource "aws_vpc_endpoint" "codedeploy_commands_secure" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.codedeploy-commands-secure"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-codedeploy-cmd-vpce" })
}
