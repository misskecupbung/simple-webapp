FROM quay.io/openshifttest/base-alpine:1.2

RUN apk update && \
    apk add nginx

COPY nginx-default.conf /etc/nginx/http.d/default.conf 

COPY html /var/lib/nginx/html

EXPOSE 80

CMD nginx -g "daemon off;"

