#!/bin/bash

# Description: Set up a readonly user for postgresql instance.
# Usage: bash ./set_readonly.sh
# Requirement: Set local pgpass file, or set trust for PRIVILEGES_USER login

# Db connection
DB_HOST="127.0.0.1"
DB_PORT=5432
# User who has privileges to create user and grant privileges
PRIVILEGES_USER="postgres"
# DB_OWNER is the user who actually uses the database, modify it according to the actual situation
DB_OWNER="example_user"

READONLY_USER="readonly"
READONLY_PASS='password'
PG_CMD="psql -h ${DB_HOST} -p ${DB_PORT} -U ${PRIVILEGES_USER}"

# Color define
RED='\033[0;31m'
GREEN='\033[0;32m'
# Reset, no color
RESET='\033[0m'

color_print() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${RESET}"
}

# Test database connection
if ! ${PG_CMD} -c "SELECT 1;" > /dev/null 2>&1; then
    color_print "${RED}" "Failed to connect to PostgreSQL database!!!\n"
    exit 1
else
    color_print "${GREEN}" "Successfully connected to PostgreSQL database.\n"
fi

# Create readonly user
color_print "${GREEN}" "Create ${READONLY_USER} user"
${PG_CMD} -d "postgres" -c "CREATE USER ${READONLY_USER} WITH ENCRYPTED PASSWORD '${READONLY_PASS}' ;"

set -e

DB_LIST=`${PG_CMD} -d "postgres" -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;"`

for db_name in ${DB_LIST};do 
    
    # Grant connect permission to database
    ${PG_CMD} -d ${db_name} -c "GRANT CONNECT ON DATABASE \"${db_name}\" TO ${READONLY_USER};"

    schema_list=`${PG_CMD} -d ${db_name} -t -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT LIKE 'pg_%' AND schema_name <> 'information_schema';"`
    for schema in ${schema_list};do 
        # Grant usage permission to schema
        ${PG_CMD} -d ${db_name} -c "GRANT USAGE ON SCHEMA ${schema} TO ${READONLY_USER};"
        # Grant SELECT permission to existing tables
        ${PG_CMD} -d ${db_name} -c "GRANT SELECT ON ALL TABLES IN SCHEMA ${schema} TO ${READONLY_USER};"

        # Grant SELECT permission to new tables of owner automatically
        # Note: Here we execute for DB_OWNER, that is, the new tables created by DB_OWNER will be automatically authorized, if you need to set it for other users, you need to change the DB_OWNER variable
        ${PG_CMD} -d ${db_name} -c "ALTER DEFAULT PRIVILEGES FOR USER ${DB_OWNER} IN SCHEMA ${schema} GRANT SELECT ON TABLES TO ${READONLY_USER};"

    done
    color_print "${GREEN}" "${db_name} default access permission:"
    ${PG_CMD} -d ${db_name} -c "\ddp"
done
set +e
color_print "${GREEN}" "Permission configuration completed, here is the current database permission:"
${PG_CMD} -d "postgres" -c "\l"
