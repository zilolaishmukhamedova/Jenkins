

resource "aws_db_instance" "project-1" {
  allocated_storage    = 20
  identifier           = "mysql-db-01"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "db_name"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "project-2" {
  allocated_storage    = 20
  identifier           = "mysql-db-02"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "db_name"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}
# Create Security Group for Database
# terraform aws create security group
resource "aws_security_group" "SecurityGroupDB" {
  name        = "Database Security Group"
  description = "Enable MySQL on Port 3306"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL Access"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver-security-group2.id]
  }
  ingress {
    description     = "MySQL Access"
    from_port       = 3306
    to_port         = 3306
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
    Name = "SecurityGroupDB Security Group"
  }
}



