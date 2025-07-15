FROM mondedie/flarum:stable

# 设置时区
ENV TZ=Asia/Shanghai

# 安装netcat检查数据库连接
RUN apk add --no-cache netcat-openbsd

WORKDIR /flarum/app

# 暴露端口
EXPOSE 8888

# 创建启动脚本 - 使用printf避免语法错误
RUN echo '#!/bin/sh' > /start.sh
RUN echo 'set -e' >> /start.sh
RUN echo 'echo "等待数据库连接..."' >> /start.sh
RUN echo 'while ! nc -z "${DB_HOST}" "${DB_PORT:-21453}"; do' >> /start.sh
RUN echo '    echo "数据库未就绪，等待中..."' >> /start.sh
RUN echo '    sleep 3' >> /start.sh
RUN echo 'done' >> /start.sh
RUN echo 'echo "数据库连接成功！"' >> /start.sh
RUN echo '# 使用printf创建配置文件，避免语法错误' >> /start.sh
RUN echo 'printf "<?php return [\\n" > /flarum/app/config.php' >> /start.sh
RUN echo 'printf "    '\''debug'\'' => false,\\n" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "    '\''database'\'' => [\\n" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "        '\''driver'\'' => '\''mysql'\'',\\n" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "        '\''host'\'' => '\''%s'\'',\\n" "${DB_HOST}" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "        '\''port'\'' => %s,\\n" "${DB_PORT:-21453}" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "        '\''database'\'' => '\''%s'\'',\\n" "${DB_NAME}" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "        '\''username'\'' => '\''%s'\'',\\n" "${DB_USER}" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "        '\''password'\'' => '\''%s'\'',\\n" "${DB_PASS}" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "        '\''charset'\'' => '\''utf8mb4'\'',\\n" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "        '\''collation'\'' => '\''utf8mb4_unicode_ci'\'',\\n" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "        '\''prefix'\'' => '\''flarum_'\'',\\n" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "        '\''strict'\'' => false,\\n" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "        '\''engine'\'' => '\''InnoDB'\'',\\n" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "        '\''prefix_indexes'\'' => true,\\n" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "    ],\\n" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "    '\''url'\'' => '\''%s'\'',\\n" "${FORUM_URL}" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "    '\''paths'\'' => [\\n" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "        '\''api'\'' => '\''api'\'',\\n" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "        '\''admin'\'' => '\''admin'\'',\\n" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "    ],\\n" >> /flarum/app/config.php' >> /start.sh
RUN echo 'printf "];\\n" >> /flarum/app/config.php' >> /start.sh
RUN echo 'echo "配置文件创建完成"' >> /start.sh
RUN echo 'echo "显示配置文件内容："' >> /start.sh
RUN echo 'cat /flarum/app/config.php' >> /start.sh
RUN echo 'echo "启动论坛服务..."' >> /start.sh
RUN echo 'cd /flarum/app/public' >> /start.sh
RUN echo 'exec php -S 0.0.0.0:8888 -t .' >> /start.sh

RUN chmod +x /start.sh

CMD ["/start.sh"]