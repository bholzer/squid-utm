resource "aws_security_group" "fargate" {
  name        = format("%s-%s-sg", var.environment, var.name)
  description = format("%s-%s-sg", var.environment, var.name)
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(
    var.tags,
    map("Name", format("%s-%s-sg", var.environment, var.name)),
  )}"
}
