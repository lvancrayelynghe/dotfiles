# Description: ....

PROJECT_PATH=""
PROJECT_DB=""
PROJECT_SQL=""

### DO NOT CHANGE ##############################

cd "$PROJECT_PATH"

# Go in project home
alias home="cd ${PROJECT_PATH}"

# mysql alias with dbname inserted
alias mysql="mysql ${PROJECT_DB}"
# mysqldump alias with dbname inserted
alias mysqldump="mysqldump --opt ${PROJECT_DB}"

# Dump the database to sql file
alias dumpdb="mysqldump > ${PROJECT_SQL}"
# Restore the database using the sql file
alias restoredb="mysql < ${PROJECT_SQL}"

