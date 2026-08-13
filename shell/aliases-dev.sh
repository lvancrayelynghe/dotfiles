# Development toolchain aliases (node, PHP, GitHub), shared by bash AND zsh.
# Sourced by shell/aliases.sh. Keep POSIX-friendly: no zsh-only syntax.

# NPM
alias nrw='npm run watch'
alias nrp='npm run prod'
alias nrb='npm run build'

# Composer helpers
alias cu='composer update'
alias cr='composer require'
alias ci='composer install'
alias cda='composer dump-autoload'

# Laravel helpers
alias art='php artisan'
alias mig-install='php artisan migrate:install'
alias mig-seed='php artisan migrate:refresh --seed'

# ngrok
alias ng='ngrok http 80'

# Codespaces
alias cs='gh cs'
alias csc='gh cs create'
alias csd='gh cs delete'
alias csl='gh cs list'
alias csll='gh cs list -o fractory-io'
alias css='gh cs ssh'
alias csstop='gh cs stop -o fractory-io'
