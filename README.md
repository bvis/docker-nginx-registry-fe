# Nginx Registry FE

Provides basic auth and TLS support when a variable is defined.

An usual configuration would be to have this service running on its own network.

## Supported Variables

- REGISTRY_ENDPOINT=Registry service address [registry:5000 by default]
- SERVER_NAME=Server name used when a TLS certificate is provided
- HTPASSWD_FILE=Path of the htpasswd file used for provide basic auth
- TLS_CERT=TLS certificate file
- TLS_KEY=TLS Key file

## Preconfigure service dependencies

The image assumes by default that you are running a registry service and it has connectivity.
In the next example I'm configuring a common network to ensure connectivity and a registry service backed by S3, the [official registry image](https://hub.docker.com/_/registry/) could be used instead.

```bash
$ docker network create --driver overlay registry
$ docker \
    service create --name registry \
      --reserve-memory 100m \
      --limit-memory 256m \
      --network registry \
      --publish 5000:5000 \
      -e AWS_BUCKET=${AWS_S3_BUCKET} \
      -e AWS_REGION=${AWS_REGION} \
      -e STORAGE_PATH=/registry \
      -e AWS_KEY=${AWS_ACCESS_KEY_ID_S3} \
      -e AWS_SECRET=${AWS_SECRET_ACCESS_KEY_S3} \
      softonic/registry-s3:latest
```

## Configuration with TLS (recommended)

In this examples I'm using docker swarm secrets for security, the same could be achieved adding or mounting the needed files.

### Create `htpasswd` file

Before the configuration you'll need a valid `htpasswd` file. If you don't have any you can create it easily with the next commands:

```bash
$ echo -n 'basi:' >> nginx.htpasswd
$ openssl passwd -apr1 >> nginx.htpasswd
```

You'll be prompted for the password.

### Create secrets

Create the secrets that contain the TLS certificates and the user/password for auth.

```bash
$ docker secret create \
  nginx-registry-fe_domain.crt \
  --label service=nginx-registry-fe \
  domain.crt
$ docker secret create \
  nginx-registry-fe_domain.key \
  --label service=nginx-registry-fe \
  domain.key
$ docker secret create \
  nginx-registry-fe_htpasswd \
  --label service=nginx-registry-fe \
  nginx.htpasswd
```

### Launch service

```bash
$ docker \
    service create \
    --name nginx-registry-fe \
    --reserve-memory 32m \
    --limit-memory 64m \
    --publish 443:443 \
    --network registry \
    --secret source=nginx-registry-fe_domain.crt,target=domain.crt \
    --secret source=nginx-registry-fe_domain.key,target=domain.key \
    --secret source=nginx-registry-fe_htpasswd,target=nginx.htpasswd \
    -e TLS_CERT=/run/secrets/domain.crt \
    -e TLS_KEY=/run/secrets/domain.key \
    basi/nginx-registry-fe:latest
```

## Configuration without TLS (not recommended)

I'd suggest to avoid this configuration unless this image works under another layer that provides automatic TLS management.

### Create `htpasswd` file

Before the configuration you'll need a valid `htpasswd` file. If you don't have any you can create it easily with the next commands:

```bash
$ echo -n 'basi:' >> nginx.htpasswd
$ openssl passwd -apr1 >> nginx.htpasswd
```

You'll be prompted for the password.

### Create secrets

Create the secrets that contain user/password for auth.

```bash
$ docker secret create \
  nginx-registry-fe.htpasswd \
  --label service=nginx-registry-fe \
  nginx.htpasswd
```

### Launch service

```bash
$ docker \
    service create \
    --name nginx-registry-fe \
    --reserve-memory 32m \
    --limit-memory 64m \
    --publish 80:80 \
    --network registry \
    --secret source=nginx-registry-fe.htpasswd,target=nginx.htpasswd \
    basi/nginx-registry-fe:latest
```
