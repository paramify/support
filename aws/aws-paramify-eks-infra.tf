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

variable "db_password" {
  description = "RDS database password used by Paramify."
  default     = "super_secret_password"
}

variable "db_port" {
  description = "RDS database port used by Paramify."
  default     = "5432"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy Paramify into."
  default     = "paramify"
}

variable "aws_prefix" {
  description = "Prefix for naming the created AWS resources."
  default     = "paramify-mycompany"
}

# # Note: The commented sections here and below can be used if a custom AMI is required
# variable "eks_node_ami" {
#   description = "Custom EC2 AMI to use for the EKS nodes (otherwise default to Amazon Linux)."
#   default     = ""
# }

# variable "key_pair" {
#   description = "Key pair to assign to the EC2 instance for SSH access."
#   default     = "my-key-pair"
# }

variable "k8s_version" {
  description = "Kubernetes version to use for the EKS cluster."
  default     = "1.31"
}


###########################################################################
## CORE
###########################################################################

provider "aws" {
  region  = var.region
  profile = var.sso_profile
}

# data "aws_ssm_parameter" "linux-ami" {
#   # Lookup the AMI for EKS optimized Amazon Linux 2
#   name = "/aws/service/eks/optimized-ami/${var.k8s_version}/amazon-linux-2/recommended/image_id"
# }


###########################################################################
## OUTPUT
###########################################################################

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.paramify_eks_cluster.name
}

output "db_dns" {
  description = "DB endpoint to configure for application"
  value       = element(split(":", aws_db_instance.paramify_eks_db.endpoint), 0)
}

output "region" {
  description = "Region for created resources"
  value       = var.region
}

output "s3_bucket" {
  description = "S3 bucket created to store images and documents"
  value       = aws_s3_bucket.paramify_eks_s3.bucket
}

output "s3_role" {
  description = "S3 role created to allow access to images and documents"
  value       = aws_iam_role.paramify_eks_sa_role.arn
}


###########################################################################
## NETWORK
###########################################################################

resource "aws_vpc" "paramify_eks_vpc" {
  tags = {
    Name = "${var.aws_prefix}-vpc"
  }
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "paramify_eks_public1" {
  tags = {
    Name = "${var.aws_prefix}-public1"
  }
  vpc_id            = aws_vpc.paramify_eks_vpc.id
  availability_zone = "us-west-2b"
  cidr_block        = "10.1.0.0/24"
}

resource "aws_subnet" "paramify_eks_public2" {
  tags = {
    Name = "${var.aws_prefix}-public2"
  }
  vpc_id            = aws_vpc.paramify_eks_vpc.id
  availability_zone = "us-west-2c"
  cidr_block        = "10.1.1.0/24"
}

resource "aws_subnet" "paramify_eks_private1" {
  tags = {
    Name = "${var.aws_prefix}-private1"
  }
  vpc_id            = aws_vpc.paramify_eks_vpc.id
  availability_zone = "us-west-2b"
  cidr_block        = "10.1.2.0/24"
}

resource "aws_subnet" "paramify_eks_private2" {
  tags = {
    Name = "${var.aws_prefix}-private2"
  }
  vpc_id            = aws_vpc.paramify_eks_vpc.id
  availability_zone = "us-west-2c"
  cidr_block        = "10.1.3.0/24"
}

resource "aws_internet_gateway" "paramify_eks_igw" {
  tags = {
    Name = "${var.aws_prefix}-igw"
  }
  vpc_id = aws_vpc.paramify_eks_vpc.id
}

resource "aws_route_table" "paramify_eks_public_rt" {
  tags = {
    Name = "${var.aws_prefix}-public-rt"
  }
  vpc_id = aws_vpc.paramify_eks_vpc.id
  route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.paramify_eks_igw.id
    }
}

resource "aws_route_table_association" "paramify_eks_public1_rta" {
    subnet_id = aws_subnet.paramify_eks_public1.id
    route_table_id = aws_route_table.paramify_eks_public_rt.id
}

resource "aws_route_table_association" "paramify_eks_public2_rta" {
    subnet_id = aws_subnet.paramify_eks_public2.id
    route_table_id = aws_route_table.paramify_eks_public_rt.id
}

resource "aws_eip" "paramify_eks_eip" {
  tags = {
    Name = "${var.aws_prefix}-eip"
  }
  domain = "vpc"
}

resource "aws_nat_gateway" "paramify_eks_nat" {
  tags = {
    Name = "${var.aws_prefix}-nat"
  }
  allocation_id = aws_eip.paramify_eks_eip.id
  subnet_id = aws_subnet.paramify_eks_public1.id
}

resource "aws_route_table" "paramify_eks_private_rt" {
  tags = {
    Name = "${var.aws_prefix}-private-rt"
  }
  vpc_id = aws_vpc.paramify_eks_vpc.id
  route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.paramify_eks_nat.id
    }
}

resource "aws_route_table_association" "paramify_eks_private1_rta" {
    subnet_id = aws_subnet.paramify_eks_private1.id
    route_table_id = aws_route_table.paramify_eks_private_rt.id
}

resource "aws_route_table_association" "paramify_eks_private2_rta" {
    subnet_id = aws_subnet.paramify_eks_private2.id
    route_table_id = aws_route_table.paramify_eks_private_rt.id
}


###########################################################################
## SECURITY GROUPS
###########################################################################

resource "aws_security_group" "paramify_eks_db_sg" {
  name        = "${var.aws_prefix}-db-sg"
  description = "Allow database traffic from private subnet"
  vpc_id      = aws_vpc.paramify_eks_vpc.id

  # Allow app/installer access to the DB port
  ingress {
    from_port   = "${var.db_port}"
    to_port     = "${var.db_port}"
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.paramify_eks_private1.cidr_block, aws_subnet.paramify_eks_private2.cidr_block]
  }
}

resource "aws_security_group" "paramify_eks_app_sg" {
  name        = "${var.aws_prefix}-app-sg"
  description = "Allow selected communication in and out from App"
  vpc_id      = aws_vpc.paramify_eks_vpc.id

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
    cidr_blocks = [aws_subnet.paramify_eks_private1.cidr_block, aws_subnet.paramify_eks_private2.cidr_block]
  }
}


###########################################################################
## DB & S3
###########################################################################

resource "aws_db_instance" "paramify_eks_db" {
  identifier             = "${var.aws_prefix}-db"
  allocated_storage      = 20
  storage_type           = "gp3"
  engine                 = "postgres"
  engine_version         = "16.9"
  instance_class         = "db.t3.micro"
  db_name                = "postgres"
  username               = "postgres"
  password               = "${var.db_password}"
  port                   = "${var.db_port}"
  vpc_security_group_ids = [aws_security_group.paramify_eks_db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.paramify_eks_db_subnet_group.name
  skip_final_snapshot    = true

  lifecycle {
    ignore_changes = [engine_version]
  }
}

resource "aws_db_subnet_group" "paramify_eks_db_subnet_group" {
  name       = "${var.aws_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.paramify_eks_private1.id, aws_subnet.paramify_eks_private2.id]
}

resource "aws_s3_bucket" "paramify_eks_s3" {
  bucket = "${var.aws_prefix}-s3"
}

resource "aws_s3_bucket_ownership_controls" "paramify_eks_s3_ownership" {
  bucket = aws_s3_bucket.paramify_eks_s3.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "paramify_eks_s3_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.paramify_eks_s3_ownership]
  bucket     = aws_s3_bucket.paramify_eks_s3.id
  acl        = "private"
}


###########################################################################
## IAM Roles (Cluster, Node, Service Account, EBS, VPC CNI, and OIDC)
###########################################################################

# Cluster role
resource "aws_iam_role" "paramify_eks_cluster_role" {
  name = "${var.aws_prefix}-cluster-role"

  assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Action: "sts:AssumeRole",
        Principal: {
          Service: [ "eks.amazonaws.com" ]
        },
        Effect: "Allow",
        Sid: ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "paramify_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.paramify_eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "paramify_eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.paramify_eks_cluster_role.name
}

# Worker Node role
resource "aws_iam_role" "paramify_eks_node_role" {
  name = "${var.aws_prefix}-node-role"

  assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Action: "sts:AssumeRole",
        Principal: {
          Service: [ "ec2.amazonaws.com" ]
        },
        Effect: "Allow",
        Sid: ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "paramify_eks_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.paramify_eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "paramify_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.paramify_eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "paramify_eks_ecr_build_policy" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role    = aws_iam_role.paramify_eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "paramify_eks_ecr_read_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.paramify_eks_node_role.name
}

resource "aws_iam_instance_profile" "paramify_eks_node_profile" {
  name = "${var.aws_prefix}-node-profile"
  role = aws_iam_role.paramify_eks_node_role.name
}

# Service Account policy and role (for S3)
resource "aws_iam_role_policy" "paramify_eks_s3_policy" {
  name = "${var.aws_prefix}-s3-policy"
  role = aws_iam_role.paramify_eks_sa_role.id

  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: ["s3:ListBucket"],
        Resource: [aws_s3_bucket.paramify_eks_s3.arn]
      },
      {
        Effect: "Allow",
        Action: [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        Resource: ["${aws_s3_bucket.paramify_eks_s3.arn}/*"]
      }
    ]
  })
}

data "aws_iam_policy_document" "paramify_eks_sa_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.paramify_eks_cluster.identity.0.oidc.0.issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:paramify"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.paramify_eks_cluster_oidc_provider.arn]
    }
  }
}

resource "aws_iam_role" "paramify_eks_sa_role" {
  name               = "${var.aws_prefix}-eks-sa-role"
  assume_role_policy = data.aws_iam_policy_document.paramify_eks_sa_policy.json
}

# EBS CSI role
data "aws_iam_policy_document" "paramify_eks_ebscsi_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.paramify_eks_cluster_oidc_provider.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.paramify_eks_cluster_oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.paramify_eks_cluster_oidc_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "paramify_eks_ebscsi_role" {
  assume_role_policy = data.aws_iam_policy_document.paramify_eks_ebscsi_policy.json
  name               = "${var.aws_prefix}-eks-ebscsi-role"
}

resource "aws_iam_role_policy_attachment" "paramify_eks_ebscsi_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.paramify_eks_ebscsi_role.name
}

# VPC CNI role
data "aws_iam_policy_document" "paramify_eks_vpccni_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.paramify_eks_cluster_oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.paramify_eks_cluster_oidc_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "paramify_eks_vpccni_role" {
  assume_role_policy = data.aws_iam_policy_document.paramify_eks_vpccni_policy.json
  name               = "${var.aws_prefix}-eks-vpccni-role"
}

resource "aws_iam_role_policy_attachment" "paramify_eks_vpccni_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.paramify_eks_vpccni_role.name
}

# OIDC (auth for service account and VPC CNI)
data "tls_certificate" "paramify_eks_cluster_cert" {
  url = aws_eks_cluster.paramify_eks_cluster.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "paramify_eks_cluster_oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.paramify_eks_cluster_cert.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.paramify_eks_cluster.identity.0.oidc.0.issuer
}


###########################################################################
## EKS Cluster and Node Group
###########################################################################

resource "aws_kms_key" "paramify_eks_key" {
  description = "EKS Secret Encryption Key for ${var.aws_prefix}-eks"
}

resource "aws_kms_alias" "paramify_eks_key_alias" {
  name          = "alias/${var.aws_prefix}-kms-key"
  target_key_id = aws_kms_key.paramify_eks_key.id
}

resource "aws_eks_cluster" "paramify_eks_cluster" {
  name     = "${var.aws_prefix}-eks"
  role_arn = aws_iam_role.paramify_eks_cluster_role.arn
  version  = var.k8s_version

  enabled_cluster_log_types = ["api", "authenticator", "audit", "scheduler", "controllerManager"]

  encryption_config {
    resources = [ "secrets" ]
    provider {
        key_arn = aws_kms_key.paramify_eks_key.arn
    }
  }

  vpc_config {
    endpoint_private_access  = true
    endpoint_public_access   = true  # false to restrict to private subnets
    subnet_ids               = [aws_subnet.paramify_eks_private1.id, aws_subnet.paramify_eks_private2.id]
    security_group_ids       = [aws_security_group.paramify_eks_app_sg.id]
    public_access_cidrs      = var.allowed_ips
  }

  lifecycle {
    ignore_changes = [version]
  }

  depends_on = [ aws_iam_role.paramify_eks_cluster_role ]
}

# resource "aws_launch_template" "paramify_eks_node_template" {
#   name_prefix   = "${var.aws_prefix}-node-template"
#   image_id      = var.eks_node_ami != "" ? var.eks_node_ami : data.aws_ssm_parameter.linux-ami.value
#   instance_type = "t3.large"
#   key_name      = var.key_pair
#
#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       volume_size = 30
#       volume_type = "gp2"
#     }
#   }
#
#   iam_instance_profile {
#     arn = aws_iam_instance_profile.paramify_eks_node_profile.arn
#   }
# }

resource "aws_eks_node_group" "paramify_eks_node_group" {
  cluster_name    = aws_eks_cluster.paramify_eks_cluster.name
  node_group_name = "${var.aws_prefix}-node-group"
  node_role_arn   = aws_iam_role.paramify_eks_node_role.arn

  capacity_type  = "SPOT"  # "ON_DEMAND" or "SPOT"
  instance_types = ["t3.large"]

  # launch_template {
  #   id      = aws_launch_template.paramify_eks_node_template.id
  #   version = aws_launch_template.paramify_eks_node_template.latest_version
  # }

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  subnet_ids = [aws_subnet.paramify_eks_private1.id, aws_subnet.paramify_eks_private2.id]
  depends_on = [aws_eks_cluster.paramify_eks_cluster]
}


###########################################################################
## EKS Addons
###########################################################################

resource "aws_eks_addon" "paramify_eks_ebscsidriver" {
  cluster_name                = aws_eks_cluster.paramify_eks_cluster.name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.paramify_eks_ebscsi_role.arn

  depends_on = [aws_eks_node_group.paramify_eks_node_group]
}

resource "aws_eks_addon" "paramify_eks_vpccni" {
  cluster_name                = aws_eks_cluster.paramify_eks_cluster.name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.16.0-eksbuild.1"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.paramify_eks_vpccni_role.arn

  configuration_values = jsonencode({ "enableNetworkPolicy" = "true" })

  lifecycle {
    ignore_changes = [addon_version]
  }

  depends_on = [aws_eks_node_group.paramify_eks_node_group]
}
