# Deploy with Helm to AWS EKS
> Paramify can be deployed using Helm into an existing Kubernetes cluster, such as AWS EKS, Azure AKS, or self-managed.

![helm](/assets/hero-helm.png)

The following instructions are an example of how to create and deploy into an AWS EKS cluster leveraging an IAM role (attached to a ServiceAccount) for permissions to read/write from S3 Storage. Other than the specific Terraform the overall process is generally applicable for any Helm-based install of Paramify into Kubernetes.

## Prerequisites
- AWS CLI and authenticated user with sufficient permissions to create resources
- [terraform](https://www.terraform.io/) CLI installed (if using the example .tf files)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/) CLI installed
- A Paramify license (user and credential for Helm registry login)
- (Recommended) An available subdomain planned to access the application (e.g., paramify.mycompany.com)
- (Recommended) Credentials for an SMTP server to send email
- (Recommended) Access to configure Okta, Microsoft Login, or Google Cloud Console for SSO

::: tip NOTE
You'll need to configure at least one authentication method (e.g., SMTP, Google, Microsoft, Okta) to be able to login to Paramify.
:::

## 1. Create Infrastructure
Paramify will use the following infrastructure in AWS:
- EKS Kubernetes cluster
- RDS PostgreSQL database
- S3 bucket for generated documentation
- Load balancer to access installer and application

To simplify creation of the infrastructure you can use the example Terraform file [aws-paramify-eks-infra.tf](https://github.com/paramify/support/blob/main/aws/aws-paramify-eks-infra.tf) to create everything in an isolated VPC. Be sure to update the variables at the top of the file according to your environment.

Follow these steps to create the infrastructure:
1. (Recommended) Create an AWS SSL certificate for the desired subdomain (e.g., paramify.mycompany.com)
2. Update and apply the terraform example (or similar):
    - In an empty directory, save and edit the example `aws-paramify-eks-infra.tf` file to set the variables for your environment (including the ARN to the SSL certificate)
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
    cluster_name = "paramify-mycompany-eks"
    db_dns = "paramify-mycompany-db.abc123abc123.us-west-2.rds.amazonaws.com"
    region = "us-west-2"
    s3_bucket = "paramify-mycompany-s3"
    s3_role = "arn:aws:iam::abc123abc123:role/paramify-mycompany-eks-sa-role"
    ```
3. Add the EKS cluster config to kubectl (using the `cluster_name` from the Terraform output above), including `--profile <sso_profile>` if not using `default`
    ```
    aws eks update-kubeconfig --region us-west-2 --name paramify-mycompany-eks --profile admin
    ```

## 2. Helm Install
Follow these steps to install the application using Helm:
1. Edit [values-eks.yaml](https://github.com/paramify/support/blob/main/aws/values-eks.yaml.example) and edit the configuration according to your environment, including SMTP and DB credentials.

    :::warning
    Be sure to update ADMIN_EMAIL to match the first user that will login, who can then add other users.
    :::
2. Authenticate to the Paramify Helm registry using your license (which can be obtained from Paramify):
    ```bash
    helm registry login registry.paramify.com --username paramify@mycompany.com --password <license_id>
    ```
3. Review the Helm templates and then install:
    - If desired, use the `helm template` command to preview the resulting templates that will be applied.
    ```bash
    helm template paramify oci://registry.paramify.com/paramify/paramify --namespace paramify --values ./values-eks.yaml
    ```
    - Then actually install the templates into your cluster:
    ```bash
    helm install paramify oci://registry.paramify.com/paramify/paramify --namespace paramify --values ./values-eks.yaml
    ```
4. If you used the default `LoadBalancer` option you should do the following to identify the endpoint to connect to:
    ```bash
    kubectl get service paramify -n paramify
    ```
    - The results will look something like:
    ```bash
    NAME             TYPE           CLUSTER-IP   EXTERNAL-IP                                                 PORT(S)         AGE
    paramify         LoadBalancer   172.20.1.2   abc123abc1234567890-012345678.us-west-2.elb.amazonaws.com   443:30835/TCP   3m
    ```
5. (Recommended) Add an AWS Route 53 DNS record (or equivalent) for the desired subdomain as a CNAME alias to the new LB endpoint in `EXTERNAL-IP` above

    :::tip
    It's recommended to generate an associated SSL cert for the custom subdomain to use. Otherwise you may see an error in the browser about the SSL cert, which you'll have to accept to access the app.
    :::

Now you should be ready to access Paramify at the load balancer endpoint or optionally your desired custom subdomain (e.g., https://paramify.mycompany.com) and login using one of your configured methods. Enjoy!
