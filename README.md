# SyncFlow Local Deployment

This repository contains the deployment files for hosting the SyncFlow platform in a Local network setup. This will be useful in situations where we don't have the privilage to host the platform in a cloud environment and access the platform from the Internet. The server used in this example was linux mint, with the cloud VM being an Ubuntu 24.04 instance.

## System Components
The SyncFlow platform consists of the following components:

- SyncFlow Dashboard: The web interface for the platform
- SyncFlow API Server: The backend server for the platform
- SyncFlow LiveKit Server: The server for handling multimedia streams for the platform
- SyncFlow LiveKit Turn Server: The server for handling multimedia streams for the platform
- SyncFlow RabbitMQ Server: The server for handling the message queues for the platform
- SyncFlow PostGreSQL Server: The database server for the platform
- SyncFlow PGAdmin Server: The web interface for the database server
- SyncFlow MinIO Server: The server for archiving the multimedia files for the platform
- SyncFlow Text Egress Actor: The service for handling the text egress for the platform
- The services for the learning environment which integrates with the platform

## Prerequisites
Docker, Docker Compose and a domain name for the platform. Access to a cloud VM for getting the SSL certificates. A local network router with the ability to modify the DNS settings.

## Overview of the Deployment Process
This is a multistage deployment process. Typically, the deployment process also involves adding an extra learning environment client to SyncFlow. In the past we have used `EcoJourneys` as the learning environment client.

The process begins with getting trusted SSL certificates for all the domains that are involved in the deployment. When dealing with multimedia streams from the browser, it is important to have a valid SSL certificate. This is because the browser will not allow access to the camera and microphone without a valid SSL certificate. While, a local self-signed certificate can be used for certain situations, this can't be used for SyncFlow as it depends on [`LiveKit`](https://livekit.io/) for the multimedia streams. LiveKit requires a valid SSL certificate for the domain and turn server.

So, for the local deployment, we need to get valid SSL certificates for the following services:

- SyncFlow Dashboard
- SyncFlow API Server
- LiveKit Server
- LiveKit Turn Server
- SyncFlow RabbitMQ Server
- SyncFlow PostGreSQL Server
- SyncFlow PGAdmin Server
- MinIO Server

The idea is simple. First, we obtain the certificates for these domains (we will be using subdomains of `syncflow.live` in this case) using `certbot` and `nginx` from a cloud VM. Copy the certificates to the local machine and use the certificates to host the services in the local network. This will be done by setting up a local DNS server using `dnsmasq` and modying the network router configuration use the local DNS server, as shown in the figure below.

![LocalDeoploymetnProcess](./images/SyncFlowLocalDeployment.png)


Here we outline the process which we followed to deploy the SyncFlow platform in a local network setup. This process was used for deploying the SyncFlow platform in multiple classroom studies, where connection to the Internet was not possible. 

## Stop 1: Getting SSL Certificates
The first step was to get the SSL certificates for the domains. We used route 53 for managing the DNS records, creating A records for the domains and used `certbot` to get the SSL certificates in a cloud VM, hosted in the IU Jetstream cloud. Since there are multiple platform components for SyncFlow, we provide a breif overview of them and the domains used for each of them. The primary domain used for the SyncFlow platform in `syncflow.live`. For the local demployment, we suffixed the domain and subdomains with `-local` to differentiate them from the production domains. The following are the domains used for the SyncFlow platform:

- SyncFlow Dashboard: `local.syncflow.live`
- SyncFlow API Server: `api-local.syncflow.live`
- SyncFlow LiveKit Server: `livekit-local.syncflow.live`
- SyncFlow LiveKit Turn Server: `turn-local.syncflow.live`
- SyncFlow RabbitMQ Server: `rabbitmq-local.syncflow.live`
- SyncFlow PostGreSQL Server: `postgres-local.syncflow.live`
- SyncFlow PGAdmin Server: `pgadmin-local.syncflow.live`
- SyncFlow MinIO Server: `minio-local.syncflow.live`
- SyncFlow Sharer: `sharer-local.syncflow.live`

If you need instructions on how to get SSL certificates using `certbot`, please refer to the following link: [Getting SSL Certificates using Certbot and Nginx](https://certbot.eff.org/instructions?ws=nginx&os=pip).

Now, after a successful process of generating certficates, we got the following certificates:


```bash
/# cd /etc/letsencrypt
/etc/letsencrypt# tree -L 1 live/
live/
├── README
├── api-local.syncflow.live
├── livekit-local.syncflow.live
├── local.syncflow.live
├── minio-local.syncflow.live
├── pgadmin-local.syncflow.live
├── postgres-local.syncflow.live
├── rabbitmq-local.syncflow.live
├── rabbitmq-mgmt-local.syncflow.live
├── sharer-local.syncflow.live
└── turn-local.syncflow.live

11 directories, 1 file
```
In the next step, we copy the entire `/etc/letsencrypt` directory to the local machine where we will be hosting the SyncFlow platform. Keep in mind that the certificates are valid for 90 days. So, you need to renew the certificates before they expire and copy the renewed certificates to the local machine.

```bash
scp -r user@cloud-vm:/etc/letsencrypt ./letsencrypt
```

## Step 2: Installing and Veryfying Livekit Deployment

After we have the SSL certificates, we can start deploying the SyncFlow platform. We start by deploying the LiveKit server, which provides us with the necessary files and a caddy server which can be used to host all our services. Use the following command to deploy [LiveKit](https://livekit.io/):

```bash
docker pull livekit/generate
docker run --rm -it -v$PWD:/output livekit/generate
```

```{sh}
docker run --rm -it -v$PWD:/output livekit/generate
Generating config for production LiveKit deployment
This deployment will utilize docker-compose and Caddy. It'll set up a secure LiveKit installation with built-in TURN/TLS
SSL Certificates for HTTPS and TURN/TLS will be generated automatically via LetsEncrypt or ZeroSSL.

✔ with Egress
Primary domain name (i.e. livekit.myhost.com): livekit-local.syncflow.live
TURN domain name (i.e. livekit-turn.myhost.com): turn-local.syncflow.live
✔ Let's Encrypt (no account required)
✔ latest
✔ no - (we'll bundle Redis)
✔ Startup Shell Script
Your production config files are generated in directory: livekit-local.syncflow.live

Please point update DNS for the following domains to the IP address of your server.
 * livekit-local.syncflow.live
 * turn-local.syncflow.live
Once started, Caddy will automatically acquire TLS certificates for the domains.

The file "init_script.sh" is a script that can be used in the "user-data" field when starting a new VM.

Since you've enabled Egress/Ingress, we recommend running it on a machine with at least 4 cores

Please ensure the following ports are accessible on the server
 * 443 - primary HTTPS and TURN/TLS
 * 80 - for TLS issuance
 * 7881 - for WebRTC over TCP
 * 3478/UDP - for TURN/UDP
 * 50000-60000/UDP - for WebRTC over UDP

Server URL: wss://livekit-local.syncflow.live
API Key: THE DEPLOYMENT API KEY
API Secret: THE DEPLOYMENT API SECRET

Here's a test token generated with your keys: TEST_TOKEN_HIDDEN

An access token identifies the participant as well as the room it's connecting to
```

Follow the instructions and you will get the necessary API keys and credentials to deploy the LiveKit server. Make sure to use the `startup_script` option instead of the `cloud_init` option. This will give you the necessary files to deploy the LiveKit server. Also choose a LiveKit deployment with Egress. Host name should be the domain name for the LiveKit server. In our case, it is `livekit-local.syncflow.live` and turn server domain should be `turn-local.syncflow.live`. Use the letsencrypt as an option for the SSL certificate. We will modify the caddy config later on, but for now, we will use the default caddy config. This will create the following file structure:

```bash
livekit-local.syncflow.live/
├── caddy.yaml
├── docker-compose.yaml
├── egress.yaml
├── init_script.sh
├── livekit.yaml
└── redis.conf
```

This will be our base for deploying everything. We now need to install livekit with the following command:

```bash
$ sudo su
/path-to-repo# cd livekit-local.syncflow.live
/path-to-repo/livekit-local.syncflow.live# chmod +x init_script.sh
/path-to-repo/livekit-local.syncflow.live# ./init_script.sh
``` 

This creates a directory in /opt/livekit, which contains the necessary files for deployment with the livekit server. This also registers a service named livekit, which can be started using the following command:

```bash
$ sudo systemctl start livekit
```
> [!WARNING]
> You shouldn't use the API Keys and Secrets in the `livekit.yaml` file in this repository. Instead, use the API Keys and Secrets from the output of the `generate` command. The `livekit.yaml` file is used for the deployment of the LiveKit server.

### Verifying the LiveKit Deployment
Once you have started LiveKit, you can verify the deployment by visiting the LiveKit `meet` page. This page is used to test the LiveKit server. You can access the page by visiting the following URL: https://meet.livekit.io. Use the following server url in the custom tab: `wss://localhost:7880` and the token you got in the output of the docker generate command. Upon success, you should be able to stream your camera and microphone to the local LiveKit server.

## Step 3: Deploying the SyncFlow platform
The next step is to deploy the SyncFlow platform. For that let's start by cloning the SyncFlow repository:

```bash
$ git clone git@github.com:oele-isis-vanderbilt/SyncFlow.git
```
Now that we have the repository. We can start by deploying the SyncFlow platform. Numerous variables need to be setup for the deployment. There's a handy [json](./deployment-config-template.json) file included here, which has the details of all the configuration settings that can be used to generate the environment files for each component. After we are done with the configuration, we can modify one of the docker compose files inside the `docker` directory to start the deployment process. Here's what a modified docker

```bash
$ cd SyncFlow
$ touch docker/docker-compose.local.yaml
```

```{yaml}
services:
  postgres-syncflow-local:
    image: postgres:14-alpine
    container_name: postgres-syncflow-local
    ports:
      - "15435:5432" # Publicly, the database is available in port 15435
    volumes:
      - postgres-data-local:/var/lib/postgresql/data
    env_file: ../crates/.env.local.pgadmin ## Credentials are set using the env file

  pgadmin-syncflow-local:
    image: dpage/pgadmin4
    container_name: pgadmin-syncflow-local
    ports:
      - "5053:81" # Publicly, the pgadmin is available in port 5053 
    env_file: ../crates/.env.local.pgadmin ## Credentials are set using the env file
    depends_on:
      - postgres-syncflow-local

  migrations-syncflow-local:
    build:
      context: ../crates
      dockerfile: ../docker/Dockerfile.migrations
    image: syncflow-migrations:latest
    container_name: migrations-local
    volumes:
      - ../crates/.env.local.migration:/migrations/.env
    depends_on:
      - postgres-syncflow-local

  rabbitmq-syncflow-local:
    image: rabbitmq:4-management
    container_name: rabbitmq-syncflow-local
    ports:
      - "20001:20001" # Publicly, the RabbitMQ is available in port 20001
      - "20002:20002" # Publicly, the RabbitMQ management is available in port 20002
    volumes:
      - rabbitmq-data-local:/var/lib/rabbitmq
      - ./rabbitmq/rabbitmq.local.conf:/etc/rabbitmq/rabbitmq.conf

  api-syncflow-local:
    build:
      context: ../crates
      dockerfile: ../docker/Dockerfile.api
    image: syncflow-api:latest
    container_name: api-syncflow-local
    ports:
      - "8085:8085" # Publicly, the API is available in port 8085, we also choose to host the port 8085
    env_file: ../crates/.env.local
    depends_on:
      - migrations-syncflow-local
      - postgres-syncflow-local
      - rabbitmq-syncflow-local

  dashboard-syncflow-local:
    build:
      context: ../dashboard
      dockerfile: ../docker/Dockerfile.next
      args:
        - BUILD_ENV=local
    image: syncflow-dashboard:latest
    container_name: dashboard-syncflow-local
    volumes:
      - ../dashboard/config/local.json:/app/config/production.json
    ports:
      - "3003:3000"
    depends_on:
      - api-syncflow-local

volumes:
  postgres-data-local:
  rabbitmq-data-local:

```

Now, based on the compose file configuration, we can start creating the configuration json file, that can be used to deploy syncflow platform. Here's a sample json file you can use, that will work in conjuction with the `docker-compose.local.yaml` above:

We generated the following secrets [for jwt secrets, encryption key and others] using openssl in the file:

```bash
$ openssl rand -base64 32
```


```{json}
{
    "service": {
      "app_host": "0.0.0.0",
      "app_port": 8085,
      "database_url": "postgres://syncflow-local-admin:syncflow-local-admin-ab6AmlEQ!@postgres-syncflow-local:5432/syncflow",
      "num_actix_workers": 4,
      "jwt_secret":"1u7+IGA9qoEKv7T8dzevyh562yDQsQKYfyvueVs5090=",
      "encryption_key": "3qeMLUsyJr9POejsiS8/lsC+eYCH5RRA+8+hgIJ05rY=",
      "github_client_id": "Ov23ct15lxXNXf5nYReR", # Use anything as this is not used in the local deployment
      "github_client_secret": "56ae302bbf08fb1f0f40f31ea8a40cbe727x7072", # Use anything as this is not used in the local deployment
      "root_user": {
        "username": "syncflowlocaladmin", # Note that this is the username for the root user
        "password": "syncflowlocaladmin-ab6AmlEQ!", # Note that this is the password for the root user
        "email": "localadmin@syncflow.live", # Note that this is the email for the root user
      },
      "jwt_expiration": 3600000000000000, # Note that this is the expiration time for the jwt token
      "jwt_refresh_expiration": "54000000000000000", # Note that this is the expiration time for the jwt refresh token
      "rabbitmq_config": {
        "host": "rabbitmq-syncflow-local",
        "port": 20001,
        "root_username": "syncflow-local-user",
        "root_password": "syncflow-local-user-ab6AmlEQ!",
        "use_ssl": false,
        "vhost_name": "syncflow",
        "exchange_name": "syncflow_session_notifier_exchange",
        "queue_name": "syncflow_session_notifier_queue"
      },
      "test_user": "admin",
      "test_password": "admin"
    },
    "dashboard": {
      "syncflow_api_url": "https://api-local.syncflow.live",
      "next_public_syncflow_api_url": "https://api-local.syncflow.live",
      "next_public_livekit_server_url": "wss://livekit-local.syncflow.live",
      "auth_secret": "1u7+IGA9qoEKv7T8dzevyh562yDQsQKYfyvueVs5090=",
      "nextauth_url": "https://local.syncflow.live/",
      "nextauth_internal_url": "http://dashboard-syncflow-local:3000/",
      "github_client_id": "Ov23ct15lxXNXf5nYR9R", # Use anything as this is not used in the local deployment
      "github_client_secret": "56ae302bbf08fb1f0f40f31ea8a40cbe727x7072", # Use anything as this is not used in the local deployment
    },
    "database_pgadmin": {
      "postgres_user": "syncflow-local-admin",
      "postgres_password": "syncflow-local-admin-ab6AmlEQ!",
      "postgres_db": "syncflow",
      "pgadmin_default_email": "admin-local@syncflow.live",
      "pgadmin_default_password": "syncflow-local-admin-ab6AmlEQ!",
      "pgadmin_listen_port": 81
    },
    "migration": {
      "database_url": "postgres://syncflow-local-admin:syncflow-local-admin-ab6AmlEQ!@postgres-syncflow-local:5432/syncflow"
    }
  }
```

The next step is to create a rabbitmq configuration file and a dashboard config file for the deployment. Based on the json and the docker compose file above, we can create the following files:

```bash
$ touch docker/rabbitmq/rabbitmq.local.conf
```

Put the following contents in the `rabbitmq.local.conf` file:

```bash
default_user = rabbitmq-syncflow-local
default_pass = syncflow-local-user-ab6AmlEQ!
default_vhost = syncflow
listeners.tcp.default = 20001

management.tcp.port = 20002

auth_backends.1 = internal
auth_backends.2 = http

auth_http.http_method   = get
auth_http.user_path     = http://api-syncflow-local:8085/rmq/auth/user
auth_http.vhost_path    = http://api-syncflow-local:8085/rmq/auth/vhost
auth_http.resource_path = http://api-syncflow-local:8085/rmq/auth/resource
auth_http.topic_path    = http://api-syncflow-local:8085/rmq/auth/topic
```

And the following contents in the `dashboard/config/local.json` file:

```json
{
    "tagLine": "<strong>Welcome to SyncFlow.</strong> Use the dashboard to manage multimodal data collection with SyncFlow.",
    "logoPath": "/syncflow2.png",
    "userPermissions": "publishOnly",
    "syncFlowApiUrl": "https://api-local.syncflow.live"
} 
```

Now we can start the deployment proces(Replace the filename with the actual path of your json file):

```bash
$ python docker/generate-prod-config --config-file ../deployment-config-local.json --outfile-name .env.local
$ docker compose -p syncflow-local -f docker/docker-compose.local.yaml build
$ docker compose -p syncflow-local -f docker/docker-compose.local.yaml up rabbitmq-syncflow-local -d
$ docker compose -p syncflow-local -f docker/docker-compose.local.yaml up
```

## Step 6: Setting up DNSMASQ and Router Configuration

Now time has come to setup the DNSMASQ server and the router configuration. We will be using the local machine as the DNS server for the local network. The DNS server will be used to resolve the domain names to the local IP addresses of the services. The router will be configured to use the local DNS server for resolving the domain names.

### Setting up DNSMASQ
First, we need to install the DNSMASQ server. Use the following command to install the DNSMASQ server:

```bash
$ sudo apt-get install dnsmasq
```

Disable the systemd-resolved service and stop it:

```bash
$ sudo systemctl disable systemd-resolved
$ sudo systemctl stop systemd-resolved
```

Unlink the resolv.conf file and create a new resolv.conf file:

```bash
$ sudo unlink /etc/resolv.conf
$ sudo touch /etc/resolv.conf
```

Add the following contents to the resolv.conf file:

```bash
nameserver 127.0.0.1
nameserver 8.8.8.8
```

Now, we need to configure the DNSMASQ server. For us, uncommenting the following lines in the `/etc/dnsmasq.conf` file worked:

```bash
strict-order
interface=eno1 # Change this to the interface name of your network
listen-address=192.168.0.66,127.0.0.1 # Change this to the IP address of your local machine
```

Now we need to add the domain name and IP address of the container in the `/etc/hosts` file. Add the following lines to the `/etc/hosts` file:

```bash
192.168.0.66    livekit-local.syncflow.live
192.168.0.66    turn-local.syncflow.live
192.168.0.66    syncflow-sharer-local.syncflow.live
192.168.0.66    api-local.syncflow.live       
192.168.0.66    rabbitmq-local.syncflow.live
192.168.0.66    rabbitmq-mgmt-local.syncflow.live
192.168.0.66    local.syncflow.live          
192.168.0.66    pgadmin-local.syncflow.live   
192.168.0.66    postgres-local.syncflow.live

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```
## Step 7: Modifying the caddy configuration
The caddy configuration file is located in this [file](./livekit-local.syncflow.live/caddy.yaml), is modified for the domains that we will be using for the deployment. Before that copy the contents of `letsencrypt` to `/opt/livekit`.




## Step 4: Setting up local minio server

## Step 5: Setting up other containers



## Step 8: Creating a Project with Local Resources

## Step 8: Deploying the SyncFlow Sharer

## Modifying the caddy configuration for the sharer

## Step 9: Testing the deployment in the local network
