FROM mondedie/flarum:stable

# 设置时区
ENV TZ=Asia/Shanghai

# 安装netcat检查数据库连接
RUN apk add --no-cache netcat-openbsd

WORKDIR /flarum/app

# 暴露端口
EXPOSE 8888

# 创建启动脚本 - 使用echo命令逐行构建
RUN echo '#!/bin/sh' > /start.sh
RUN echo 'set -e' >> /start.sh
RUN echo 'echo "等待数据库连接..."' >> /start.sh
RUN echo 'while ! nc -z "${DB_HOST}" "${DB_PORT:-3306}"; do' >> /start.sh
RUN echo '    echo "数据库未就绪，等待中..."' >> /start.sh
RUN echo '    sleep 3' >> /start.sh
RUN echo 'done' >> /start.sh
RUN echo 'echo "数据库连接成功！"' >> /start.sh
RUN echo 'if [ ! -f "/flarum/app/config.php" ]; then' >> /start.sh
RUN echo '    echo "创建配置文件..."' >> /start.sh
RUN echo '    echo "<?php return [" > /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"debug\" => false," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"database\" => [" >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "        \"driver\" => \"mysql\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "        \"host\" => \"${DB_HOST}\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "        \"port\" => ${DB_PORT:-3306}," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "        \"database\" => \"${DB_NAME}\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "        \"username\" => \"${DB_USER}\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "        \"password\" => \"${DB_PASS}\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "        \"charset\" => \"utf8mb4\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "        \"collation\" => \"utf8mb4_unicode_ci\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "        \"prefix\" => \"flarum_\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "        \"strict\" => false," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "        \"engine\" => \"InnoDB\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "        \"prefix_indexes\" => true" >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    ]," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"url\" => \"${FORUM_URL}\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"paths\" => [" >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "        \"api\" => \"api\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "        \"admin\" => \"admin\"" >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    ]" >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "];" >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "配置文件创建完成"' >> /start.sh
RUN echo 'fi' >> /start.sh
RUN echo 'echo "清理缓存..."' >> /start.sh
RUN echo 'php flarum cache:clear' >> /start.sh
RUN echo 'echo "启动论坛服务..."' >> /start.sh
RUN echo 'cd /flarum/app/public' >> /start.sh
RUN echo 'exec php -S 0.0.0.0:8888 -t .' >> /start.sh

RUN chmod +x /start.sh

CMD ["/start.sh"]