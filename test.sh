#!/bin/bash

# ================= 配置信息 =================

# 数据库用户名
DB_USER="root"

# 数据库密码 (建议不要直接写在脚本里，可以使用 .my.cnf 配置文件，这里为了演示方便写出)
DB_PASS="your_password"

# 要备份的数据库名 (如果要备份所有数据库，使用 --all-databases 替换下方的 $DB_NAME)
DB_NAME="your_database_name"

# 备份文件存放目录
BACKUP_DIR="/var/backups/mysql"

# 备份文件命名格式 (例如: mysql_backup_20231027_153020.sql)
DATE=$(date +%Y%m%d_%H%M%S)
FILE_NAME="${DB_NAME}_backup_${DATE}.sql"

# 保留最近多少天的备份 (天数)
RETENTION_DAYS=7

# ===========================================

# 判断备份目录是否存在，不存在则创建
if [ ! -d "$BACKUP_DIR" ]; then
  mkdir -p "$BACKUP_DIR"
  echo "创建备份目录: $BACKUP_DIR"
fi

echo "开始备份数据库: $DB_NAME ..."

# 1. 执行备份命令
# 使用 mysqldump 导出数据
# 注意: -u 用户名, -p密码, -h 主机(默认localhost)
mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/$FILE_NAME"

# 判断备份是否成功
if [ $? -eq 0 ]; then
    echo "数据库备份成功: $BACKUP_DIR/$FILE_NAME"
    
    # 2. 压缩备份文件 (可选，但推荐)
    echo "正在压缩备份文件..."
    tar -czf "$BACKUP_DIR/$FILE_NAME.tar.gz" -C "$BACKUP_DIR" "$FILE_NAME"
    
    # 压缩成功后，删除原始的 .sql 文件，只保留 .tar.gz
    rm -f "$BACKUP_DIR/$FILE_NAME"
    echo "压缩完成，已删除原始 SQL 文件。"
    
    # 3. 删除旧备份
    echo "正在查找 $RETENTION_DAYS 天前的旧备份..."
    # find 命令查找 .tar.gz 结尾的文件，且修改时间超过 +7 天，并执行删除
    find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +$RETENTION_DAYS -exec rm -f {} \;
    
    if [ $? -eq 0 ]; then # 如果（上一条命令的退出状态码）等于（0）
        echo "旧备份清理完成。"
    else
        echo "清理旧备份时出错。"
    fi

else
    echo "数据库备份失败！请检查用户名、密码或数据库连接。"
    exit 1
fi

echo "备份任务结束。"
