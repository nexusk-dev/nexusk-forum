FROM mondedie/flarum:stable

# 设置时区为中国
ENV TZ=Asia/Shanghai

# 只需要安装 netcat 用于检查连接
RUN apk add --no-cache netcat-openbsd

# 设置工作目录
WORKDIR /flarum/app

# 暴露 Flarum 运行的端口
EXPOSE 8888

# 创建启动脚本 - 使用简单的echo命令
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'DB_PORT=${DB_PORT:-3306}' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "=== NexusK Flarum 正在启动... ==="' >> /start.sh && \
    echo 'echo "数据库主机: ${DB_HOST}"' >> /start.sh && \
    echo 'echo "数据库端口: ${DB_PORT}"' >> /start.sh && \
    echo 'echo "正在等待 MySQL 数据库连接..."' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'timeout=180' >> /start.sh && \
    echo 'counter=0' >> /start.sh && \
    echo 'while ! nc -z "${DB_HOST}" "${DB_PORT}"; do' >> /start.sh && \
    echo '    counter=$((counter + 1))' >> /start.sh && \
    echo '    if [ ${counter} -ge ${timeout} ]; then' >> /start.sh && \
    echo '        echo "数据库连接超时！"' >> /start.sh && \
    echo '        exit 1' >> /start.sh && \
    echo '    fi' >> /start.sh && \
    echo '    echo "等待数据库，5秒后重试..."' >> /start.sh && \
    echo '    sleep 5' >> /start.sh && \
    echo 'done' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "数据库连接成功！"' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'if [ ! -f "/flarum/app/config.php" ]; then' >> /start.sh && \
    echo '    echo "检测到首次运行，正在安装 Flarum..."' >> /start.sh && \
    echo '    # 创建配置文件' >> /start.sh && \
    echo '    echo "<?php return [" > /flarum/app/config.php' >> /start.sh && \
    echo '    echo "  \"debug\" => false," >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "  \"database\" => [" >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "    \"driver\" => \"mysql\"," >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "    \"host\" => \"${DB_HOST}\"," >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "    \"port\" => ${DB_PORT}," >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "    \"database\" => \"${DB_NAME}\"," >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "    \"username\" => \"${DB_USER}\"," >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "    \"password\" => \"${DB_PASS}\"," >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "    \"charset\" => \"utf8mb4\"," >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "    \"collation\" => \"utf8mb4_unicode_ci\"," >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "    \"prefix\" => \"flarum_\"," >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "    \"strict\" => false," >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "    \"engine\" => \"InnoDB\"," >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "    \"prefix_indexes\" => true" >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "  ]," >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "  \"url\" => \"${FORUM_URL}\"," >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "  \"paths\" => [" >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "    \"api\" => \"api\"," >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "    \"admin\" => \"admin\"" >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "  ]" >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "];" >> /flarum/app/config.php' >> /start.sh && \
    echo '    echo "config.php 创建成功。"' >> /start.sh && \
    echo '    php flarum migrate --force' >> /start.sh && \
    echo '    php flarum install --defaults --admin-user="${FLARUM_ADMIN_USER}" --admin-pass="${FLARUM_ADMIN_PASS}" --admin-email="${FLARUM_ADMIN_MAIL}" --title="${FLARUM_TITLE}"' >> /start.sh && \
    echo '    echo "Flarum 安装完成！"' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "正在清理缓存..."' >> /start.sh && \
    echo 'php flarum cache:clear' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "启动 Flarum 服务..."' >> /start.sh && \
    echo 'exec php flarum serve --host=0.0.0.0 --port=8888' >> /start.sh && \
    chmod +x /start.sh

# 使用启动脚本
CMD ["/start.sh"]