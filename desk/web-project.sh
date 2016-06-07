PROJECT_PATH=$1
PROJECT_DB=$2
PROJECT_SQL=$3
PROJECT_HOST=$4


alias dev-http="xdg-open http://${DESK_NAME}.dev/ > /dev/null"      # Open browser on dev server
alias dev-log="tail -f /var/log/nginx/${DESK_NAME}.dev-error.log"   # Tail nginx error log
alias dev-mysql="mysql ${PROJECT_DB}"                               # mysql alias with dbname inserted
alias dev-mysqldump="mysqldump --opt ${PROJECT_DB}"                 # mysqldump alias with dbname inserted
alias dev-dumpdb="mysqldump --opt ${PROJECT_DB} > ${PROJECT_SQL}"   # Dump the database to sql file
alias dev-restoredb="mysql -e \"DROP DATABASE \\\`${PROJECT_DB}\\\`\" &>/dev/null ; \mysql -e \"CREATE DATABASE \\\`${PROJECT_DB}\\\`\" ; mysql ${PROJECT_DB} < ${PROJECT_SQL}"   # Restore the database using the sql file

alias prd-http="xdg-open http://${PROJECT_HOST}/ > /dev/null"                             # Open browser on prod server
alias prd-ftp="filezilla -c 0/${PROJECT_HOST} &"                                          # Open Filezilla on prod server
alias prd-ssh="ssh ${PROJECT_HOST}"                                                       # Open SSH on prod server
alias prd-getdb="ssh ${PROJECT_HOST} \"mysqldump $PRJ_NAME\" > $PRJ_PATH/sql/prod_db.sql" # Download production database
