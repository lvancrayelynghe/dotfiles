# Description: ....

PROJECT_PATH=""
PROJECT_DB="_db"
PROJECT_SQL="${PROJECT_PATH}/sql/${PROJECT_DB}.sql"

### DO NOT CHANGE ##############################

# Use a per project history file
HISTFILE=$HOME/.cache/zsh-history-desk-${DESK_NAME}

# Go in project home
cd "$PROJECT_PATH"

# Go in project home alias
alias home="cd ${PROJECT_PATH}"

# mysql alias with dbname inserted
alias mysql="mysql ${PROJECT_DB}"
# mysqldump alias with dbname inserted
alias mysqldump="mysqldump --opt ${PROJECT_DB}"

# Dump the database to sql file
alias dumpdb="mysqldump > ${PROJECT_SQL}"
# Restore the database using the sql file
alias restoredb="\mysql -e \"DROP DATABASE ${PROJECT_DB}\" &>/dev/null ; \mysql -e \"CREATE DATABASE ${PROJECT_DB}\" ; mysql < ${PROJECT_SQL}"
