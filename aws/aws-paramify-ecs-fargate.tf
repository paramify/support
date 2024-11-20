# If your cluster is in the AWS GovCloud (US-East) or AWS GovCloud (US-West)
# AWS Regions, then replace arn:aws: with arn:aws-us-gov:.

###########################################################################
## NETWORK
###########################################################################

resource "aws_vpc" "paramify_ecs_vpc" {
  tags = {
    Name = "${var.aws_prefix}-vpc"
  }
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "paramify_ecs_public1" {
  tags = {
    Name = "${var.aws_prefix}-public1"
  }
  vpc_id            = aws_vpc.paramify_ecs_vpc.id
  availability_zone = "us-west-2b"
  cidr_block        = "10.1.0.0/24"
}

resource "aws_subnet" "paramify_ecs_public2" {
  tags = {
    Name = "${var.aws_prefix}-public2"
  }
  vpc_id            = aws_vpc.paramify_ecs_vpc.id
  availability_zone = "us-west-2c"
  cidr_block        = "10.1.1.0/24"
}

resource "aws_subnet" "paramify_ecs_private1" {
  tags = {
    Name = "${var.aws_prefix}-private1"
  }
  vpc_id            = aws_vpc.paramify_ecs_vpc.id
  availability_zone = "us-west-2b"
  cidr_block        = "10.1.2.0/24"
}

resource "aws_subnet" "paramify_ecs_private2" {
  tags = {
    Name = "${var.aws_prefix}-private2"
  }
  vpc_id            = aws_vpc.paramify_ecs_vpc.id
  availability_zone = "us-west-2c"
  cidr_block        = "10.1.3.0/24"
}

resource "aws_internet_gateway" "paramify_ecs_igw" {
  tags = {
    Name = "${var.aws_prefix}-igw"
  }
  vpc_id = aws_vpc.paramify_ecs_vpc.id
}

resource "aws_route_table" "paramify_ecs_public_rt" {
  tags = {
    Name = "${var.aws_prefix}-public-rt"
  }
  vpc_id = aws_vpc.paramify_ecs_vpc.id
  route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.paramify_ecs_igw.id
    }
}

resource "aws_route_table_association" "paramify_ecs_public1_rta" {
    subnet_id = aws_subnet.paramify_ecs_public1.id
    route_table_id = aws_route_table.paramify_ecs_public_rt.id
}

resource "aws_route_table_association" "paramify_ecs_public2_rta" {
    subnet_id = aws_subnet.paramify_ecs_public2.id
    route_table_id = aws_route_table.paramify_ecs_public_rt.id
}

resource "aws_eip" "paramify_ecs_eip" {
  tags = {
    Name = "${var.aws_prefix}-eip"
  }
  domain = "vpc"
}

resource "aws_nat_gateway" "paramify_ecs_nat" {
  tags = {
    Name = "${var.aws_prefix}-nat"
  }
  allocation_id = aws_eip.paramify_ecs_eip.id
  subnet_id = aws_subnet.paramify_ecs_public1.id
}

resource "aws_route_table" "paramify_ecs_private_rt" {
  tags = {
    Name = "${var.aws_prefix}-private-rt"
  }
  vpc_id = aws_vpc.paramify_ecs_vpc.id
  route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.paramify_ecs_nat.id
    }
}

resource "aws_route_table_association" "paramify_ecs_private1_rta" {
    subnet_id = aws_subnet.paramify_ecs_private1.id
    route_table_id = aws_route_table.paramify_ecs_private_rt.id
}

resource "aws_route_table_association" "paramify_ecs_private2_rta" {
    subnet_id = aws_subnet.paramify_ecs_private2.id
    route_table_id = aws_route_table.paramify_ecs_private_rt.id
}


###########################################################################
## SECURITY GROUPS
###########################################################################

resource "aws_security_group" "paramify_ecs_db_sg" {
  name        = "${var.aws_prefix}-db-sg"
  description = "Allow database traffic from private subnet"
  vpc_id      = aws_vpc.paramify_ecs_vpc.id

  # Allow app/installer access to the DB port
  ingress {
    from_port   = "${var.db_port}"
    to_port     = "${var.db_port}"
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.paramify_ecs_private1.cidr_block, aws_subnet.paramify_ecs_private2.cidr_block]
  }
}

resource "aws_security_group" "paramify_ecs_app_sg" {
  name        = "${var.aws_prefix}-app-sg"
  description = "Allow selected communication in and out from app"
  vpc_id      = aws_vpc.paramify_ecs_vpc.id

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

  # Allow SMTP from app out to internet (optional for mail)
  egress {
    from_port   = var.smtp_port
    to_port     = var.smtp_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow access to DB port from app
  egress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.paramify_ecs_private1.cidr_block, aws_subnet.paramify_ecs_private2.cidr_block]
  }

  # Allow access to app from LB
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.paramify_ecs_public1.cidr_block, aws_subnet.paramify_ecs_public2.cidr_block]
  }
}

resource "aws_security_group" "paramify_ecs_lb_sg" {
  name        = "${var.aws_prefix}-lb-sg"
  description = "Allow specific IPs to reach lb"
  vpc_id      = aws_vpc.paramify_ecs_vpc.id

  # Allow incoming 443 for HTTPS to app (backend port 3000)
  # [ <allowed_ips> --> LB 443 ] --> paramify 3000
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # Allow outgoing to port 3000 for app on EC2 (private)
  # <allowed_ips> --> [ LB 443 --> paramify 3000 ]
  egress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.paramify_ecs_private1.cidr_block, aws_subnet.paramify_ecs_private2.cidr_block]
  }
}


###########################################################################
## DB & S3
###########################################################################

resource "aws_db_instance" "paramify_ecs_db" {
  identifier             = "${var.aws_prefix}-db"
  allocated_storage      = 20
  storage_type           = "gp3"
  engine                 = "postgres"
  engine_version         = "16.4"
  instance_class         = "db.t3.small"
  db_name                = var.db_name
  username               = var.db_user
  password               = var.db_password
  port                   = var.db_port
  vpc_security_group_ids = [aws_security_group.paramify_ecs_db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.paramify_ecs_db_subnet_group.name
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "paramify_ecs_db_subnet_group" {
  name       = "${var.aws_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.paramify_ecs_private1.id, aws_subnet.paramify_ecs_private2.id]
}

resource "aws_s3_bucket" "paramify_ecs_s3" {
  bucket = "${var.aws_prefix}-s3"
}

resource "aws_s3_bucket_ownership_controls" "paramify_ecs_s3_ownership" {
  bucket = aws_s3_bucket.paramify_ecs_s3.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "paramify_ecs_s3_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.paramify_ecs_s3_ownership]
  bucket     = aws_s3_bucket.paramify_ecs_s3.id
  acl        = "private"
}


###########################################################################
## IAM Roles (Task Execution, Task, and Policies)
###########################################################################

resource "aws_iam_role" "paramify_ecs_task_execution_role" {
  name = "${var.aws_prefix}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]}
  )
}

resource "aws_iam_role_policy_attachment" "paramify_ecs_task_execution_role_attach" {
  role       = aws_iam_role.paramify_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "paramify_ecs_task_ssm_policy" {
  name        = "${var.aws_prefix}-ecs-task-ssm-policy"
  description = "Policy that allows Paramify access to S3"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters",
        ],
        "Resource": [
          aws_ssm_parameter.paramify_ecs_cert_docrobot_key.arn,
          aws_ssm_parameter.paramify_ecs_cert_docrobot_crt.arn,
          aws_ssm_parameter.paramify_ecs_cert_paramify_key.arn,
          aws_ssm_parameter.paramify_ecs_cert_paramify_crt.arn,
          aws_ssm_parameter.paramify_ecs_db_connection_url.arn,
          aws_ssm_parameter.paramify_ecs_google_client_secret.arn,
          aws_ssm_parameter.paramify_ecs_magic_link_secret.arn,
          aws_ssm_parameter.paramify_ecs_session_secret.arn,
          aws_ssm_parameter.paramify_ecs_smtp_password.arn,
          aws_secretsmanager_secret.paramify_ecs_registry_creds.arn,
        ]
      }
    ]}
  )
}

resource "aws_iam_role_policy_attachment" "paramicy_ecs_task_ssm_role_attach" {
  role       = aws_iam_role.paramify_ecs_task_execution_role.name
  policy_arn = aws_iam_policy.paramify_ecs_task_ssm_policy.arn
}

resource "aws_iam_role" "paramify_ecs_task_role" {
  name = "${var.aws_prefix}-ecsTaskRole"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]}
  )
}

resource "aws_iam_policy" "paramify_ecs_task_policy" {
  name        = "${var.aws_prefix}-ecs-task-policy"
  description = "Policy that allows Paramify access to S3"

  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: ["s3:ListBucket"],
        Resource: [aws_s3_bucket.paramify_ecs_s3.arn]
      },
      {
        Effect: "Allow",
        Action: [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        Resource: ["${aws_s3_bucket.paramify_ecs_s3.arn}/*"]
      }
    ]}
  )
}

resource "aws_iam_role_policy_attachment" "paramicy_ecs_task_role_attach" {
  role       = aws_iam_role.paramify_ecs_task_role.name
  policy_arn = aws_iam_policy.paramify_ecs_task_policy.arn
}


###########################################################################
## Fargate Service Load Balancer
###########################################################################

resource "aws_lb" "paramify_ecs_lb" {
  name               = "${var.aws_prefix}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.paramify_ecs_lb_sg.id]
  subnets            = [aws_subnet.paramify_ecs_public1.id, aws_subnet.paramify_ecs_public2.id]

  enable_deletion_protection = false
  enable_http2 = true
  enable_cross_zone_load_balancing = false
}

# Listener for application (LB 443 -> backend 3000)
resource "aws_lb_listener" "paramify_ecs_lb_app_listener" {
  tags = {
    Name = "${var.aws_prefix}-lb-app-listener"
  }
  load_balancer_arn = aws_lb.paramify_ecs_lb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.ssl_cert
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.paramify_ecs_lb_app_target.arn
  }
}

# Target group for application (LB 443 -> backend 3000)
resource "aws_lb_target_group" "paramify_ecs_lb_app_target" {
  name        = "${var.aws_prefix}-lb-app-target"
  port        = 3000
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = aws_vpc.paramify_ecs_vpc.id

  health_check {
    path                = "/health-check"
    protocol            = "HTTPS"
    matcher             = "200"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


###########################################################################
## ECS Cluster and Service
###########################################################################

resource "aws_ecs_cluster" "paramify_ecs_cluster" {
  name     = "${var.aws_prefix}-ecs"
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.paramify_ecs_cluster.name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
  }
}

resource "aws_ecs_service" "paramify_ecs_service" {
  name                               = "${var.aws_prefix}-ecs-service"
  cluster                            = aws_ecs_cluster.paramify_ecs_cluster.id
  task_definition                    = "${aws_ecs_task_definition.paramify_ecs_taskdef.family}:${aws_ecs_task_definition.paramify_ecs_taskdef.revision}"
  desired_count                      = 1
  # deployment_minimum_healthy_percent = 50
  # deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 60
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.paramify_ecs_app_sg.id]
    subnets          = [aws_subnet.paramify_ecs_private1.id, aws_subnet.paramify_ecs_private2.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.paramify_ecs_lb_app_target.arn
    container_name   = "paramify"
    container_port   = 3000
  }

  # lifecycle {
  #   ignore_changes = [task_definition, desired_count]
  # }
}


###########################################################################
## Self-signed certs for the containers
###########################################################################

resource "tls_private_key" "paramify_ecs_cert_key_paramify" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_private_key" "paramify_ecs_cert_key_docrobot" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "paramify_ecs_cert_paramify" {
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
  private_key_pem = tls_private_key.paramify_ecs_cert_key_paramify.private_key_pem
  subject {
    common_name  = "paramify"
    organization = "Paramify"
  }
  validity_period_hours = 87600
}

resource "tls_self_signed_cert" "paramify_ecs_cert_docrobot" {
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
  private_key_pem = tls_private_key.paramify_ecs_cert_key_docrobot.private_key_pem
  subject {
    common_name  = "document-robot"
    organization = "Paramify"
  }
  validity_period_hours = 87600
}

resource "aws_ssm_parameter" "paramify_ecs_cert_paramify_key" {
  name  = "/${var.aws_prefix}/ssl/paramify_key"
  type  = "SecureString"
  value = tls_self_signed_cert.paramify_ecs_cert_paramify.private_key_pem
}

resource "aws_ssm_parameter" "paramify_ecs_cert_docrobot_key" {
  name  = "/${var.aws_prefix}/ssl/document-robot_key"
  type  = "SecureString"
  value = tls_self_signed_cert.paramify_ecs_cert_docrobot.private_key_pem
}

resource "aws_ssm_parameter" "paramify_ecs_cert_paramify_crt" {
  name  = "/${var.aws_prefix}/ssl/paramify_cert"
  type  = "SecureString"
  value = tls_self_signed_cert.paramify_ecs_cert_paramify.cert_pem
}

resource "aws_ssm_parameter" "paramify_ecs_cert_docrobot_crt" {
  name  = "/${var.aws_prefix}/ssl/document-robot_cert"
  type  = "SecureString"
  value = tls_self_signed_cert.paramify_ecs_cert_docrobot.cert_pem
}


###########################################################################
## Secrets to store in SSM for use by containers
###########################################################################

resource "aws_ssm_parameter" "paramify_ecs_smtp_password" {
  name  = "/${var.aws_prefix}/paramify/smtp_password"
  type  = "SecureString"
  value = var.smtp_password
}

resource "aws_ssm_parameter" "paramify_ecs_magic_link_secret" {
  name  = "/${var.aws_prefix}/paramify/magic_link_secret"
  type  = "SecureString"
  value = var.magic_link_secret
}

resource "aws_ssm_parameter" "paramify_ecs_session_secret" {
  name  = "/${var.aws_prefix}/paramify/session_secret"
  type  = "SecureString"
  value = var.session_secret
}

resource "aws_ssm_parameter" "paramify_ecs_google_client_secret" {
  name  = "/${var.aws_prefix}/paramify/google_client_secret"
  type  = "SecureString"
  value = var.auth_google_client_secret
}

resource "aws_ssm_parameter" "paramify_ecs_db_connection_url" {
  name  = "/${var.aws_prefix}/paramify/db_connection_url"
  type  = "SecureString"
  value = "postgres://${var.db_user}:${urlencode(var.db_password)}@${element(split(":", aws_db_instance.paramify_ecs_db.endpoint), 0)}:${var.db_port}/${var.db_name}?connection_limit=10&pool_timeout=30&sslmode=require"
}

resource "aws_secretsmanager_secret" "paramify_ecs_registry_creds" {
  name = "/${var.aws_prefix}/paramify/registry_creds"
}

resource "aws_secretsmanager_secret_version" "paramify_ecs_registry_creds_version" {
  secret_id     = aws_secretsmanager_secret.paramify_ecs_registry_creds.id
  secret_string = jsonencode({
    username = var.paramify_license,
    password = var.paramify_license
  })
}


###########################################################################
## Fargate Task
###########################################################################

resource "aws_ecs_task_definition" "paramify_ecs_taskdef" {
  family                   = "${var.aws_prefix}-taskdef"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "3072"
  execution_role_arn       = aws_iam_role.paramify_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.paramify_ecs_task_role.arn

  container_definitions = jsonencode([{
    name        = "paramify"
    image       = var.paramify_image
    essential   = true
    repositoryCredentials = {
      credentialsParameter = aws_secretsmanager_secret.paramify_ecs_registry_creds.arn
    }
    logConfiguration = {
      logDriver = "awslogs",
      options   = {
        awslogs-group         = var.cloudwatch_group
        awslogs-region        = var.region
        awslogs-stream-prefix = var.aws_prefix
        mode                  = "non-blocking"
        max-buffer-size       = "2m"
      }
    }
    healthCheck = {
      retries = 10
      command = [ "CMD-SHELL", "wget https://localhost:3000/health-check#container -q --spider || exit 1" ]
      timeout: 5
      interval: 10
      startPeriod: 60
    }

    environment = [
      { name = "DOCUMENT_ROBOT_BASE_URL", value = "https://localhost:5078" },
      { name = "IS_KUBERNETES", value = "true" },
      { name = "FEDRAMP", value = "true" },
      { name = "LISAAS", value = "true" },
      { name = "NODE_ENV", value = "production" },
      { name = "PORT", value = "3000" },
      { name = "ADMIN_EMAIL", value = var.admin_email },
      { name = "APP_BASE_URL", value = var.app_base_url },
      { name = "AWS_STORAGE_BUCKET_NAME", value = aws_s3_bucket.paramify_ecs_s3.bucket },
      { name = "AUTH_SMTP_ENABLED", value = "true" },
      { name = "SMTP_ENABLED", value = "true" },
      { name = "SMTP_FROM", value = var.smtp_from },
      { name = "SMTP_HOST", value = var.smtp_host },
      { name = "SMTP_PORT", value = var.smtp_port },
      { name = "SMTP_USER", value = var.smtp_user },
      { name = "AUTH_GOOGLE_ENABLED", value = var.auth_google_enabled },
      { name = "AUTH_GOOGLE_CLIENT_ID", value = var.auth_google_client_id },
    ]
    secrets = [
      { name = "AUTH_GOOGLE_CLIENT_SECRET", valueFrom = aws_ssm_parameter.paramify_ecs_google_client_secret.arn },
      { name = "DB_CONNECTION_URL", valueFrom = aws_ssm_parameter.paramify_ecs_db_connection_url.arn },
      { name = "MAGIC_LINK_SECRET", valueFrom = aws_ssm_parameter.paramify_ecs_magic_link_secret.arn },
      { name = "SESSION_SECRET", valueFrom = aws_ssm_parameter.paramify_ecs_session_secret.arn },
      { name = "SMTP_PASSWORD", valueFrom = aws_ssm_parameter.paramify_ecs_smtp_password.arn },
      { name = "TLS_CERT", valueFrom = aws_ssm_parameter.paramify_ecs_cert_paramify_crt.arn },
      { name = "TLS_KEY", valueFrom = aws_ssm_parameter.paramify_ecs_cert_paramify_key.arn },
    ]

    portMappings = [{
      protocol      = "tcp"
      containerPort = 3000
      hostPort      = 3000
    }]
  },{
    name        = "document-robot"
    image       = var.docrobot_image
    essential   = true
    repositoryCredentials = {
      credentialsParameter = aws_secretsmanager_secret.paramify_ecs_registry_creds.arn
    }
    logConfiguration = {
      logDriver = "awslogs",
      options   = {
        awslogs-group         = var.cloudwatch_group
        awslogs-region        = var.region
        awslogs-stream-prefix = var.aws_prefix
        mode                  = "non-blocking"
        max-buffer-size       = "2m"
      }
    }

    environment = [
      { name  = "AWS_REGION", value = var.region },
      { name  = "AWS_S3_BUCKET", value = aws_s3_bucket.paramify_ecs_s3.bucket },
      { name  = "NODE_ENV", value = "production" },
      { name  = "STORAGE_PROVIDER", value = "AWSS3" },
    ]
    secrets = [
      { name = "TLS_CERT", valueFrom = aws_ssm_parameter.paramify_ecs_cert_docrobot_crt.arn },
      { name = "TLS_KEY", valueFrom = aws_ssm_parameter.paramify_ecs_cert_docrobot_key.arn },
    ]

    portMappings = [{
      protocol      = "tcp"
      containerPort = 5078
      hostPort      = 5078
    }]
  }])
}
