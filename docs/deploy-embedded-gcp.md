# Deploy an Embedded Cluster to Google Cloud (Beta)
> Paramify can be deployed in an embedded cluster, as an alternative to deploying into an existing Kubernetes cluster.

The following instructions are an example of how to deploy to a single node embedded cluster in Google Cloud using services for database and storage.

:::tip NOTE
These instructions rely on a Beta version of the embedded cluster, so details may change.
:::

## Prerequisites
- Google Cloud CLI (gcloud) and authenticated user with sufficient permissions to create resources
- [terraform](https://www.terraform.io/) CLI installed (if using the example .tf files)
- Your Paramify license ID
- (Recommended) An available subdomain planned to access the application (e.g., paramify.mycompany.com)
- (Recommended) Credentials for an SMTP server to send email
- (Recommended) Access to configure Okta, Microsoft Login, or Google Cloud Console for SSO

:::tip NOTE
You'll need to configure at least one authentication method (e.g., SMTP, Google, Okta) to be able to login to Paramify.
:::


## 1. Create Infrastructure
Paramify will use the following infrastructure in Google Cloud:
- VM instance to run Paramify
- Cloud SQL for PostgreSQL
- Cloud Storage bucket for images and generated documentation
- Load balancer to access Admin Console and application

To simplify creation of the infrastructure you can use the [example Terraform files](https://github.com/paramify/support/blob/main/gcp_embed) to create everything in an isolated VPC in an existing Google Project.

Follow these steps to create the infrastructure:
1. (Recommended) Acquire an SSL certificate for the desired subdomain (e.g., paramify.mycompany.com)
2. Select a Project ID to use (or create a new Project in the [Google Cloud console](https://console.cloud.google.com))
3. Authenticate the `gcloud` CLI, select the desired Project (replacing `mycompany-paramify-project-id` with your project ID), then enable required APIs:
    ```bash
    gcloud auth application-default login
    gcloud config set project mycompany-paramify-project-id
    gcloud services enable servicenetworking.googleapis.com compute.googleapis.com iamcredentials.googleapis.com networkservices.googleapis.com
    ```
4. Update and apply the terraform example (or similar):
    - In an empty directory, save and edit the example `.tf` files (and `startup.sh`), then update the variables (at the top of the `.tf` file) for your environment
    - Init and check the configuration:
    ```bash
    terraform init
    terraform plan
    ```
    - Apply the configuration to create Google Cloud resources:
    ```bash
    terraform apply
    ```
    :::info
    This will usually take several minutes.
    :::
    - Copy the convenience output values (or run `terraform output`) that look something like:
    ```
    db_ip = "10.1.2.3"
    google_bucket = "paramify-mycompany-bucket"
    iam_sa = "paramify-mycompany-sa@mycompany-paramify-project-id.iam.gserviceaccount.com"
    lb_ip = "34.1.2.3"
    vm_id = "paramify-mycompany-app"
    ```
5. (Recommended) Add a DNS record for the desired domain as an alias to the new LB IP (lookup the `lb_ip` from terraform output when setting alias target)


## 2. Prepare Admin Console
The included `startup.sh` script with the example Terraform files should automatically provision the Admin Console on the VM. It will try to download and extract the installer to `/opt/paramify/paramify`, then run the installer and log output to `/tmp/paramify.log`.

However, if you would rather install it manually then follow these steps (replacing `example-key` with a valid SSH private key):
1. SSH into the VM:
    - For example, using the `vm_id` from terraform output execute the following:
    ```bash
    gcloud compute ssh --tunnel-through-iap --ssh-key-file ~/.ssh/example-key `terraform output -raw vm_id`
    ```
2. Update the VM instance (then reboot, if applicable):
    ```bash
    sudo apt update && sudo apt upgrade -y
    ```
3. Download and install the Admin Console (replacing `paramify_license_id` with your License ID):
    ```bash
    curl -f https://replicated.app/embedded/paramify -H "Authorization: paramify_license_id" -o /tmp/paramify.tgz
    sudo mkdir /opt/paramify
    sudo tar -xvzf /tmp/paramify.tgz -C /opt/paramify
    sudo /opt/paramify/paramify install --license /opt/paramify/license.yaml
    ```
    :::info
    This step usually takes about 5 minutes. If there are preflight warnings then correct, if needed, and proceed.
    :::

    - Note that you can access a shell with `kubectl` for troubleshooting on the VM with the following:
    ```bash
    sudo /opt/paramify/paramify shell
    ```

    :::tip
    You can change the password from within the Admin Console by clicking the circle with three dots in the top right and choosing "Change password".
    :::


## 3. Deploy Paramify
At this point the configuration and deployment will be similar to other Paramify deployment methods.

1. Open the installer URL at the configured subdomain on port 8443 (e.g., https://paramify.mycompany.com:8443)
    - Alternatively you can use the `lb_ip` directly if DNS is not ready (e.g., https://34.1.2.3:8443)
2. Login using the password from the Admin Console install (default is "password", which you should change)
3. Enter your Paramify configuration information then "Save config" to continue
    - The "Application Base URL" should match the DNS subdomain you chose (e.g., https://paramify.mycompany.com)
    - (Optional) Set the custom SSL cert under "Ingress Settings"
        - Select "User Provided" and choose the appropriate .key and .crt files

    :::info
    This cert is used for SSL in the container, which is normally a self-signed cert. If your load balancer is terminating SSL then you should specify that cert in the `.tf` file instead.
    :::

    - For "Database" select "External Postgres"
        - As "Database Host" enter the `db_ip` from terraform output of the created database
        - Set "Username" and "Database" to "paramify", and "Password" to the DB password you set in the `.tf` file
        - The other settings can be left at default (e.g., port is 5432)
    - Under "Cloud Storage Settings" select "Google Cloud Storage", then from terraform output set the following:
        - "Google Storage Bucket" to the value of `google_bucket`
4. Wait for Preflight checks to complete
5. Deploy the application and wait for the "Ready" status

Now you should be ready to access Paramify at the desired domain (e.g., https://paramify.mycompany.com) or directly (https://34.1.2.3 using `lb_ip` from terraform output) and login using one of your configured methods. Enjoy!
