


# Create Security Group for the Web Server
# terraform aws create security group
resource "aws_security_group" "webserver-security-group2" {
  name        = "Web Server Security Group"
  description = "Enable HTTP/HTTPS access on Port 80/443 via ALB and SSH access on Port 22 via SSH SG"
  vpc_id      = aws_vpc.main.id
  ingress {
    description     = "SSH Access"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.elb_http.id]
  }
  ingress {
    description     = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.elb_http.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Web Server Security Group2"
  }
}

resource "aws_security_group" "elb_http" {
  name        = "elb_http"
  description = "Allow HTTP traffic to instances through Elastic Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  ingress {
    description = "HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP through ELB Security Group"
  }
}


data "aws_ami" "amznlx2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-gp2"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_configuration" "ec2_launcher" {
  name_prefix                 = "alb-launcher"
  image_id                    = data.aws_ami.amznlx2.id
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  security_groups             = [aws_security_group.webserver-security-group2.id]
  user_data                   = file("user_data.sh")
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ec2_scaling_rule1" {
  name                 = "ec2-scaling"
  vpc_zone_identifier  = [aws_subnet.private_subnet1a.id, aws_subnet.private_subnet2c.id]
  launch_configuration = aws_launch_configuration.ec2_launcher.name
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  lifecycle {
    create_before_destroy = true
  }

 
  tag {
     key                 = "Name"
     value               = "app-tier"
    propagate_at_launch = "true"
  }
   tag {
    key                 = "lorem"
    value               = "ipsum"
    propagate_at_launch = false
  }
}

resource "aws_lb" "app" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_http.id]
  subnets            = [aws_subnet.public_subnet1a.id, aws_subnet.public_subnet2c.id]
  tags = {
    "Name" = "APP"
  }
}

resource "aws_lb_target_group" "ec2_target_group1" {
  name     = "web-target-group1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "lb_listener1" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_target_group1.arn
  }
}

resource "aws_autoscaling_attachment" "alb_asg_attach1" {
  autoscaling_group_name = aws_autoscaling_group.ec2_scaling_rule1.id
  alb_target_group_arn   = aws_lb_target_group.ec2_target_group1.arn
}

  resource "aws_autoscaling_policy" "app_policy_up" {
  name                   = "app_policy_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ec2_scaling_rule1.name
}
resource "aws_cloudwatch_metric_alarm" "app_cpu_alarm_up" {
  alarm_name          = "app_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ec2_scaling_rule1.name
  }

alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.app_policy_up.arn]
}
resource "aws_autoscaling_policy" "app_policy_down" {
  name                   = "app_policy_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ec2_scaling_rule1.name
}
resource "aws_cloudwatch_metric_alarm" "app_cpu_alarm_down" {
  alarm_name          = "app_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ec2_scaling_rule1.name
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.app_policy_down.arn]
}