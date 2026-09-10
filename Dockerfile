FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY config.js.template /usr/share/nginx/html/config.js.template
COPY 40-inject-config.sh /docker-entrypoint.d/40-inject-config.sh
COPY nginx-no-cache.conf /etc/nginx/conf.d/default.conf
RUN chmod +x /docker-entrypoint.d/40-inject-config.sh

EXPOSE 80
