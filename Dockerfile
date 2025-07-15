FROM mondedie/flarum:stable

# 设置时区为中国
ENV TZ=Asia/Shanghai

# 只需要安装 netcat 用于检查连接
RUN apk add --no-cache netcat-openbsd

# 设置工作目录
WORKDIR /flarum/app

# 暴露 Flarum 运行的端口
EXPOSE 8888

# 创建启动脚本
RUN printf '#!/bin/sh\nset -e\n\n# 如果 DB_PORT 环境变量未设置，则默认使用 3306\nDB_PORT=${DB_PORT:-3306}\n\necho "=== NexusK Flarum 正在启动... ==="\necho "数据库主机 (DB_HOST): ${DB_HOST}"\necho "数据库端口 (DB_PORT): ${DB_PORT}"\necho "正在等待 MySQL 数据库连接..."\n\ntimeout=180\ncounter=0\nwhile ! nc -z "${DB_HOST}" "${DB_PORT}"; do\n    counter=$((counter + 1))\n    if [ ${counter} -ge ${timeout} ]; then\n        echo "错误：数据库连接超时！请检查数据库状态和网络设置。"\n        exit 1\n    fi\n    echo "数据库尚未就绪，5秒后重试..."\n    sleep 5\ndone\n\necho "数据库连接成功！"\n\nif [ ! -f "/flarum/app/config.php" ]; then\n    echo "检测到首次运行，正在安装 Flarum..."\n    \n    # 创建配置文件\n    printf "<?php return array (\\n  '\''debug'\'' => false,\\n  '\''database'\'' =>\\n  array (\\n    '\''driver'\'' => '\''mysql'\'',\\n    '\''host'\'' => '\''%s'\'',\\n    '\''port'\'' => %s,\\n    '\''database'\'' => '\''%s'\'',\\n    '\''username'\'' => '\''%s'\'',\\n    '\''password'\'' => '\''%s'\'',\\n    '\''charset'\'' => '\''utf8mb4'\'',\\n    '\''collation'\'' => '\''utf8mb4_unicode_ci'\'',\\n    '\''prefix'\'' => '\''flarum_'\'',\\n    '\''strict'\'' => false,\\n    '\''engine'\'' => '\''InnoDB'\'',\\n    '\''prefix_indexes'\'' => true,\\n  ),\\n  '\''url'\'' => '\''%s'\'',\\n  '\''paths'\'' =>\\n  array (\\n    '\''api'\'' => '\''api'\'',\\n    '\''admin'\'' => '\''admin'\'',\\n  ),\\n);" "${DB_HOST}" "${DB_PORT}" "${DB_NAME}" "${DB_USER}" "${DB_PASS}" "${FORUM_URL}" > /flarum/app/config.php\n\n    echo "config.php 创建成功。"\n    php flarum migrate --force\n    php flarum install --defaults --admin-user="${FLARUM_ADMIN_USER}" --admin-pass="${FLARUM_ADMIN_PASS}" --admin-email="${FLARUM_ADMIN_MAIL}" --title="${FLARUM_TITLE}"\n    echo "Flarum 安装完成！"\nfi\n\necho "正在清理缓存..."\nphp flarum cache:clear\n\necho "启动 Flarum 服务..."\nexec php flarum serve --host=0.0.0.0 --port=8888\n' > /start.sh && \
    chmod +x /start.sh

# 使用启动脚本
CMD ["/start.sh"]