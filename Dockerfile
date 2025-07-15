FROM mondedie/flarum:stable

# 设置时区为中国
ENV TZ=Asia/Shanghai

# 安装 netcat 和 mysql-client 用于检查数据库连接和执行 SQL
RUN apk add --no-cache netcat-openbsd mysql-client

# 设置工作目录
WORKDIR /flarum/app

# 暴露 Flarum 运行的端口
EXPOSE 8888

# 创建数据库初始化 SQL 文件
RUN cat > /init_database.sql << 'EOF'
-- Flarum 核心表结构
CREATE TABLE IF NOT EXISTS `flarum_settings` (
  `key` varchar(65) NOT NULL,
  `value` text DEFAULT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `flarum_users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `is_email_confirmed` tinyint(1) NOT NULL DEFAULT 0,
  `password` varchar(100) NOT NULL,
  `avatar_url` varchar(100) DEFAULT NULL,
  `preferences` text DEFAULT NULL,
  `joined_at` datetime DEFAULT NULL,
  `last_seen_at` datetime DEFAULT NULL,
  `marked_all_as_read_at` datetime DEFAULT NULL,
  `read_notifications_at` datetime DEFAULT NULL,
  `discussion_count` int(10) unsigned NOT NULL DEFAULT 0,
  `comment_count` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_username_unique` (`username`),
  UNIQUE KEY `users_email_unique` (`email`),
  KEY `users_joined_at_index` (`joined_at`),
  KEY `users_last_seen_at_index` (`last_seen_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `flarum_discussions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(200) NOT NULL,
  `comment_count` int(11) NOT NULL DEFAULT 1,
  `participant_count` int(10) unsigned NOT NULL DEFAULT 0,
  `post_number_index` int(10) unsigned NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `first_post_id` int(10) unsigned DEFAULT NULL,
  `last_posted_at` datetime DEFAULT NULL,
  `last_posted_user_id` int(10) unsigned DEFAULT NULL,
  `last_post_id` int(10) unsigned DEFAULT NULL,
  `last_post_number` int(10) unsigned DEFAULT NULL,
  `hidden_at` datetime DEFAULT NULL,
  `hidden_user_id` int(10) unsigned DEFAULT NULL,
  `slug` varchar(255) NOT NULL,
  `is_approved` tinyint(1) NOT NULL DEFAULT 1,
  `is_locked` tinyint(1) NOT NULL DEFAULT 0,
  `is_sticky` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `discussions_hidden_user_id_foreign` (`hidden_user_id`),
  KEY `discussions_first_post_id_foreign` (`first_post_id`),
  KEY `discussions_last_post_id_foreign` (`last_post_id`),
  KEY `discussions_last_posted_user_id_foreign` (`last_posted_user_id`),
  KEY `discussions_user_id_foreign` (`user_id`),
  KEY `discussions_created_at_index` (`created_at`),
  KEY `discussions_last_posted_at_index` (`last_posted_at`),
  KEY `discussions_comment_count_index` (`comment_count`),
  KEY `discussions_participant_count_index` (`participant_count`),
  KEY `discussions_is_approved_index` (`is_approved`),
  KEY `discussions_is_sticky_index` (`is_sticky`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `flarum_posts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `discussion_id` int(10) unsigned NOT NULL,
  `number` int(10) unsigned DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `type` varchar(100) DEFAULT NULL,
  `content` mediumtext DEFAULT NULL,
  `edited_at` datetime DEFAULT NULL,
  `edited_user_id` int(10) unsigned DEFAULT NULL,
  `hidden_at` datetime DEFAULT NULL,
  `hidden_user_id` int(10) unsigned DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `is_approved` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `posts_discussion_id_number_unique` (`discussion_id`,`number`),
  KEY `posts_edited_user_id_foreign` (`edited_user_id`),
  KEY `posts_hidden_user_id_foreign` (`hidden_user_id`),
  KEY `posts_discussion_id_number_index` (`discussion_id`,`number`),
  KEY `posts_discussion_id_created_at_index` (`discussion_id`,`created_at`),
  KEY `posts_user_id_created_at_index` (`user_id`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `flarum_groups` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name_singular` varchar(100) NOT NULL,
  `name_plural` varchar(100) NOT NULL,
  `color` varchar(20) DEFAULT NULL,
  `icon` varchar(100) DEFAULT NULL,
  `is_hidden` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `flarum_group_user` (
  `user_id` int(10) unsigned NOT NULL,
  `group_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`user_id`,`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `flarum_group_permission` (
  `group_id` int(10) unsigned NOT NULL,
  `permission` varchar(100) NOT NULL,
  PRIMARY KEY (`group_id`,`permission`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `flarum_notifications` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `from_user_id` int(10) unsigned DEFAULT NULL,
  `type` varchar(100) NOT NULL,
  `subject_id` int(10) unsigned DEFAULT NULL,
  `data` text DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `read_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `notifications_from_user_id_foreign` (`from_user_id`),
  KEY `notifications_user_id_index` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `flarum_password_tokens` (
  `token` varchar(100) NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`token`),
  KEY `password_tokens_user_id_foreign` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `flarum_email_tokens` (
  `token` varchar(100) NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `email` varchar(150) NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`token`),
  KEY `email_tokens_user_id_foreign` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `flarum_registration_tokens` (
  `token` varchar(100) NOT NULL,
  `data` text DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `flarum_api_keys` (
  `key` varchar(100) NOT NULL,
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `allowed_ips` text DEFAULT NULL,
  `scopes` text DEFAULT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `last_activity_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `api_keys_key_unique` (`key`),
  KEY `api_keys_user_id_foreign` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `flarum_access_tokens` (
  `token` varchar(40) NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `last_activity_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  `type` varchar(100) NOT NULL,
  `title` varchar(150) DEFAULT NULL,
  `last_ip_address` varchar(45) DEFAULT NULL,
  `last_user_agent` text DEFAULT NULL,
  PRIMARY KEY (`token`),
  KEY `access_tokens_user_id_foreign` (`user_id`),
  KEY `access_tokens_type_index` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 插入默认数据
INSERT IGNORE INTO `flarum_groups` (`id`, `name_singular`, `name_plural`, `color`, `icon`, `is_hidden`) VALUES
(1, 'Admin', 'Admins', '#B72A2A', 'fas fa-wrench', 0),
(2, 'Guest', 'Guests', NULL, NULL, 0),
(3, 'Member', 'Members', NULL, NULL, 0),
(4, 'Mod', 'Mods', '#80349E', 'fas fa-bolt', 0);

-- 插入默认权限
INSERT IGNORE INTO `flarum_group_permission` (`group_id`, `permission`) VALUES
(1, 'viewForum'),
(1, 'startDiscussion'),
(1, 'discussion.reply'),
(1, 'discussion.edit'),
(1, 'discussion.hide'),
(1, 'discussion.delete'),
(1, 'discussion.rename'),
(1, 'discussion.viewIpsPosts'),
(1, 'discussion.lock'),
(1, 'discussion.sticky'),
(1, 'discussion.tag'),
(1, 'user.edit'),
(1, 'user.editCredentials'),
(1, 'user.editGroups'),
(1, 'user.suspend'),
(1, 'user.viewLastSeenAt'),
(1, 'searchUsers'),
(1, 'user.delete'),
(1, 'moderateAccessTokens'),
(2, 'viewForum'),
(3, 'viewForum'),
(3, 'startDiscussion'),
(3, 'discussion.reply'),
(3, 'user.editOwnCredentials'),
(3, 'user.viewLastSeenAt'),
(3, 'searchUsers'),
(4, 'viewForum'),
(4, 'startDiscussion'),
(4, 'discussion.reply'),
(4, 'discussion.edit'),
(4, 'discussion.hide'),
(4, 'discussion.rename'),
(4, 'discussion.viewIpsPosts'),
(4, 'discussion.lock'),
(4, 'discussion.sticky'),
(4, 'user.suspend'),
(4, 'user.viewLastSeenAt'),
(4, 'searchUsers'),
(4, 'moderateAccessTokens');

-- 插入默认设置
INSERT IGNORE INTO `flarum_settings` (`key`, `value`) VALUES
('version', '1.8.0'),
('database_version', '1.8.0'),
('forum_title', 'Flarum'),
('forum_description', ''),
('default_locale', 'en'),
('default_route', '/all'),
('theme_primary_color', '#4D698E'),
('theme_secondary_color', '#4D698E'),
('theme_dark_mode', '0'),
('theme_colored_header', '0'),
('custom_less', ''),
('display_name_driver', 'username'),
('slug_driver_Flarum-Discussion-Discussion', 'default'),
('slug_driver_Flarum-User-User', 'default'),
('mail_driver', 'mail'),
('mail_host', ''),
('mail_port', '587'),
('mail_username', ''),
('mail_password', ''),
('mail_encryption', ''),
('mail_from', ''),
('welcome_title', 'Welcome to Flarum'),
('welcome_message', 'This is beta software and should not be used in production.'),
('allow_post_editing', 'reply'),
('allow_hide_own_posts', 'reply'),
('allow_renaming', '10'),
('allow_sign_up', '1'),
('extensions_enabled', '[]');
EOF

# 创建启动脚本
RUN cat > /start.sh << 'EOF'
#!/bin/sh
set -e

# 设置默认端口
DB_PORT=${DB_PORT:-3306}

echo "=== NexusK Flarum 正在启动... ==="
echo "数据库主机: ${DB_HOST}"
echo "数据库端口: ${DB_PORT}"

# 等待数据库连接
echo "正在等待 MySQL 数据库连接..."
timeout=180
counter=0
while ! nc -z "${DB_HOST}" "${DB_PORT}"; do
    counter=$((counter + 1))
    if [ ${counter} -ge ${timeout} ]; then
        echo "错误：数据库连接超时！请检查数据库状态和网络设置。"
        exit 1
    fi
    echo "数据库尚未就绪，5秒后重试..."
    sleep 5
done
echo "数据库连接成功！"

# 检查是否已安装
if [ ! -f "/flarum/app/config.php" ]; then
    echo "检测到首次运行，正在初始化数据库和安装 Flarum..."

    # 创建配置文件
    cat > /flarum/app/config.php << CONFIG_EOF
<?php return array (
  'debug' => false,
  'database' =>
  array (
    'driver' => 'mysql',
    'host' => '${DB_HOST}',
    'port' => ${DB_PORT},
    'database' => '${DB_NAME}',
    'username' => '${DB_USER}',
    'password' => '${DB_PASS}',
    'charset' => 'utf8mb4',
    'collation' => 'utf8mb4_unicode_ci',
    'prefix' => 'flarum_',
    'strict' => false,
    'engine' => 'InnoDB',
    'prefix_indexes' => true,
  ),
  'url' => '${FORUM_URL}',
  'paths' =>
  array (
    'api' => 'api',
    'admin' => 'admin',
  ),
);
CONFIG_EOF

    echo "config.php 创建成功。"

    # 手动初始化数据库
    echo "正在初始化数据库表..."
    mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" < /init_database.sql

    if [ $? -eq 0 ]; then
        echo "数据库表创建成功！"
    else
        echo "数据库表创建失败！"
        exit 1
    fi

    # 创建管理员用户
    echo "正在创建管理员用户..."
    ADMIN_PASS_HASH=$(php -r "echo password_hash('${FLARUM_ADMIN_PASS}', PASSWORD_DEFAULT);")
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')

    mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" << ADMIN_SQL
INSERT INTO flarum_users (username, email, is_email_confirmed, password, joined_at, last_seen_at)
VALUES ('${FLARUM_ADMIN_USER}', '${FLARUM_ADMIN_MAIL}', 1, '${ADMIN_PASS_HASH}', '${CURRENT_TIME}', '${CURRENT_TIME}');

INSERT INTO flarum_group_user (user_id, group_id) VALUES (1, 1);
INSERT INTO flarum_group_user (user_id, group_id) VALUES (1, 3);

UPDATE flarum_settings SET value = '${FLARUM_TITLE}' WHERE \`key\` = 'forum_title';
ADMIN_SQL

    if [ $? -eq 0 ]; then
        echo "管理员用户创建成功！"
        echo "安装完成！"
    else
        echo "管理员用户创建失败！"
        exit 1
    fi
else
    echo "检测到已有配置文件，跳过安装步骤。"
fi

# 清理缓存
echo "正在清理缓存..."
php flarum cache:clear

# 启动服务
echo "启动 Flarum 服务..."
exec php flarum serve --host=0.0.0.0 --port=8888
EOF

# 设置脚本权限
RUN chmod +x /start.sh

# 使用脚本启动
CMD ["/start.sh"]