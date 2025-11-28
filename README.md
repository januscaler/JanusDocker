# Janus Docker

Setup your own janus server locally or on production environment hassle free. this repo contains both `Dockerfile` and `docker-compose.yaml` for building as well as deployment of janus server.

# Recommended way

Use `Janus` folder to build or deploy janus gateway using docker-compose
it uses pre-build core image which comes with pre-installed janus gateway dependencies cuts down lot of compile time since nobody's got time to compile and wait for hours
you can find `JanusCoreDeps` docker image [here](https://hub.docker.com/repository/docker/shivanshtalwar0/januscoredeps/tags)
or can build your own if you got lot of time in this world. by using [JanusCoreDeps](./JanusCoreDeps/) folder it outputs docker image containing just janus peer dependencies


# QuickStart

    cd Janus
    docker-compose up -d # note option -d to start it in detached mode


## Build Alpine Image

```bash
    cd JanusCoreDeps
    ./build-alpine.sh
```
# Build

    cd Janus
    docker build -t dockerusername/janusgateway:latest .
    docker run -d dockerusername/janusgateway:latest
  

# Nginx Janus Domain Config
```
map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }
 
    upstream websocket {
        server 127.0.0.1:8188;
    }
    upstream admin_websocket {
        server 127.0.0.1:7188;
    }

    upstream rest{
        server 127.0.0.1:8088;
    }
    upstream admin_rest{
        server 127.0.0.1:7088;
    }

server {
        listen 80;

        server_name janus1.januscaler.com;
  
      location /admin/ws {
            proxy_pass http://admin_websocket;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $host;
        }


        location /admin {
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_pass http://admin_rest/admin;
        }



  location /janus/ws {
            proxy_pass http://websocket;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $host;
        }


        location /janus {
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_pass http://rest/janus;
            }
}
```
