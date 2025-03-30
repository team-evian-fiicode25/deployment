resource "aws_security_group" "test_sg" {
  name        = "${var.app_name}-test-sg"
  description = "Allow SSH access from approved IP"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from current IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-test-sg"
  }
}

# Create key pair from provided public key
resource "aws_key_pair" "test_key" {
  key_name   = "${var.app_name}-test-key"
  public_key = var.ssh_key_public
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "test_ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnets[0]

  vpc_security_group_ids = [aws_security_group.test_sg.id]
  key_name               = aws_key_pair.test_key.key_name

  associate_public_ip_address = true

  tags = {
    Name = "${var.app_name}-test-instance"
  }
}
