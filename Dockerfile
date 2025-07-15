FROM mondedie/flarum:stable

# 设置时区
ENV TZ=Asia/Shanghai

# 安装netcat检查数据库连接
RUN apk add --no-cache netcat-openbsd

WORKDIR /flarum/app

# 暴露端口
EXPOSE 8888

# 创建启动脚本 - 直接创建配置文件
RUN echo '#!/bin/sh' > /start.sh
RUN echo 'set -e' >> /start.sh
RUN echo 'echo "等待数据库连接..."' >> /start.sh
RUN echo 'while ! nc -z "${DB_HOST}" "${DB_PORT:-21453}"; do' >> /start.sh
RUN echo '    echo "数据库未就绪，等待中..."' >> /start.sh
RUN echo '    sleep 3' >> /start.sh
RUN echo 'done' >> /start.sh
RUN echo 'echo "数据库连接成功！"' >> /start.sh
RUN echo '# 直接创建配置文件' >> /start.sh
RUN echo 'cat > /flarum/app/config.php << "EOF"' >> /start.sh
RUN echo '<?php return [' >> /start.sh
RUN echo '    "debug" => false,' >> /start.sh
RUN echo '    "database" => [' >> /start.sh
RUN echo '        "driver" => "mysql",' >> /start.sh
RUN echo '        "host" => "${DB_HOST}",' >> /start.sh
RUN echo '        "port" => ${DB_PORT:-21453},' >> /start.sh
RUN echo '        "database" => "${DB_NAME}",' >> /start.sh
RUN echo '        "username" => "${DB_USER}",' >> /start.sh
RUN echo '        "password" => "${DB_PASS}",' >> /start.sh
RUN echo '        "charset" => "utf8mb4",' >> /start.sh
RUN echo '        "collation" => "utf8mb4_unicode_ci",' >> /start.sh
RUN echo '        "prefix" => "flarum_",' >> /start.sh
RUN echo '        "strict" => false,' >> /start.sh
RUN echo '        "engine" => "InnoDB",' >> /start.sh
RUN echo '        "prefix_indexes" => true,' >> /start.sh
RUN echo '    ],' >> /start.sh
RUN echo '    "url" => "${FORUM_URL}",' >> /start.sh
RUN echo '    "paths" => [' >> /start.sh
RUN echo '        "api" => "api",' >> /start.sh
RUN echo '        "admin" => "admin",' >> /start.sh
RUN echo '    ],' >> /start.sh
RUN echo '];' >> /start.sh
RUN echo 'EOF' >> /start.sh
RUN echo 'echo "配置文件创建完成"' >> /start.sh
RUN echo 'echo "启动论坛服务..."' >> /start.sh
RUN echo 'cd /flarum/app/public' >> /start.sh
RUN echo 'exec php -S 0.0.0.0:8888 -t .' >> /start.sh

RUN chmod +x /start.sh

CMD ["/start.sh"]