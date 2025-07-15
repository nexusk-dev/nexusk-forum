FROM mondedie/flarum:stable

ENV TZ=Asia/Shanghai

RUN apk add --no-cache netcat-openbsd

WORKDIR /flarum/app

EXPOSE 8888

# 超级简单的启动脚本
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'echo "=== 启动 NexusK Forum ==="' >> /start.sh && \
    echo 'while ! nc -z "$DB_HOST" "$DB_PORT"; do' >> /start.sh && \
    echo '  echo "等待数据库..."' >> /start.sh && \
    echo '  sleep 3' >> /start.sh && \
    echo 'done' >> /start.sh && \
    echo 'echo "数据库连接成功！"' >> /start.sh && \
    echo 'rm -f /flarum/app/config.php' >> /start.sh && \
    echo 'echo "启动论坛..."' >> /start.sh && \
    echo 'cd /flarum/app/public' >> /start.sh && \
    echo 'exec php -S 0.0.0.0:8888 -t .' >> /start.sh && \
    chmod +x /start.sh

CMD ["/start.sh"]