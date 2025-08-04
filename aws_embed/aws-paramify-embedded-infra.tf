###########################################################################
## VARIABLES
###########################################################################

variable "region" {
  description = "The AWS region to create resources in."
  default     = "us-west-2"
}

variable "sso_profile" {
  description = "The AWS SSO profile to use for create access."
  default     = "admin"
}

variable "allowed_ips" {
  description = "Company egress IPs that should be allowed to access app and installer."
  default     = ["192.168.0.1/32"]
}

variable "ssl_cert" {
  description = "SSL cert to use on app/kots loadbalancer."
  default     = "arn:aws:acm:<region>:<account>:certificate/<cert-guid>"
}

variable "db_password" {
  description = "RDS database password used by Paramify."
  default     = "super_secret"
}

variable "db_port" {
  description = "RDS database port used by Paramify."
  default     = "5432"
}

variable "key_pair" {
  description = "Key pair to assign to the EC2 instance for SSH access."
  default     = "my-key-pair"
}

variable "aws_prefix" {
  description = "Prefix for naming the created AWS resources."
  default     = "paramify-company"
}


###########################################################################
## CORE
###########################################################################

provider "aws" {
  region  = var.region
  profile = var.sso_profile
}

data "aws_ssm_parameter" "linux-ami" {
  # Lookup the AMI for Amazon Linux 2
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}


###########################################################################
## OUTPUT
###########################################################################

output "ec2_id" {
  description = "EC2 instance ID to use to SSH via EIC"
  value       = aws_instance.paramify_solo_app.id
}

output "db_dns" {
  description = "DB endpoint to configure for application"
  value       = element(split(":", aws_db_instance.paramify_solo_db.endpoint), 0)
}

output "lb_dns" {
  description = "Load balancer name to lookup for DNS record alias"
  value       = aws_lb.paramify_solo_lb.dns_name
}

output "region" {
  description = "Region for created resources"
  value       = var.region
}

output "s3_bucket" {
  description = "S3 bucket created to store documents"
  value       = aws_s3_bucket.paramify_solo_s3.bucket
}


###########################################################################
## NETWORK
###########################################################################

resource "aws_vpc" "paramify_solo_vpc" {
  tags = {
    Name = "${var.aws_prefix}-vpc"
  }
  cidr_block = "10.1.0.0/16"
}

resource "aws_subnet" "paramify_solo_public1" {
  tags = {
    Name = "${var.aws_prefix}-public1"
  }
  vpc_id            = aws_vpc.paramify_solo_vpc.id
  availability_zone = "us-west-2b"
  cidr_block        = "10.1.0.0/24"
}

resource "aws_subnet" "paramify_solo_public2" {
  tags = {
    Name = "${var.aws_prefix}-public2"
  }
  vpc_id            = aws_vpc.paramify_solo_vpc.id
  availability_zone = "us-west-2c"
  cidr_block        = "10.1.1.0/24"
}

resource "aws_subnet" "paramify_solo_private1" {
  tags = {
    Name = "${var.aws_prefix}-private1"
  }
  vpc_id            = aws_vpc.paramify_solo_vpc.id
  availability_zone = "us-west-2b"
  cidr_block        = "10.1.2.0/24"
}

resource "aws_subnet" "paramify_solo_private2" {
  tags = {
    Name = "${var.aws_prefix}-private2"
  }
  vpc_id            = aws_vpc.paramify_solo_vpc.id
  availability_zone = "us-west-2c"
  cidr_block        = "10.1.3.0/24"
}

resource "aws_ec2_instance_connect_endpoint" "paramify_solo_eic" {
  tags = {
    Name = "${var.aws_prefix}-eic"
  }
  subnet_id          = aws_subnet.paramify_solo_private1.id
  security_group_ids = [aws_security_group.paramify_solo_eic_sg.id]
  preserve_client_ip = false
}

resource "aws_internet_gateway" "paramify_solo_igw" {
  tags = {
    Name = "${var.aws_prefix}-igw"
  }
  vpc_id = aws_vpc.paramify_solo_vpc.id
}

resource "aws_route_table" "paramify_solo_public_rt" {
  tags = {
    Name = "${var.aws_prefix}-public-rt"
  }
  vpc_id = aws_vpc.paramify_solo_vpc.id
  route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.paramify_solo_igw.id
    }
}

resource "aws_route_table_association" "paramify_solo_public1_rta" {
    subnet_id = aws_subnet.paramify_solo_public1.id
    route_table_id = aws_route_table.paramify_solo_public_rt.id
}

resource "aws_route_table_association" "paramify_solo_public2_rta" {
    subnet_id = aws_subnet.paramify_solo_public2.id
    route_table_id = aws_route_table.paramify_solo_public_rt.id
}

resource "aws_eip" "paramify_solo_eip" {
  tags = {
    Name = "${var.aws_prefix}-eip"
  }
  domain = "vpc"
}

resource "aws_nat_gateway" "paramify_solo_nat" {
  tags = {
    Name = "${var.aws_prefix}-nat"
  }
  allocation_id = aws_eip.paramify_solo_eip.id
  subnet_id = aws_subnet.paramify_solo_public1.id
}

resource "aws_route_table" "paramify_solo_private_rt" {
  tags = {
    Name = "${var.aws_prefix}-private-rt"
  }
  vpc_id = aws_vpc.paramify_solo_vpc.id
  route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.paramify_solo_nat.id
    }
}

resource "aws_route_table_association" "paramify_solo_private1_rta" {
    subnet_id = aws_subnet.paramify_solo_private1.id
    route_table_id = aws_route_table.paramify_solo_private_rt.id
}

resource "aws_route_table_association" "paramify_solo_private2_rta" {
    subnet_id = aws_subnet.paramify_solo_private2.id
    route_table_id = aws_route_table.paramify_solo_private_rt.id
}


###########################################################################
## SECURITY GROUPS
###########################################################################

resource "aws_security_group" "paramify_solo_lb_sg" {
  name        = "${var.aws_prefix}-lb-sg"
  description = "Allow specific IPs to reach lb"
  vpc_id      = aws_vpc.paramify_solo_vpc.id

  # Allow incoming 443 for HTTPS to app (backend port 3000)
  # [ <allowed_ips> --> LB 443 ] --> EC2 3000
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # Allow incoming 8443 for HTTPS to installer (backend port 8800)
  # [ <allowed_ips> --> LB 8443 ] --> EC2 8800
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # Allow outgoing to port 3000 for app on EC2 (private)
  # <allowed_ips> --> [ LB 443 --> EC2 3000 ]
  egress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.paramify_solo_private1.cidr_block, aws_subnet.paramify_solo_private2.cidr_block]
  }

  # Allow outgoing to port 8800 for installer on EC2 (private)
  # <allowed_ips> --> [ LB 8443 --> EC2 8800 ]
  egress {
    from_port   = 8800
    to_port     = 8800
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.paramify_solo_private1.cidr_block, aws_subnet.paramify_solo_private2.cidr_block]
  }
}

resource "aws_security_group" "paramify_solo_db_sg" {
  name        = "${var.aws_prefix}-db-sg"
  description = "Allow database traffic from private subnet"
  vpc_id      = aws_vpc.paramify_solo_vpc.id

  # Allow app/installer access to the DB port
  ingress {
    from_port   = "${var.db_port}"
    to_port     = "${var.db_port}"
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.paramify_solo_private1.cidr_block, aws_subnet.paramify_solo_private2.cidr_block]
  }
}

resource "aws_security_group" "paramify_solo_app_sg" {
  name        = "${var.aws_prefix}-app-sg"
  description = "Allow selected communication in and out from App"
  vpc_id      = aws_vpc.paramify_solo_vpc.id

  # Allow incoming to port 3000 from LB
  # <allowed_ips> --> [ LB 443 --> EC2 3000 ]
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.paramify_solo_public1.cidr_block, aws_subnet.paramify_solo_public2.cidr_block]
  }

  # Allow incoming to port 8800 from LB
  # <allowed_ips> --> [ LB 8443 --> EC2 8800 ]
  ingress {
    from_port       = 8800
    to_port         = 8800
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.paramify_solo_public1.cidr_block, aws_subnet.paramify_solo_public2.cidr_block]
  }

  # Allow EIC SSH access to app EC2 instance
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.paramify_solo_eic_sg.id]
  }

  # Allow SMTP from app out to internet (optional for mail)
  egress {
    from_port   = 25
    to_port     = 25
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP from app out to internet
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from app out to internet
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SMTPS from app out to internet (optional for mail)
  egress {
    from_port   = 465
    to_port     = 465
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow access to DB port from app
  egress {
    from_port   = "${var.db_port}"
    to_port     = "${var.db_port}"
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.paramify_solo_private1.cidr_block, aws_subnet.paramify_solo_private2.cidr_block]
  }
}

resource "aws_security_group" "paramify_solo_eic_sg" {
  name        = "${var.aws_prefix}-eic-sg"
  description = "Allow SSH from EIC to the private subnet"
  vpc_id      = aws_vpc.paramify_solo_vpc.id

  # Allow SSH from EIC to private subnet (EC2)
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.paramify_solo_private1.cidr_block, aws_subnet.paramify_solo_private2.cidr_block]
  }
}


###########################################################################
## LB (App 443->3000 and KOTS installer 8443->8800)
###########################################################################

resource "aws_lb" "paramify_solo_lb" {
  name               = "${var.aws_prefix}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.paramify_solo_lb_sg.id]
  subnets            = [aws_subnet.paramify_solo_public1.id, aws_subnet.paramify_solo_public2.id]

  enable_deletion_protection = false
  enable_http2 = true
  enable_cross_zone_load_balancing = false
}

# Listener for application (LB 443 -> backend 3000)
resource "aws_lb_listener" "paramify_solo_lb_app_listener" {
  tags = {
    Name = "${var.aws_prefix}-lb-app-listener"
  }
  load_balancer_arn = aws_lb.paramify_solo_lb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.ssl_cert

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.paramify_solo_lb_app_target.arn
  }
}

# Target group for application (LB 443 -> backend 3000)
resource "aws_lb_target_group" "paramify_solo_lb_app_target" {
  name        = "${var.aws_prefix}-lb-app-target"
  port        = 3000
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = aws_vpc.paramify_solo_vpc.id

  health_check {
    path              = "/health-check"
    protocol          = "HTTPS"
    healthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "paramify_solo_lb_app_attach" {
  target_group_arn = aws_lb_target_group.paramify_solo_lb_app_target.arn
  target_id        = aws_instance.paramify_solo_app.id
  port             = 3000
}

# Listener for KOTS installer (LB 8443 -> backend 8800)
resource "aws_lb_listener" "paramify_solo_lb_kots_listener" {
  tags = {
    Name = "${var.aws_prefix}-lb-kots-listener"
  }
  load_balancer_arn = aws_lb.paramify_solo_lb.arn
  port              = 8443
  protocol          = "HTTPS"
  certificate_arn   = var.ssl_cert

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.paramify_solo_lb_kots_target.arn
  }
}

# Target group for KOTS installer (LB 8443 -> backend 8800)
resource "aws_lb_target_group" "paramify_solo_lb_kots_target" {
  name        = "${var.aws_prefix}-lb-kots-target"
  port        = 8800
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = aws_vpc.paramify_solo_vpc.id
}

resource "aws_lb_target_group_attachment" "paramify_solo_lb_kots_attach" {
  target_group_arn = aws_lb_target_group.paramify_solo_lb_kots_target.arn
  target_id        = aws_instance.paramify_solo_app.id
  port             = 8800
}


###########################################################################
## DB & S3
###########################################################################

resource "aws_db_instance" "paramify_solo_db" {
  identifier             = "${var.aws_prefix}-db"
  allocated_storage      = 20
  storage_type           = "gp3"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.t3.micro"
  db_name                = "postgres"
  username               = "postgres"
  password               = "${var.db_password}"
  port                   = "${var.db_port}"
  vpc_security_group_ids = [aws_security_group.paramify_solo_db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.paramify_solo_db_subnet_group.name
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "paramify_solo_db_subnet_group" {
  name       = "${var.aws_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.paramify_solo_private1.id, aws_subnet.paramify_solo_private2.id]
}

resource "aws_s3_bucket" "paramify_solo_s3" {
  bucket = "${var.aws_prefix}-s3"
}

resource "aws_s3_bucket_ownership_controls" "paramify_solo_s3_ownership" {
  bucket = aws_s3_bucket.paramify_solo_s3.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "paramify_solo_s3_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.paramify_solo_s3_ownership]
  bucket     = aws_s3_bucket.paramify_solo_s3.id
  acl        = "private"
}


###########################################################################
## EC2 (App) and IAM node role (to S3)
###########################################################################

resource "aws_instance" "paramify_solo_app" {
  tags = {
    Name = "${var.aws_prefix}-app"
  }
  ami                    = data.aws_ssm_parameter.linux-ami.value
  instance_type          = "t3.xlarge"
  subnet_id              = aws_subnet.paramify_solo_private1.id
  key_name               = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.paramify_solo_app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.paramify_solo_node_profile.id

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_size = 32
    volume_type = "gp3"
  }

  # See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-using-eice.html to SSH
}

# EC2 instance node role (will have policy for S3)
resource "aws_iam_role" "paramify_solo_node_role" {
  name = "${var.aws_prefix}-node-role"

  assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Action: "sts:AssumeRole",
        Principal: {
          Service: "ec2.amazonaws.com"
        },
        Effect: "Allow",
        Sid: ""
      }
    ]
  })
}

resource "aws_iam_instance_profile" "paramify_solo_node_profile" {
  name = "${var.aws_prefix}-node-profile"
  role = aws_iam_role.paramify_solo_node_role.name
}

# Policy to attach to EC2 instance node for access to S3
resource "aws_iam_role_policy" "paramify_solo_s3_policy" {
  name = "${var.aws_prefix}-s3-policy"
  role = aws_iam_role.paramify_solo_node_role.id

  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: ["s3:ListBucket"],
        Resource: [aws_s3_bucket.paramify_solo_s3.arn]
      },
      {
        Effect: "Allow",
        Action: [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        Resource: ["${aws_s3_bucket.paramify_solo_s3.arn}/*"]
      }
    ]
  })
}
