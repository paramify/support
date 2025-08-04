# Deploy with Helm to Azure AKS
> Paramify can be deployed using Helm into an existing Kubernetes cluster, such as AWS EKS, Azure AKS, or self-managed.

![helm](/assets/hero-helm.png)

The following instructions are an example of how to create and deploy into an Azure AKS cluster leveraging Workload Identity (attached to a ServiceAccount) for permissions to read/write from Azure Storage. Other than the specific Terraform the overall process is generally applicable for any Helm-based install of Paramify into Kubernetes.

## Prerequisites
- Azure CLI and authenticated user with sufficient permissions to create resources
- [terraform](https://www.terraform.io/) CLI installed (if using the example .tf files)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/) CLI installed
- A Paramify license (user and credential for Helm registry login)
- (Recommended) An available subdomain planned to access the application (e.g., paramify.company.com)
- (Recommended) Credentials for an SMTP server to send email
- (Recommended) Access to configure Okta, Microsoft Login, or Google Cloud Console for SSO

::: tip NOTE
You'll need to configure at least one authentication method (e.g., SMTP, Google, Microsoft, Okta) to be able to login to Paramify.
:::

## 1. Create Infrastructure
Paramify will use the following infrastructure in Azure:
- AKS Kubernetes cluster
- PostgreSQL database (this example uses an embedded DB container, so refer to [Embedded Postgres Backup](embedded-db-backup) for info on backups. Preferably you could use a managed solution like Azure Database for PostgreSQL, with an example in [Embedded in Azure](deploy-embedded-azure).)
- Azure Storage account and container for images and generated documentation
- Load balancer to access to the Paramify application

To simplify creation of the infrastructure you can use the example [Terraform files](https://github.com/paramify/support/blob/main/azure) to create everything in an isolated resource group.

Follow these steps to create the infrastructure:
1. Update and apply the terraform example (or similar):
    - In an empty directory, save the example files and edit `variables.tf` to set the variables for your environment.

    :::tip
    If an AKS cluster already exists you may be able to skip the `azure-paramify-infra-prereq.tf` file.
    :::
    - Init and check the configuration:
    ```bash
    terraform init
    terraform plan
    ```
    - Apply the configuration to create Azure resources:
    ```bash
    terraform apply
    ```
    :::tip NOTE
    This will usually take a few minutes.
    :::
    - Copy the convenience output values (or run `terraform output`) that look something like:
    ```
    azure_blob_endpoint = "https://paramify-mycompany.blob.core.windows.net/"
    azure_container = "paramify-container"
    azure_storage = "paramify-mycompany"
    client_id = "00000000-0000-0000-0000-000000000000"
    kubernetes_cluster_name = "paramify-aks"
    resource_group_name = "paramify-rg"
    ```
2. Authenticate your `kubectl` config by running the `aks-creds.sh` script


## 2. Helm Install
Follow these steps to install the application using Helm:
1. Edit `values-azure.yaml` and edit the configuration according to your environment, including SMTP and DB credentials.

    :::warning
    Be sure to update ADMIN_EMAIL to match the first user that will login, who can then add other users.
    :::
2. Authenticate to the Paramify Helm registry using your license (which can be obtained from Paramify):
    ```bash
    helm registry login registry.paramify.com --username user@company.com --password <license_id>
    ```
3. Review the Helm templates and then install:
    - If desired, use the `helm template` command to preview the resulting templates that will be applied.
    ```bash
    helm template paramify oci://registry.paramify.com/paramify/paramify --namespace paramify --values ./values-azure.yaml
    ```
    - Then actually install the templates into your cluster:
    ```bash
    helm install paramify oci://registry.paramify.com/paramify/paramify --namespace paramify --values ./values-azure.yaml
    ```
4. If you used the default `LoadBalancer` option you should do the following to identify the IP to connect to:
    ```bash
    kubectl get service paramify -n paramify
    ```
    - The results will look something like:
    ```bash
    NAME                     TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)         AGE
    service/paramify         LoadBalancer   10.0.43.163    10.224.0.6    443:31758/TCP   31s
    ```
    - Copy the `EXTERNAL-IP` and paste that into your browser to https://&lt;EXTERNAL-IP&gt;.

    :::tip
    You can add a custom DNS domain name pointing at that `EXTERNAL-IP` to get a more user friendly endpoint. It's then recommended to generate an associated SSL cert to use. Otherwise you may see an error in the browser about the SSL cert, which you'll have to accept to access the app.
    :::

Now you should be ready to access Paramify at the load balancer IP or optionally your desired domain (e.g., https://paramify.company.com) and login using one of your configured methods. Enjoy!
