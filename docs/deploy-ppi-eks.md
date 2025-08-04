# Deploy to an EKS Cluster in AWS
> Paramify can be deployed into an Elastic Kubernetes Service (EKS) cluster in AWS.

The following instructions are an example of how to deploy the infrastructure and application into AWS EKS.


## Prerequisites
- AWS CLI and SSO login with sufficient permissions to create resources
- [Terraform](https://www.terraform.io/) CLI installed
- [kubectl](https://kubernetes.io/docs/reference/kubectl/) CLI installed
- An available subdomain planned to access the application (e.g., paramify.mycompany.com)
- A Paramify license file
- (Recommended) Credentials for an SMTP server to send email
- (Recommended) Access to configure Google Cloud Console, Microsoft Account Login, or Okta for SSO

:::tip NOTE
You'll need to configure at least one authentication method (e.g., SMTP, Google, MS, Okta) to be able to login to Paramify.
:::


## 1. Create Infrastructure
Paramify will use the following infrastructure in AWS:
- EKS cluster in a new VPC
- RDS PostgreSQL database
- S3 bucket for generated documentation

To simplify creation of the infrastructure you can use the example Terraform file [aws-paramify-eks-infra.tf](https://github.com/paramify/support/blob/main/aws/aws-paramify-eks-infra.tf) to create everything in an isolated VPC. Be sure to update the variables at the top of the file according to your environment.

Follow these steps to create the infrastructure:
1. Create an AWS SSL certificate for the desired subdomain (e.g., paramify.mycompany.com) in ACM
2. Update and apply the terraform example (or similar):
    - In an empty directory, save and edit the example `aws-paramify-eks-infra.tf` file to set the variables for your environment
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
    db_dns = "paramify-mycompany-db.abcdef123456.us-west-2.rds.amazonaws.com"
    region = "us-west-2"
    s3_bucket = "paramify-mycompany-s3"
    s3_role = "arn:aws:iam::012345678901:role/paramify-mycompany-eks-sa-role"
    ```


## 2. Prepare Installer
Follow these steps to prepare the Admin Console installer:
1. Connect `kubectl` to your new EKS cluster, replacing your values similar to the following:
    ```bash
    aws eks update-kubeconfig --region us-west-2 --name paramify-mycompany-eks --profile=admin
    kubectl get ns
    ```
    The second command should confirm ability to communicate with your cluster if it returns entries like `default`, `kube-system`, etc.

    :::tip
    The parameter `--profile=admin` refers to your desired AWS SSO profile. If your default profile has sufficient permissions this may be optional.
    :::
2. Add the KOTS plugin to kubectl:
    ```bash
    curl https://kots.io/install | sudo bash
    ```
3. Startup the installer in the EKS cluster:
    ```bash
    kubectl kots install paramify
    ```
    After choosing your desired namespace (i.e., paramify) it should prompt for a password to set on the installer.
    The Admin Console will then be installed and pause with the following message:
    ```
    • Press Ctrl+C to exit
    • Go to http://localhost:8800 to access the Admin Console
    ```


## 3. Deploy Paramify
At this point the configuration and deployment will be similar to other Paramify deployment methods.

1. Open the installer URL at the local URL (e.g., http://localhost:8800)
2. Login using the admin password previously set while preparing the installer
3. Upload your Paramify License file
4. Enter your Paramify configuration information then continue
    - The "Application Base URL" should match the DNS subdomain you chose (e.g., https://paramify.company.com)
    - For "Ingress Setting" choose "Load Balancer" and enter the following:
        - Under "Load Balancer Annotations" enter:
        ```yaml
        service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:us-west-2:<account_id>:certificate/<cert_id>  # replace with your SSL cert
        service.beta.kubernetes.io/aws-load-balancer-ssl-ports: http
        service.beta.kubernetes.io/aws-load-balancer-backend-protocol: https
        service.beta.kubernetes.io/load-balancer-source-ranges: "1.2.3.4/32,0.0.0.0/0"  # replace with your IP addresses, or remove for public access
        ```
    - For "Database" select "External Postgres"
        - As "Database Host" enter the `db_dns` from terraform output of the created RDS database.
        - Set "User" to "postgres" and "Password" to the DB password you set in the `.tf` file variable.
        - The other settings can be left at default (e.g., port is 5432, database is "postgres").
    - Under "Cloud Storage Settings"
        - "S3 Bucket" name will be the `s3_bucket` from terraform output of the created bucket
        - "S3 Region" should also match `region` from terraform output
        - "S3 Annotations" would be similar to the following with your `s3_role` from terraform output:
        ```yaml
        eks.amazonaws.com/role-arn: arn:aws:iam::<account_id>:role/paramify-mycompany-eks-sa-role
        ```
    - (Recommended) Click the box for "Enable Admission Webhook"
        - Lookup the container registry AWS is using for their EKS add-ons in your region from [here](https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html).
        - Enter the domain into "Additional Allowed Registries and Images" from the lookup, similar to the following:
        ```yaml
        602401143452.dkr.ecr.us-west-2.amazonaws.com
        ```
5. Click "Continue" and wait for Preflight checks to complete
6. Deploy the application and wait for the "Ready" status
7. (Optional) Lookup the loadbalancer URL created for your service and create a DNS entry pointing to it
    - Use `kubectl` to get the hostname of the EKS-created load balancer (see the "EXTERNAL_IP" column):
    ```bash
    $ kubectl get svc -n paramify paramify

    NAME       TYPE           CLUSTER-IP   EXTERNAL-IP                                                               PORT(S)         AGE
    paramify   LoadBalancer   172.20.0.1   abcdef0123456789abcdef1234567890-1234567890.us-west-2.elb.amazonaws.com   443:32101/TCP   3m18s
    ```
    - If using AWS Route 53 for DNS you can create as follows:
        - In your domain create your DNS entry (e.g., paramify.mycompany.com)
        - For "Record type" use "A" record then select "Alias"
        - Under "Route traffic to" choose "Alias to Application and Classic Load Balancer", your region, then select the entry for the LB hostname that was created

    :::tip
    The desired LB entry may start with "dualstack", such as "dualstack.abcdef0123456789abcdef1234567890-1234567890.us-west-2.elb.amazonaws.com."
    :::

Now you should be ready to access Paramify at the desired domain (e.g., https://paramify.mycompany.com) and login using one of your configured methods. Enjoy!


## 4. (Optional) Harden the Cluster
Once the cluster is running you can use the following steps to further harden the cluster for CIS/STIG requirements:
1. Set network policies by downloading and applying the [networkpolicies.yaml](https://github.com/paramify/support/blob/main/networkpolicies.yaml):
```bash
# modify this file if the application namespace is not "paramify" or DB port is not 5432
kubectl apply -f networkpolicies.yaml
```
2. Disable the default service account token auto-mount (replace "paramify" if it is not the app namespace)
```bash
for NS in default paramify kube-system kube-public kube-node-lease; do
kubectl patch serviceaccount default -p '{"automountServiceAccountToken": false}' -n $NS
done
```
3. Restrict pod security contexts (replace "paramify" if it is not the app namespace)
```bash
kubectl label --overwrite ns kube-system pod-security.kubernetes.io/enforce=privileged
kubectl label --overwrite ns kube-node-lease pod-security.kubernetes.io/enforce=baseline
kubectl label --overwrite ns kube-public pod-security.kubernetes.io/enforce=baseline
kubectl label --overwrite ns paramify pod-security.kubernetes.io/enforce=baseline
kubectl label --overwrite ns default pod-security.kubernetes.io/enforce=restricted
```
