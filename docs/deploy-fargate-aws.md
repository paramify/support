# Deploy to Fargate (ECS) in AWS
> Paramify can be deployed using Fargate in an Elastic Container Service (ECS) cluster in AWS

The following instructions are an example of how to deploy the infrastructure and application into Fargate in AWS ECS.

:::warn
This deployment model is being evaluated for future official support.
:::

## Prerequisites
- AWS CLI and SSO login with sufficient permissions to create resources
- [Terraform](https://www.terraform.io/) CLI installed
- An available subdomain planned to access the application (e.g., paramify.mycompany.com)
- A Paramify license file
- (Optional) [Helm](https://helm.sh/docs/intro/install/) CLI installed
- (Recommended) Credentials for an SMTP server to send email
- (Recommended) Access to configure Google Cloud Console, Microsoft Account Login, or Okta for SSO

:::tip NOTE
You'll need to configure at least one authentication method (e.g., SMTP, Google, MS, Okta) to be able to login to Paramify.
:::


## 1. Get the latest Container Image URLs using Helm
The easiest way to get the latest image URLs is temporarily pulling the templates using Helm. Alternatively you can contact Paramify support.
Follow these steps to download and get the image URLs:
1. Authenticate to the Paramify Helm registry using your license (which can be obtained from Paramify):
    ```bash
    helm registry login registry.paramify.com --username paramify@company.com --password <license_id>
    ```
2. Get the container image URLs from the Helm template:
    - Use the `helm template` command to download the templates that would be applied
    ```bash
    helm template paramify oci://registry.paramify.com/paramify/paramify > paramify.yaml
    ```
    - Then find the relevant container image URLs (using `grep` or a text editor):
    ```bash
    $ grep "image.*proxy" paramify.yaml
          image: "proxy.paramify.com/proxy/paramify/012345012345.dkr.ecr.us-west-2.amazonaws.com/document-robot:abc1234@sha256:abcdefg1234567890..."
          image: "proxy.paramify.com/proxy/paramify/012345012345.dkr.ecr.us-west-2.amazonaws.com/paramify:abc1234@sha256:abcdefg1234567890..."
    ```
    Notice the `proxy.paramify.com` lines for `paramify` and `document-robot` to copy into your `variables-fargate.tf` file.
    Optionally you could `docker pull` the images (using your license as user and password) then retag and push them to your own ECR, in which case you'd want to use your resulting URLs in the variables.


## 2. Create Infrastructure and Deploy Paramify
Paramify will use the following infrastructure in AWS:
- ECS cluster in a new VPC with service via Fargate
- RDS PostgreSQL database
- S3 bucket for generated documentation

To simplify creation of the infrastructure you can use the example Terraform file [aws-paramify-ecs-fargate.tf](https://github.com/paramify/support/blob/main/aws-paramify-ecs-fargate.tf) to create everything in an isolated VPC. Be sure to update the [variables-fargate.tf](https://github.com/paramify/support/blob/main/variables-fargate.tf) according to your environment.

Follow these steps to create the infrastructure and deploy the application:
1. Create an AWS SSL certificate for the desired subdomain (e.g., paramify.mycompany.com) in ACM
2. Update and apply the terraform example (or similar):
    - In an empty directory, save and edit the example `variables-fargate.tf` file to set the variables for your environment (including your SSL cert and license)
    - Init and review the planned changes:
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
    lb_dns = "paramify-fargate-lb-123456890.us-west-2.elb.amazonaws.com"
    region = "us-west-2"
    s3_bucket = "paramify-mycompany-s3"
    ```
3. (Recommended) Lookup the loadbalancer URL created for your service and create a DNS entry pointing to it
    - Use `terraform output` to get the hostname of the ECS-created load balancer (see `lb_dns` in example above)
    - If using AWS Route 53 for DNS you can create as follows:
        - In your domain create your DNS entry (e.g., paramify.mycompany.com) matching the SSL cert assigned to the loadbalancer
        - For "Record type" use "A" record then select "Alias"
        - Under "Route traffic to" choose "Alias to Application and Classic Load Balancer", your region, then select the entry for the LB hostname that was created

    :::tip
    The desired LB entry may start with "dualstack", such as "dualstack.abcdef0123456789abcdef1234567890-1234567890.us-west-2.elb.amazonaws.com."
    :::

Now you should be ready to access Paramify at the desired domain (e.g., https://paramify.mycompany.com) and login using one of your configured methods. Enjoy!
