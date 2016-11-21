resource "aws_security_group" "bastion" {
  name        = "${var.vpc_key}-sg-bastion"
  description = "Security group for bastion instances"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        "0.0.0.0/0"
      ]
  }

  tags {
    Name = "${var.vpc_key}-sg-bastion"
    VPC = "${var.vpc_key}"
    Terraform = "Terraform"
  }
}

output "sg_bastion" {
  value = "${aws_security_group.bastion.id}"
}
