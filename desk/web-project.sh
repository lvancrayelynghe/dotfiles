PROJECT_PATH=$1
PROJECT_DB=$2
PROJECT_SQL=$3
PROJECT_HOST=$4


alias dev-http="o http://${DESK_NAME}.dev/"                                                              # Open browser on dev server

alias prd-http="o http://${PROJECT_HOST}/"                                                               # Open browser on prod server
alias prd-ftp="filezilla -c 0/${PROJECT_HOST} &"                                                         # Open Filezilla on prod server
alias prd-ssh="ssh ${PROJECT_HOST}"                                                                      # Open SSH on prod server
alias prd-getdb="ssh ${PROJECT_HOST} \"mysqldump $PRJ_NAME\" > $PRJ_PATH/.docker/db/dumps/$PRJ_NAME.sql" # Download production database
alias prd-update="ssh ${PROJECT_HOST} \"git pull\""                                                      # Update production server
