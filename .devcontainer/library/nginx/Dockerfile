FROM alpine

RUN apk --no-cache add build-base pcre-dev openssl-dev gzip curl jq zlib-dev \
    && NGINX_VERSION=$(curl -s https://hub.docker.com/v2/repositories/library/nginx/tags | jq -r ".results[] | select(.images | any(.digest==\"$(curl -s https://hub.docker.com/v2/repositories/library/nginx/tags | jq -r '.results[] | select(.name=="stable").images[] | select(.architecture=="amd64").digest')\")) | .name " | grep "[0-9]*\.[0-9]*\.[0-9]") \
    && UPLOAD_VERSION=$(curl -s https://api.github.com/repos/fdintino/nginx-upload-module/tags | jq -r '.[0].name') \
    && wget -P /tmp https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && tar -zxvf /tmp/nginx-${NGINX_VERSION}.tar.gz -C /tmp \
    && wget -P /tmp https://github.com/fdintino/nginx-upload-module/archive/${UPLOAD_VERSION}.tar.gz && tar -zxvf /tmp/${UPLOAD_VERSION}.tar.gz -C /tmp \
    && cd /tmp/nginx-${NGINX_VERSION}\
    && ./configure \
    --add-module=/tmp/nginx-upload-module-${UPLOAD_VERSION}\
    --with-http_stub_status_module \
    && make \
    && make install

EXPOSE 80

STOPSIGNAL SIGQUIT

CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]