FROM nginx:stable-alpine

COPY ./vhost.conf /etc/nginx/conf.d/default.conf

#символическая ссылка для журналов если что-то пойдет не так на нашем веб-сервере
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log
CMD ["nginx-debug", "-g", "daemon off;"]
