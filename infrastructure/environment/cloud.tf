resource "aws_subnet" "base_project_cloud_subnet" {
  count             = var.subnet_count.cloud_private
  vpc_id            = aws_vpc.base_project_VPC.id
  cidr_block        = var.cloud_subnet_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_cloud_subnet_stg_${count.index}" : "geacco_app_cloud_subnet_prod_${count.index}"
  }
}

resource "aws_internet_gateway" "base_project_gw" {
  vpc_id = aws_vpc.base_project_VPC.id

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_internet_gateway_stg" : "geacco_app_internet_gateway_prod"
  }
}

resource "aws_security_group" "EC2_security_group" {
  name        = terraform.workspace == "stg" ? "EC2_security_group_stg" : "EC2_security_group_prod"
  description = "A security group for the EC2 instance"
  vpc_id      = aws_vpc.base_project_VPC.id

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

  # # EC2 instances should be accessible from Redis.
  # ingress {
  #   description = "Allow all traffic for Redis"
  #   from_port   = "6379"
  #   to_port     = "6379"
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  // Allowing all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_ec2_security_group_stg" : "geacco_app_ec2_security_group_prod"
  }
}

#ssh-keygen -t rsa -b 4096 -m pem -f geacco-app && openssl rsa -in geacco-app -outform pem && chmod 400 geacco-app.pem
#Modified
#ssh-keygen -t rsa -b 4096 -m pem -f geacco-app && openssl rsa -in geacco-app -outform pem -out geacco-app.pem && chmod 400 geacco-app.pem
resource "aws_key_pair" "geacco_app_kp" {
  key_name   = terraform.workspace == "stg" ? "geacco_app_kp_stg" : "geacco_app_kp_prod"
  public_key = file("geacco-app.pub")
}

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

# data "aws_ami" "ecs_ami" {
#   most_recent = "true"
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#   }
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
#   owners = ["099720109477"]
# }

# Connect to instance
# ssh -i "geacco-app.pem" ubuntu@$(terraform output -raw web_public_dns)
# With ecs optimized ami
# ssh -i "geacco-app.pem" ec2-user@$(terraform output -raw web_public_dns)
resource "aws_instance" "base_project_EC2_instance" {
  count                       = var.settings.web_app.count
  ami                         = data.aws_ami.ecs_ami.id
  instance_type               = var.settings.web_app.instance_type
  subnet_id                   = aws_subnet.base_project_cloud_subnet[count.index].id
  key_name                    = aws_key_pair.geacco_app_kp.key_name
  associate_public_ip_address = true //Will removed when address route 53
  iam_instance_profile        = aws_iam_instance_profile.base_project_repository_intance_profile.name
  vpc_security_group_ids      = [aws_security_group.EC2_security_group.id]

  # Usar solo en caso de creación de instancia

  # root_block_device {
  #   volume_size = 35 // Add this volume size. Potencial 50
  # }

  # ebs_block_device {
  #   device_name = "/dev/xvda"
  #   volume_size = 35
  # }
  user_data_base64            = filebase64("user_data.sh")

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_EC2_instance_stg" : "geacco_EC2_instance_prod"
  }
}

# resource "aws_ebs_volume" "root_volume" {
#   count                       = var.settings.web_app.count
#   availability_zone = data.aws_availability_zones.available.names[count.index]
#   size             = 35
#   # Other EBS volume options can be set here as needed
# }

# resource "aws_volume_attachment" "root_volume_attachment" {
#   count                       = var.settings.web_app.count
#   device_name = "/dev/xvda"
#   volume_id   = aws_ebs_volume.root_volume[count.index].id
#   instance_id = aws_instance.base_project_EC2_instance[count.index].id
# }

// Get internet connectivity
resource "aws_eip" "geacco_EC2_eip" {
  count = var.settings.web_app.count

  instance = aws_instance.base_project_EC2_instance[count.index].id
  #instance = "i-0762e68ee40aeb876"

  vpc = true

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_EC2_iep_instance_stg" : "geacco_EC2_iep_instance_prod"
  }
}

# Run image in EC2
# docker run -p 80:8000 app

# sudo docker run -p 80:8000 388813176377.dkr.ecr.us-east-1.amazonaws.com/geacco_app_stg:latest
# With port 8000 in the image
