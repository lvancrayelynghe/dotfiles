PROJECT_PATH=$1


HISTFILE=$HOME/.cache/zsh-history-desk-${DESK_NAME}  # Use a per project history file

alias home="cd ${PROJECT_PATH}"                      # Go in project home
alias dev-home="cd ${PROJECT_PATH}"                  # Go in project home
alias dev-files="o ${PROJECT_PATH}"                  # Browse development files

cd "$PROJECT_PATH"

# Docker compose helpers
if [[ -f "$PROJECT_PATH/docker-compose.yml" ]]; then
    alias dc="docker-compose"
    alias dce="docker-compose exec"
    alias dcr="docker-compose run"
    alias dcb="docker-compose build"
    alias dcup="docker-compose up"
    alias dcrm="docker-compose rm"
    alias dcsa="docker-compose start"
    alias dcso="docker-compose stop"
    alias dsss="docker-sync-stack start"
    alias dssc="docker-sync-stack clean"
fi

# Symfony helpers (through docker)
if [[ -f "$PROJECT_PATH/docker-compose.yml" && -f "$PROJECT_PATH/symfony.lock" && -f "$PROJECT_PATH/bin/console" ]]; then
    alias sc="docker-compose exec php php bin/console"
    alias sc-make-entity="docker-compose exec php php bin/console make:entity"
    alias sc-make-migration="docker-compose exec php php bin/console make:migration"
    alias sc-doctrine-migrate="docker-compose exec php php bin/console doctrine:migrations:migrate -n"
    alias sc-doctrine-fixtures="docker-compose exec php php bin/console doctrine:fixtures:load -n"
fi

# Laravel helpers (through docker)
if [[ -f "$PROJECT_PATH/docker-compose.yml" && -f "$PROJECT_PATH/artisan" ]]; then
    alias art='docker-compose exec php php artisan'
    alias art-mig-install='docker-compose exec php php artisan migrate:install'
    alias art-mig-seed='docker-compose exec php php artisan migrate:refresh --seed'
fi

# Composer helpers (through docker)
if [[ -f "$PROJECT_PATH/docker-compose.yml" && -f "$PROJECT_PATH/composer.json" ]]; then
    alias cu="docker-compose exec php composer update"
    alias cr="docker-compose exec php composer require"
    alias ci="docker-compose exec php composer install"
    alias cda="docker-compose exec php composer dump-autoload"
    alias cdao="docker-compose exec php composer dump-autoload --optimize --no-dev --classmap-authoritative"
fi
