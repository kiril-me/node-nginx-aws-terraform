FROM nginx:1.13.3-alpine

EXPOSE 80 443

COPY nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /opt/app/public/

COPY error.html /opt/app/public/error.html