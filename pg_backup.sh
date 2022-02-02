#!/bin/bash

set -e

while getopts h:p:d:P:u:s:t:a:D: opt; do
        case ${opt} in
                h) HOST=${OPTARG} ;;
                p) PORT=${OPTARG} ;;
                d) DATABASE=${OPTARG} ;;
                P) PASSWORD=${OPTARG} ;;
                u) USERNAME=${OPTARG} ;;
                s) DB_SCHEMA=${OPTARG} ;;
                t) DB_TABLES=${OPTARG} ;;
		            a) AGE=${OPTARG} ;;
                D) DESTINATION=${OPTARG} ;;
                *)
                        echo 'Error in command line parsing' >&2
                        exit 1
        esac
done

shift "$(( OPTIND - 1 ))"

if [ -z ${HOST} ] || [ -z ${PORT} ]  || [ -z ${DATABASE} ] || [ -z ${PASSWORD} ] || [ -z ${USERNAME} ] || [ -z ${DB_SCHEMA} ] || [ -z ${DB_TABLES} ] || [ -z ${AGE} ] || [ -z ${DESTINATION} ]; then
        echo "Usage:" >&2
        echo -e "\t $0"
        echo -e "\t\t -h <The host of postgres server. Like: localhost>" >&2
        echo -e "\t\t -p <The port of postgres server. Like: 5432>" >&2
        echo -e "\t\t -d <The database name. Like: postgres>" >&2
        echo -e "\t\t -P <The password of postgres server. Like: mysecretpassword>" >&2
        echo -e "\t\t -u <The username of postgres server. Like: username>" >&2
        echo -e "\t\t -s <The DB schema to use. Like: public>" >&2
        echo -e "\t\t -t <The tables to use. Like: table1,table2,table3>" >&2
        echo -e "\t\t -a <The age by days. Like: 182>" >&2
        echo -e "\t\t -D <The destination to save backup file. Like: /tmp/backup>" >&2
        exit 1
fi

#Add comma to be able to add schema name to table names properly
DB_TABLES=","$DB_TABLES
# Cast tables to array
DB_TABLES_ARRAY=($(echo "$DB_TABLES" | tr ',' '\n'))

#Calculate age date
AGE_DATE=`date -d "-${AGE} days" +%d-%m-%Y`
echo $AGE_DATE
BACKUP_DATE=`date +%d-%m-%Y`

export PGPASSWORD=$PASSWORD

#echo "pg_dump --username=$USERNAME --host=$HOST --port=$PORT $DATABASE --inserts --column-inserts --table=${DB_TABLES//,/ DB_SCHEMA.}  > $DESTINATION/$backup_date.sql"

for table in "${DB_TABLES_ARRAY[@]}"
do
    #Backup data from particular table before given date to the destination
    echo "Copying records from " $table " before " $AGE_DATE
    psql --username=$USERNAME --host=$HOST --port=$PORT $DATABASE -c "COPY (SELECT * FROM ${DB_SCHEMA}.${table} where created_at<'${AGE_DATE}'::DATE) TO STDOUT;" > $DESTINATION/${table}_${BACKUP_DATE}.sql
    #Delete records from particular table before given date
#    echo "Deleting records from " $table " before " $AGE_DATE
    psql --username=$USERNAME --host=$HOST --port=$PORT $DATABASE -c "DELETE FROM ${DB_SCHEMA}.${table} where created_at<'${AGE_DATE}'::DATE;"
done

unset PGPASSWORD

