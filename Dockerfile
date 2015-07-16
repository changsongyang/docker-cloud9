FROM ubuntu:14.04
 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN locale-gen en_US en_US.UTF-8
ENV LANG en_US.UTF-8

#Runit
RUN apt-get install -y runit 
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq
RUN apt-get install -y build-essential
RUN apt-get install -y nginx

#Node
RUN wget -O - http://nodejs.org/dist/v0.12.7/node-v0.12.7-linux-x64.tar.gz | tar xz
RUN mv node* node && \
    ln -s /node/bin/node /usr/local/bin/node && \
    ln -s /node/bin/npm /usr/local/bin/npm
ENV NODE_PATH /usr/local/lib/node_modules

#NPM Modules
RUN npm install -g gulp npm-check-updates slush slush-generator

#Docker client only
RUN wget -O /usr/local/bin/docker https://get.docker.io/builds/Linux/x86_64/docker-latest && \
    chmod +x /usr/local/bin/docker
#Compose
RUN curl -L https://github.com/docker/compose/releases/download/1.3.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose


#Change last_commit hash as a cache buster
ENV latest_commit 9ce99fb2f0fc45fecc5448b28301e3258835383e
RUN git clone --depth 1 https://github.com/c9/core.git
RUN cd core && \
    npm install && \
    ./scripts/install-sdk.sh

#ssl
RUN mkdir -p /etc/nginx/ssl && \
    cd /etc/nginx/ssl && \
    export PASSPHRASE=$(head -c 500 /dev/urandom | tr -dc a-z0-9A-Z | head -c 128; echo) && \
    openssl genrsa -des3 -out server.key -passout env:PASSPHRASE 2048 && \
    openssl req -new -batch -key server.key -out server.csr -subj "/C=/ST=/O=org/localityName=/commonName=org/organizationalUnitName=org/emailAddress=/" -passin env:PASSPHRASE && \
    openssl rsa -in server.key -out server.key -passin env:PASSPHRASE && \
    openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt

#Set your user:password
RUN echo "user:`perl -le 'print crypt(\"password\", \"salt-hash\")'`" > /etc/nginx/htpasswd
ADD default /etc/nginx/sites-enabled/default

#NPM cache
RUN git clone --depth 1 https://github.com/mixu/npm_lazy.git && \
    cd npm_lazy && \
    npm install && \
    npm config set registry http://localhost:8080/

#Add runit services
ADD sv /etc/service 

