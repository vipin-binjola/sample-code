provider "aws" {
    region = "ap-south-1"
}

variable vpc_cidr_blocks {}
variable subnet_cidr_blocks {}
variable env_prefix {}
variable instance_type {}


resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_blocks
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_blocks
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}
resource "aws_route_table" "myapp-rtb" {
    vpc_id = aws_vpc.myapp-vpc.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.myapp-igw.id
    } ]
    tags = {
        Name: "${var.env_prefix}-rtb"
    }

}
resource "aws_internet_gateway" "myapp-igw"{
        vpc_id = aws_vpc.myapp-vpc.id
        tags = {
        Name: "${var.env_prefix}-igw"
    }

}
resource "aws_route_table_association" "a-rtb-subnet" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-rtb.id
  
}
resource "aws_security_group" "myapp-sg" {
        vpc_id = aws_vpc.myapp-vpc.id
        tags = {
        Name: "${var.env_prefix}-sg"
        }

    ingress =  {

     from_port   = 22

     to_port     = 22

     protocol    = "tcp"

     cidr_blocks = ["0.0.0.0/0"]

    }
  ingress =  {

     from_port   = 8080

     to_port     = 8080

     protocol   = "tcp"

     cidr_blocks = ["0.0.0.0/0"]

    } 

    egress = {
      cidr_blocks = ["0.0.0.0/0"]
      from_port = 0
      to_port = 0
      protocol = "-1"
    }
}
data "aws_ami" "latest-AMI" {
    most_recent = true
    owners = [ "amazon" ]

    filter {
      name = "name"
      values = ["amazon-ami-hvm-*-x86_64-gp2"]
    }
    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }  
}
resource "aws_instance" "myapp-instance" {
    ami = data.aws_ami.latest-AMI.id
    instance_type = var.instance_type
    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_security_group.myapp-sg]
    key_name = "terraform"
    availability_zone = "ap-south-1a"
    user_data = file("user-data.sh")
    tags = {
        Name : "${var.env_prefix}-instance"
    }
}
resource "aws_ebs_volume" "myapp-ebs" {
  size = 10
  availability_zone = "ap-south-1a"
  tags = {
        Name = "data-volume"
    }
}
resource "aws_volume_attachment" "myapp-instance-data" {
 device_name = "/dev/sdc"
 volume_id = "${aws_ebs_volume.myapp-ebs.id}"
 instance_id = "${aws_instance.myapp-instance}"
 availability_zone = "ap-south-1a"

}