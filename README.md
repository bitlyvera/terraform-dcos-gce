# Terraform DC/OS

A fork of [ContainerSolutions' Mesos scripts](https://github.com/ContainerSolutions/terraform-mesos). 
This README and the scripts have been adapted to work with DC/OS instead of plain Mesos.

## How to set up a DC/OS cluster on the Google Cloud using Terraform

### Install Terraform

* This module requires Terraform 0.8.2 or greater
* Follow the instructions on <https://www.terraform.io/intro/getting-started/install.html> to set up Terraform on your machine.

### Get your Google Cloud JSON account_file
Authenticating with Google Cloud services requires a JSON file which we call the account file. This file is downloaded directly from the Google Developers Console. Follow these steps:
- Log into the [Google Developers Console](https://console.developers.google.com/) and select `your google project`.
- The API Manager view should be selected, click on "Credentials" on the left, then "Create credentials", and finally "Service account key".
- Select "Compute Engine default service account" in the "Service account" dropdown, and select "JSON" as the key type.
- Clicking "Create" will download your account_file.

### Get Google Cloud SDK
- Visit https://cloud.google.com/sdk/
- Install the SDK, login and authenticate with your Google Account.

### Add your SSH key to the Project Metadata
- Back in the Developer Console, go to Compute - Compute Engine - Metadata and click the SSH Keys tab. Add your public SSH key there.
- Decrypt your ssh key using `openssl`:
```bash 
openssl rsa -in ~/.ssh/id_rsa -out decrypted.private.key
```
- Use the path to the private key and the username in the next step as `gce_ssh_user` and `gce_ssh_private_key_file`

### Prepare Terraform configuration file

Create a file `dcos.tf` containing something like this:

    module "dcos" {
        source                   = "github.com/bitlyvera/terraform-dcos-gce"
        account_file             = "/path/to/your.key.json"
        project                  = "your google project ID"
        region                   = "europe-west1"
        zone                     = "europe-west1-d"
        gce_ssh_user             = "user"
        gce_ssh_private_key_file = "/path/to/private.key"
        name                     = "mydcoscluster"
        masters                  = "1"
        slaves                   = "2"
        subnetwork               = "10.20.30.0/24"
        domain                   = "example.com"
      # dcos_version             = "1.8"
        image                    = "centos-cloud/centos-7"
        slave_machine_type       = "n1-highmem-2"
        master_machine_type      = "n1-highmem-2"
      # slave_resources          = "cpus(*):0.90; disk(*):7128"
    }

See the `variables.tf` file for the available variables and their defaults

### Get the Terraform module

Download the module

```
terraform get -update
```

### Create Terraform plan

Create the plan and save it to a file. Use module-depth 1 to show the configuration of the resources inside the module.

```
terraform plan -out my.plan -module-depth=1
```

### Create the cluster

Once you are satisfied with the plan, apply it.

```
terraform apply my.plan
```

### VPN configuration

Use the following commands to download `client.ovpn` file. Then use it to establish VPN with the cluster.

```
OVPNFILE=`terraform output -module dcos openvpn`
scp -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $OVPNFILE .
sudo openvpn --config client.ovpn
```

### Use the DC/OS CLI on the bootstrap node
Once the VPN is up, you can access the DC/OS cli on the bootstrap node.

First, ssh into the bootstrap node:
```
ssh -o StrictHostKeyChecking=no `terraform output -module dcos bootstrap`
```
Now you can e.g. install the spark package...
```
dcos package install spark 
```
... and run an example job computing Pi:
```
dcos spark run --submit-args='-Dspark.mesos.coarse=true --driver-cores 1 --driver-memory 1024M --class org.apache.spark.examples.SparkPi https://downloads.mesosphere.com/spark/assets/spark-examples_2.10-1.4.0-SNAPSHOT.jar 2'
```

### View the DC/OS UI 
While the VPN is connected, you can access the DC/OS ui on the master node:
```
open http://`terraform output -module dcos master`
````

### Destroy the cluster
When you're done, clean up the cluster with
```
terraform destroy
```

## To do

- Cannot reach the log files of the Mesos slave nodes from the web interface on the leading master

The installation and configuration used in this module is based on this excellent howto: <https://www.digitalocean.com/community/tutorials/how-to-configure-a-production-ready-mesosphere-cluster-on-ubuntu-14-04>
