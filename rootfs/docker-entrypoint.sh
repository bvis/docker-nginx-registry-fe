#!/bin/sh -e

config_file=/etc/nginx/nginx.conf

if [ -n "${TLS_KEY}" ]; then
    cat /tmp/nginx.conf | \
        sed "s/# ssl_certificate/ssl_certificate/g" > /tmp/nginx.conf
fi

/usr/local/bin/envsubst \
  '${REGISTRY_ENDPOINT}:${SERVER_NAME}:${HTPASSWD_FILE}:${TLS_CERT}:${TLS_KEY}' \
  < /tmp/nginx.conf \
  > $config_file

exec nginx -g "daemon off;"
