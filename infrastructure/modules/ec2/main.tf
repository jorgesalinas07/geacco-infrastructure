resource "aws_subnet" "this" {
  count             = var.subnet_count.cloud_private
  vpc_id            = var.vpc_id
  cidr_block        = var.cloud_subnet_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = terraform.workspace == "stg" ? "${var.ec2_name}_stg_${count.index}" : "${var.ec2_name}_prod_${count.index}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id

  tags = {
    Name = terraform.workspace == "stg" ? "${var.ec2_name}_internet_gateway_stg" : "${var.ec2_name}_internet_gateway_prod"
  }
}

resource "aws_security_group" "this" {
  name        = terraform.workspace == "stg" ? "${var.ec2_name}_security_group_stg" : "${var.ec2_name}_security_group_prod"
  description = "A security group for the EC2 instance"
  vpc_id      = var.vpc_id

  # EC2 instances should be accessible anywhere on the internet via HTTP. // Check if add only ALB security group here
  ingress {
    description = "Allow all traffic throught HTTP"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] //Add EC2 security group
  }

  # EC2 instances should be accessible anywhere on the internet via HTTP.
  ingress {
    description = "Allow all traffic throught HTTP"
    from_port   = "8000"
    to_port     = "8000"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Only you should be able to access the EC2 instances via SSH. //Checked
  ingress {
    description = "Allow SSH from computer"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  // Allowing all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = terraform.workspace == "stg" ? "${var.ec2_name}_security_group_stg" : "${var.ec2_name}_security_group_prod"
  }
}

resource "aws_key_pair" "this" {
  key_name   = terraform.workspace == "stg" ? "${var.ec2_name}_kp_stg" : "${var.ec2_name}_kp_prod"
  public_key = file("${var.ec2_name}.pub")
}

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

resource "aws_instance" "this" {
  count                       = var.settings.web_app.count
  ami                         = data.aws_ami.ecs_ami.id
  instance_type               = var.settings.web_app.instance_type
  subnet_id                   = aws_subnet.this[count.index].id
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true //Will removed when address route 53
  iam_instance_profile        = aws_iam_instance_profile.base_project_repository_intance_profile.name
  vpc_security_group_ids      = [aws_security_group.EC2_security_group.id]
  user_data_base64            = filebase64("user_data.sh")

  tags = {
    Name = terraform.workspace == "stg" ? "${var.ec2_name}_stg" : "${var.ec2_name}_prod"
  }
}

// Get internet connectivity
resource "aws_eip" "geacco_EC2_eip" {
  count = var.settings.web_app.count

  instance = aws_instance.this[count.index].id

  vpc = true

  tags = {
    Name = terraform.workspace == "stg" ? "${var.ec2_name}_iep_instance_stg" : "${var.ec2_name}_iep_instance_prod"
  }
}
