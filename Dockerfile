FROM mondedie/flarum:stable

# 设置时区为中国
ENV TZ=Asia/Shanghai

# 只需要安装 netcat 用于检查连接
RUN apk add --no-cache netcat-openbsd

# 设置工作目录
WORKDIR /flarum/app

# 暴露 Flarum 运行的端口
EXPOSE 8888

# 创建PHP路由文件（用于PHP内置服务器）
RUN cat > /flarum/app/router.php << 'EOF'
<?php
// 检查文件是否存在
if (file_exists($_SERVER['DOCUMENT_ROOT'] . $_SERVER['REQUEST_URI'])) {
    return false; // 让内置服务器处理静态文件
}

// 重定向到 index.php
$_SERVER['SCRIPT_NAME'] = '/index.php';
$_SERVER['SCRIPT_FILENAME'] = $_SERVER['DOCUMENT_ROOT'] . '/index.php';

// 设置正确的 REQUEST_URI
chdir($_SERVER['DOCUMENT_ROOT']);
require 'index.php';
EOF

# 创建启动脚本
RUN echo '#!/bin/sh' > /start.sh
RUN echo 'set -e' >> /start.sh
RUN echo 'DB_PORT=${DB_PORT:-3306}' >> /start.sh
RUN echo 'echo "=== NexusK Flarum 正在启动... ==="' >> /start.sh
RUN echo 'echo "数据库主机: ${DB_HOST}"' >> /start.sh
RUN echo 'echo "数据库端口: ${DB_PORT}"' >> /start.sh
RUN echo 'echo "正在等待 MySQL 数据库连接..."' >> /start.sh
RUN echo 'timeout=180' >> /start.sh
RUN echo 'counter=0' >> /start.sh
RUN echo 'while ! nc -z "${DB_HOST}" "${DB_PORT}"; do' >> /start.sh
RUN echo '    counter=$((counter + 1))' >> /start.sh
RUN echo '    if [ ${counter} -ge ${timeout} ]; then' >> /start.sh
RUN echo '        echo "数据库连接超时！"' >> /start.sh
RUN echo '        exit 1' >> /start.sh
RUN echo '    fi' >> /start.sh
RUN echo '    echo "等待数据库，5秒后重试..."' >> /start.sh
RUN echo '    sleep 5' >> /start.sh
RUN echo 'done' >> /start.sh
RUN echo 'echo "数据库连接成功！"' >> /start.sh
RUN echo 'if [ ! -f "/flarum/app/config.php" ]; then' >> /start.sh
RUN echo '    echo "创建配置文件..."' >> /start.sh
RUN echo '    echo "<?php return [" > /flarum/app/config.php' >> /start.sh
RUN echo '    echo "  \"debug\" => false," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "  \"database\" => [" >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"driver\" => \"mysql\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"host\" => \"${DB_HOST}\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"port\" => ${DB_PORT}," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"database\" => \"${DB_NAME}\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"username\" => \"${DB_USER}\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"password\" => \"${DB_PASS}\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"charset\" => \"utf8mb4\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"collation\" => \"utf8mb4_unicode_ci\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"prefix\" => \"flarum_\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"strict\" => false," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"engine\" => \"InnoDB\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"prefix_indexes\" => true" >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "  ]," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "  \"url\" => \"${FORUM_URL}\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "  \"paths\" => [" >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"api\" => \"api\"," >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "    \"admin\" => \"admin\"" >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "  ]" >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "];" >> /flarum/app/config.php' >> /start.sh
RUN echo '    echo "config.php 创建成功。"' >> /start.sh
RUN echo 'fi' >> /start.sh
RUN echo 'echo "正在清理缓存..."' >> /start.sh
RUN echo 'php flarum cache:clear' >> /start.sh
RUN echo 'echo "启动 Flarum 服务..."' >> /start.sh
RUN echo 'cd /flarum/app/public' >> /start.sh
RUN echo 'exec php -S 0.0.0.0:8888 -t /flarum/app/public /flarum/app/router.php' >> /start.sh

# 给启动脚本执行权限
RUN chmod +x /start.sh

# 使用启动脚本
CMD ["/start.sh"]