# docker_private_registry

# Make directories for us to create and store our files
```
mkdir -p registry/{nginx,auth}
```

### Change Directory to "registry/"
```
cd registry
```

### Make additional directories for us to create and store our nginx files
```
mkdir -p nginx/{conf.d/,ssl}
```

# Docker Compose File
### Create a docker-compose.yml file for docker configurations
```
vi docker-compose.yml
```

# Paste the below listed code into the .yml
```
version: '3'
services:
#Registry
  registry:
    image: registry:2
    restart: always
    ports:
    - "5000:5000"
    environment:
      REGISTRY_AUTH: htpasswd
      REGISTRY_AUTH_HTPASSWD_REALM: Registry-Realm
      REGISTRY_AUTH_HTPASSWD_PATH: /auth/registry.passwd
      REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY: /data
    volumes:
      - registrydata:/data
      - ./auth:/auth
    networks:
      - mynet
#Nginx Service
  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    tty: true
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d/:/etc/nginx/conf.d/
      - ./nginx/ssl/:/etc/nginx/ssl/
    networks:
      - mynet
#Docker Networks
networks:
  mynet:
    driver: bridge
#Volumes
volumes:
  registrydata:
    driver: local
```
# NGINX Configurations
### Change Directory to nginx/conf.d
```
cd nginx/conf.d
```

###  Create a new file for "registry" configurations
```
vi registry.conf
```

# Paste the below listed code in the file
```
upstream docker-registry {
    server registry:5000;
}

server {
    listen 80;
    server_name registry.example-server.com;
    return 301 https://registry.example-server.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name registry.example-server.com;

    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;

    # Log files for Debug
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;

    location / {
        # Do not allow connections from docker 1.5 and earlier
        # docker pre-1.6.0 did not properly set the user agent on ping, catch "Go *" user agents
        if ($http_user_agent ~ "^(docker\/1\.(3|4|5(?!\.[0-9]-dev))|Go ).*$" )  {
            return 404;
        }

        proxy_pass                          http://docker-registry;
        proxy_set_header  Host              $http_host;
        proxy_set_header  X-Real-IP         $remote_addr;
        proxy_set_header  X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header  X-Forwarded-Proto $scheme;
        proxy_read_timeout                  900;
    }

}
```
### Create an additional config to increase nginx file upload size

```
vi additional.conf
```

### Paste the below listed line of code
```
client_max_body_size 2G;
```

# To create our own self-signed certificate, we can create our own CA

### Create a Private Key for the CA
```
openssl genrsa -des3 -out CAPrivate.key 2048
```

### Generate the root certificate
```
openssl req -x509 -new -nodes -key CAPrivate.key -sha256 -days 365 -out CAPrivate.pem
```

### Generate Key for our registry certificate
```
openssl genrsa -out MyPrivate.key 2048
```

### Generate CSR for our registry certificate
```
openssl req -new -key MyPrivate.key -out MyRequest.csr
```

### Generate the certificate using the CSR

```
openssl x509 -req -in MyRequest.csr -CA CAPrivate.pem -CAkey CAPrivate.key -CAcreateserial -out MyRequest.crt -days 365 -sha256
```

Store the **key** and **certificate** file in the **nginx/ssl** directories we created above

# Bring up the registry
```
docker-compose up (From the /registry directory)
```
