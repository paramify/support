# If your cluster is in the AWS GovCloud (US-East) or AWS GovCloud (US-West)
# AWS Regions, then replace arn:aws: with arn:aws-us-gov:.

###########################################################################
## VARIABLES
###########################################################################

variable "paramify_license" {
  description = "Your company's Paramify license key."
  default     = "ABC...123"
}

variable "region" {
  description = "The AWS region to create resources in."
  default     = "us-west-2"
}

variable "sso_profile" {
  description = "The AWS SSO profile to use for create access."
  default     = "admin"
}

variable "allowed_ips" {
  description = "Company egress IPs that should be allowed to access app."
  default     = ["192.168.0.1/32"]
}

variable "db_name" {
  description = "RDS database name used by Paramify."
  default     = "paramify"
}

variable "db_user" {
  description = "RDS database user used by Paramify."
  default     = "paramify"
}

variable "db_password" {
  description = "RDS database password used by Paramify."
  default     = "super_secret"
}

variable "db_port" {
  description = "RDS database port used by Paramify."
  default     = "5432"
}

variable "aws_prefix" {
  description = "Prefix for naming the created AWS resources."
  default     = "paramify-fargate"
}

variable "ssl_cert" {
  description = "SSL cert to use on Paramify loadbalancer."
  default     = "arn:aws:acm:<region>:<account>:certificate/<cert-guid>"
}

variable "paramify_image" {
  description = "Container image to use for the Paramify application."
  # default     = "proxy.paramify.com/proxy/paramify/041462616641.dkr.ecr.us-west-2.amazonaws.com/paramify:..."
  default     = "041462616641.dkr.ecr.us-west-2.amazonaws.com/paramify:41ae0be@sha256:86212d976ba5b1f5beb6ec1e09f4f64426af0dfa96ead3ab0dc62c57b5023c20"
}

variable "docrobot_image" {
  description = "Container image to use for the Document Robot."
  # default     = "proxy.paramify.com/proxy/paramify/041462616641.dkr.ecr.us-west-2.amazonaws.com/document-robot:..."
  default     = "041462616641.dkr.ecr.us-west-2.amazonaws.com/document-robot:68596c7@sha256:ba4917c962c75f1cf6d45add8c78eef83aaab5ba1355b16b412c2948079a17a4"
}

variable "cloudwatch_group" {
  description = "Cloudwatch log group to use for logging."
  default     = "paramify-fargate-logs"
}

variable "admin_email" {
  description = "Email address of initial Admin user to create in Paramify."
  default     = "user@company.com"
}

variable "app_base_url" {
  description = "Base URL for the Paramify app."
  default     = "https://paramify.company.com"
}

variable "smtp_host" {
  description = "SMTP host to use for sending email."
  default     = "smtp-relay.gmail.com"
}

variable "smtp_port" {
  description = "SMTP port to use for sending email."
  default     = "465"
}

variable "smtp_user" {
  description = "SMTP user to use for sending email."
  default     = "smtpuser@company.com"
}

variable "smtp_password" {
  description = "SMTP password to use for sending email."
  default     = "smtp_secret"
}

variable "smtp_from" {
  description = "SMTP from address to use for sending email."
  default     = "Paramify <noreply@company.com>"
}

variable "magic_link_secret" {
  description = "Secret used to sign emailed magic links."
  default     = "super_secret_l1nk"
}

variable "session_secret" {
  description = "Secret used to sign user sessions."
  default     = "Super_s3cr3t"
}

variable "auth_google_enabled" {
  description = "Flag to enable Google SSO."
  default     = "false"
}

variable "auth_google_client_id" {
  description = "Client ID used for Google SSO."
  default     = "12345678-abc123.apps.googleusercontent.com"
}

variable "auth_google_client_secret" {
  description = "Client Secret used for Google SSO."
  default     = "Gsomething_something"
}


###########################################################################
## AWS PROVIDER
###########################################################################

provider "aws" {
  region  = var.region
  profile = var.sso_profile
}


###########################################################################
## OUTPUT
###########################################################################

output "region" {
  description = "Region for created resources"
  value       = var.region
}

output "s3_bucket" {
  description = "S3 bucket created to store images and documents"
  value       = aws_s3_bucket.paramify_ecs_s3.bucket
}

output "lb_dns" {
  description = "DNS for the load balancer"
  value       = aws_lb.paramify_ecs_lb.dns_name
}
