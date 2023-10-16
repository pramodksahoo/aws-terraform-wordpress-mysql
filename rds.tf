resource "aws_db_subnet_group" "my_db_subnet_group" {
  subnet_ids = [aws_subnet.private_subnet_az1.id, aws_subnet.private_subnet_az2.id]
}

resource "aws_db_instance" "my_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "myuser"
  password             = "mypassword"
  db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.name
  multi_az             = true
}
