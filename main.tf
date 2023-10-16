provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "route" {
  route_table_id = aws_route_table.route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.main.default_route_table_id
}

# Create a security group for the WordPress instances (update with your rules)
resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress-sg"
  description = "Security Group for WordPress instances"
  vpc_id      = aws_vpc.my_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Add more rules as needed
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

resource "aws_subnet" "subnet1" {
  availability_zone = "us-east-1a" # AZ 1
  cidr_block        = "10.0.1.0/24"
}

resource "aws_subnet" "subnet2" {
  availability_zone = "us-east-1b" # AZ 2
  cidr_block        = "10.0.2.0/24"
}

# Define WordPress EC2 instance
resource "aws_instance" "wordpress" {
  count               = 2
  ami                 = var.ami_id # Change this to your preferred AMI
  instance_type       = var.instance_type
  subnet_id           = element(aws_subnet.*.id, count.index % 2)
  key_name            = var.key_name
  security_groups     = [aws_security_group.wordpress_sg.name]
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install nginx1.12 -y
              sudo service nginx start
              sudo chkconfig nginx on
              sudo amazon-linux-extras install php7.2 -y
              sudo yum install php-mysql -y
              sudo wget https://wordpress.org/latest.tar.gz
              sudo tar -xzf latest.tar.gz -C /usr/share/nginx/html/
              sudo cp /usr/share/nginx/html/wordpress/wp-config-sample.php /usr/share/nginx/html/wordpress/wp-config.php
              sudo chown -R nginx:nginx /usr/share/nginx/html/wordpress
              sudo service nginx restart
              EOF
  tags = {
    Name = "WordPress-${count.index + 1}"
  }
}

# Create Auto Scaling Groups and launch configurations
resource "aws_launch_configuration" "wordpress_launch_config" {
  count = 8
  name               = "wordpress-launch-config-${count.index}"
  image_id           = var.ami_id
  instance_type      = "t2.micro" # Replace with your desired instance type
  security_groups    = [aws_security_group.wordpress_sg.id]
  user_data          = file("user_data.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "wordpress_asg" {
  count                = 4
  name                 = "wordpress-asg-${count.index}"
  launch_configuration = aws_launch_configuration.wordpress_launch_config[count.index].name
  vpc_zone_identifier  = slice(aws_subnet.public.*.id, count.index, count.index + 1)
  min_size             = 2
  max_size             = 2
  desired_capacity     = 2
  target_group_arns    = [element(aws_lb_target_group.wordpress_target_group[*].arn, count.index)]

  tag {
    key                 = "Name"
    value               = "wordpress-instance"
    propagate_at_launch = true
  }

  depends_on = [aws_launch_configuration.wordpress_launch_config, aws_lb_target_group.wordpress_target_group]
}

#  Create aws lb aws_lb_listener
resource "aws_lb_listener" "wordpress" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      content      = "OK"
    }
  }
}

# -----------------------------------------------


# Create an S3 bucket for logs
resource "aws_s3_bucket" "logs_bucket" {
  bucket = "your-logs-bucket-name"
  acl    = "private"
}

# Create an IAM Role and Instance Profile for S3 access (add proper policies)
resource "aws_iam_role" "s3_access_role" {
  name = "s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
    }]
  })
}

resource "aws_iam_instance_profile" "s3_access_profile" {
  name = "s3-access-profile"

  role = aws_iam_role.s3_access_role.name
}

# Add more configuration for S3 bucket and instance IAM role

