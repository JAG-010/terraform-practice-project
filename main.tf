// Referance
# https://youtu.be/iRaai1IBlB0

// Create VPC
resource "aws_vpc" "lab_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "lab_public_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "lab_igw" {
  vpc_id = aws_vpc.lab_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "lab_public_route_table" {
  vpc_id = aws_vpc.lab_vpc.id

  tags = {
    Name = "dev-rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.lab_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab_igw.id
}

resource "aws_route_table_association" "lab_public_assoc" {
  subnet_id      = aws_subnet.lab_public_subnet.id
  route_table_id = aws_route_table.lab_public_route_table.id
}


resource "aws_security_group" "lab_sg" {
  name        = "dev-sg"
  description = "dev security group"
  vpc_id      = aws_vpc.lab_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] // This will allow access to public. Changing to your PC/Laptop public IP is recommended.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "lab_auth" {
  key_name   = "labkey"
  public_key = file("~/.ssh/labkey.pub")
}

// Create EC2 instance
resource "aws_instance" "dev_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.lab_auth.id
  vpc_security_group_ids = [aws_security_group.lab_sg.id]
  subnet_id              = aws_subnet.lab_public_subnet.id
  user_data              = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-node"
  }

// below mentioned block will create a VSCode confige file, which will procice ec2 access to vscode
  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl", {
      hostname     = self.public_ip
      user         = "ubuntu"
      identityfile = "~/.ssh/labkey"
    })
    // This script was default to Windows 
    // IF using linux/macos use
    // terraform apply -var="host_os=linux"
    interpreter = var.host_os == "windows" ? ["powershell", "-command"] : ["bash", "-c"]
  }

}
