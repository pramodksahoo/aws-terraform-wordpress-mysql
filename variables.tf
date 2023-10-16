variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1" # Change this to your preferred region
}

variable "key_name" {
  description = "SSH key pair name"
  default     = "your-key-pair-name" # Change this to your key pair name
}

variable "db_password" {
  description = "MySQL DB password"
  default     = "your-db-password" # Change this to your preferred DB password
}

# Define the AMI ID for the EC2 instances (You should replace this with the correct AMI ID)
variable "ami_id" {
  default = "ami-0123456789"
}

# Define a Instance type
variable "instance_type" {
  default = "t2.micro"
}

# Define a list of availability zones
variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}

# Define variables
variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1" # Change to your desired region
}
------------------------------------------


# Create an S3 bucket for logs
resource "aws_s3_bucket" "logs_bucket" {
  bucket = "your-logs-bucket-name"
  acl    = "private"
}


# Create target groups
resource "aws_lb_target_group" "wordpress_target_group" {
  count       = 4
  name        = "wordpress-target-group-${count.index}"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "your-vpc-id"

  health_check {
    path                = "/index.html"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  depends_on = [aws_lb.web_lb]
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

# Define MySQL RDS instance
resource "aws_db_instance" "wordpress_db" {
  allocated_storage    = 20
  storage_type        = "gp2"
  engine              = "mysql"
  engine_version      = "5.7"
  instance_class      = "db.t2.micro"
  name                = "wordpressdb"
  username            = "admin"
  password            = var.db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot = true
  publicly_accessible = false
}

# Define WordPress EC2 instance
resource "aws_instance" "wordpress_instance" {
  ami           = var.ami_id # Replace with your WordPress AMI ID
  instance_type = var.instance_type
  subnet_id     = aws_subnet.my_subnet[0].id
  security_groups = [aws_security_group.wordpress_sg.name]
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
}

# Add more configuration for S3 bucket and instance IAM role

# Output the load balancer DNS name
output "load_balancer_dns" {
  value = aws_lb.web_lb.dns_name
}
