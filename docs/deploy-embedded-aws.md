# Deploy an Embedded Cluster to AWS
> Paramify can be deployed in an embedded cluster or "virtual appliance" mode, as an alternative to deploying into an existing Kubernetes cluster.

<YouTube src="https://www.youtube.com/embed/hHPVGQq-zrA?si=caqQ4So4pJo4pvNF" />

The following instructions are an example of how to deploy into AWS.

## Prerequisites
- AWS SSO login with sufficient permissions to create resources
- [Terraform](https://www.terraform.io/) CLI installed
- An available subdomain planned to access the application (e.g., paramify.company.com)
- An AWS key pair to assign to the EC2 instance for SSH
- A Paramify license file
- (Recommended) Credentials for an SMTP server to send email
- (Recommended) Access to configure Okta or Google Cloud Console for SSO

:::tip NOTE
You'll need to configure at least one authentication method (e.g., SMTP, Google, Okta) to be able to login to Paramify.
:::

## 1. Create Infrastructure
Paramify will use the following infrastructure in AWS:
- EC2 instance to run Paramify
- RDS PostgreSQL database
- S3 bucket for generated documentation
- Load balancer to access installer and application

To simplify creation of the infrastructure you can use the example Terraform file [aws-paramify-embedded-infra.tf](https://github.com/paramify/support/blob/main/aws_embed/aws-paramify-embedded-infra.tf) to create everything in an isolated VPC. Be sure to update the variables at the top of the file according to your environment.

Follow these steps to create the infrastructure:
1. Create an AWS SSL certificate for the desired subdomain (e.g., paramify.company.com)
2. Update and apply the terraform example (or similar):
    - In an empty directory, save and edit the example `aws-paramify-embedded-infra.tf` file to set the variables for your environment (including the ARN to the SSL certificate)
    - Init and check the configuration:
    ```bash
    terraform init
    terraform plan
    ```
    - Apply the configuration to create AWS resources:
    ```bash
    terraform apply
    ```
    :::info
    This will usually take a few minutes.
    :::
    - Copy the convenience output values (or run `terraform output`) that look something like:
    ```
    db_dns = "paramify-company-db.abc123abc123.us-west-2.rds.amazonaws.com"
    ec2_id = "i-0123456789example"
    lb_dns = "paramify-company-lb-1234567890.us-west-2.elb.amazonaws.com"
    region = "us-west-2"
    s3_bucket = "paramify-company-s3"
    ```
3. Add an AWS Route 53 DNS record (or equivalent) for the desired domain as an alias to the new LB (lookup the `lb_dns` from terraform output when setting alias target)


## 2. Prepare Installer
Follow these steps to prepare the installer:
1. SSH using [AWS EC2 Instance Connect](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-using-eice.html) to the EC2 instance:
    - For example, using the `ec2_id` from terraform output as the instance ID execute the following:
    ```bash
    ssh -i my-key-pair.pem ec2-user@i-0123456789example \
    -o ProxyCommand='aws ec2-instance-connect open-tunnel --instance-id i-0123456789example'
    ```
2. Update the EC2 instance (then reboot, if applicable):
    ```bash
    sudo yum update -y
    ```
3. Download and prepare the installer:
    ```bash
    curl -sSL https://kurl.sh/paramify | sudo bash
    ```
    :::info
    This step usually takes about 10 minutes. If there are preflight warnings then correct, if needed, and proceed (e.g., you can ignore a UTC timezone warning).
    :::
4. Copy and save the output after “Installation Complete” (specifically the admin password, which is required later)

    :::tip
    You can reset the admin password manually with `kubectl kots reset-password default` if needed.
    :::


## 3. Deploy Paramify
At this point the configuration and deployment will be similar to other Paramify deployment methods.

1. Open the installer URL at the configured subdomain on port 8443 (e.g., https://paramify.company.com:8443)
2. Login using the admin password previously copied from installation output
3. Upload your Paramify License file
4. Enter your Paramify configuration information then continue
    - The "Application Base URL" should match the DNS subdomain you chose (e.g., https://paramify.company.com)
    - For "Database" select "External Postgres"
        - As "Database Host" enter the `db_dns` from terraform output of the created RDS database.
        - Set "User" to "postgres" and "Password" to the DB password you set in the `.tf` file variable.
        - The other settings can be left at default (e.g., port is 5432, database is "postgres").
    - "S3 Bucket" name will be the `s3_bucket` from terraform output of the created bucket
        - "S3 Region" should also match `region` from terraform output
5. Wait for Preflight checks to complete
6. Deploy the application and wait for the "Ready" status

Now you should be ready to access Paramify at the desired domain (e.g., https://paramify.company.com) and login using one of your configured methods. Enjoy!
