resource "aws_subnet" "base_project_cloud_subnet" {
  count             = var.subnet_count.cloud_private
  vpc_id            = aws_vpc.base_project_VPC.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = data.aws_availability_zones.available.state[count.index]

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

resource "aws_route_table" "base_project_cloud_route_table" {
  vpc_id = aws_vpc.base_project_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.base_project_gw.id
  }

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_cloud_route_table_stg" : "geacco_app_cloud_route_table_prod"
  }
}

resource "aws_route_table_association" "base_project_cloud_route_table_association" {
  count          = var.subnet_count.cloud_private
  subnet_id      = aws_subnet.base_project_cloud_subnet[count.index].id
  route_table_id = aws_route_table.base_project_cloud_route_table.id
}

resource "aws_security_group" "EC2_security_group" {
  name        = terraform.workspace == "stg" ? "EC2_security_group_stg" : "EC2_security_group_prod"
  description = "A security group for the EC2 instance"
  vpc_id      = aws_vpc.base_project_VPC.id

  ingress {
    description = "Allow all traffic throught HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from computer"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"] #Set ip. Why /32?
  }

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
resource "aws_key_pair" "geacco_app_kp" {
  key_name   = terraform.workspace == "stg" ? "geacco_app_kp_stg" : "geacco_app_kp_prod"
  public_key = file("geacco-app.pub")
}

data "aws_ami" "ubuntu" {
  most_recent = "true"
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "base_project_EC2_instance" {
  count         = var.settings.web_app.count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.settings.web_app.instance_type
  subnet_id     = aws_subnet.base_project_cloud_subnet[count.index].id
  key_name      = aws_key_pair.geacco_app_kp.key_name
  vpc_security_group_ids = [
    aws_security_group.RDS_security_group.id,
    aws_security_group.S3_security_group.id,
    aws_security_group.ECR_security_group.id,
  ]

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_EC2_instance_stg" : "geacco_EC2_instance_prod"
  }
}

// Get internet connectivity
resource "aws_eip" "geacco_EC2_eip" {
  count = var.settings.web_app.count

  instance = aws_instance.base_project_EC2_instance[count.index].id

  vpc = true

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_EC2_instance_stg" : "geacco_EC2_instance_prod"
  }
}
