PROJECT_PATH=$1
PROJECT_DB=$2
PROJECT_SQL=$3
PROJECT_HOST=$4


alias dev-http="xdg-open http://${DESK_NAME}.dev/ > /dev/null"   # Open browser on dev server

alias mysql="mysql ${PROJECT_DB}"                 # mysql alias with dbname inserted
alias mysqldump="mysqldump --opt ${PROJECT_DB}"   # mysqldump alias with dbname inserted

alias dumpdb="mysqldump > ${PROJECT_SQL}"   # Dump the database to sql file
alias restoredb="\mysql -e \"DROP DATABASE ${PROJECT_DB}\" &>/dev/null ; \mysql -e \"CREATE DATABASE ${PROJECT_DB}\" ; mysql < ${PROJECT_SQL}"   # Restore the database using the sql file

alias prod-http="xdg-open http://${PROJECT_HOST}/ > /dev/null"                           # Open browser on dev server
alias prod-ftp="filezilla -c 0/${PROJECT_HOST} &"                                        # Open Filezilla on dev server
alias prod-ssh="ssh ${PROJECT_HOST}"                                                     # Open SSH on prod server
alias prod-getdb="ssh ${PROJECT_HOST} \"mysqldump $PRJ_NAME\" > $PRJ_PATH/prod_db.sql"   # Download production database
