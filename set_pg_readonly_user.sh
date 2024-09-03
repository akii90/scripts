#!/bin/bash
# Author: Vicen
# Date Created: 2024-04-10
# Last Modified: 2024-09-03
# Description: Set up a readonly user for postgresql instance.
# Usage: bash ./set_readonly.sh

# Requirement:需要配置数据库的连接即可，密码可以配置在.pgpass中，会遍历数据库中的所有库和schema（系统相关的除外）

# 需要设置数据库连接信息
# 密码设置在 .pgpass中,或者配置免密登录
DB_HOST="127.0.0.1"
DB_PORT=5432

# 执行脚本使用的用户,需要足够权限
DB_USER="postgres"
# SVC_USER 是实际业务使用数据库的用户，根据实际情况修改
SVC_USER="xxx"
READONLY_USER="readonly"
READONLY_PASS='password'
PG_CMD="psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER}"

# 测试数据库连接
if ! ${PG_CMD} -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "\e[31mFailed to connect to PostgreSQL database!!!\e[0m \n"
    exit 1
else
    echo -e "\e[32mSuccessfully connected to PostgreSQL database.\e[0m \n"
fi


# 创建只读用户
echo "Create ${READONLY_USER} user"
${PG_CMD} -d "postgres" -c "CREATE USER ${READONLY_USER} WITH ENCRYPTED PASSWORD '${READONLY_PASS}' ;"

set -e

DB_LIST=`${PG_CMD} -d "postgres" -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;"`

for db_name in ${DB_LIST};do 
    
    # 授予连接数据库的权限
    ${PG_CMD} -d ${db_name} -c "GRANT CONNECT ON DATABASE \"${db_name}\" TO ${READONLY_USER};"

    schema_list=`${PG_CMD} -d ${db_name} -t -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT LIKE 'pg_%' AND schema_name <> 'information_schema';"`
    for schema in ${schema_list};do 
        # 授予在特定 schema 使用此用户的权限
        ${PG_CMD} -d ${db_name} -c "GRANT USAGE ON SCHEMA ${schema} TO ${READONLY_USER};"
        # 为现有的所有表赋予 SELECT 权限
        ${PG_CMD} -d ${db_name} -c "GRANT SELECT ON ALL TABLES IN SCHEMA ${schema} TO ${READONLY_USER};"

        # 为新表自动赋予 SELECT 权限
        # 注意：这里我们为 SVC_USER 执行，即为 SVC_USER 创建的新表自动授权，如果需要为其他用户设置，需要更改 SVC_USER 变量
        ${PG_CMD} -d ${db_name} -c "ALTER DEFAULT PRIVILEGES FOR USER ${SVC_USER} IN SCHEMA ${schema} GRANT SELECT ON TABLES TO ${READONLY_USER};"

    done
    echo -e "\n${db_name} 配置的默认访问权限:"
    ${PG_CMD} -d ${db_name} -c "\ddp"
done
set +e
echo -e "\e[32m权限配置完成，以下是当前数据库的权限:\e[0m"
${PG_CMD} -d "postgres" -c "\l"
