# Docker aliases and helpers, shared by bash AND zsh. Sourced by
# shell/aliases.sh. Keep POSIX-friendly: no zsh-only syntax.
#
# Naming: do* wraps plain docker, dc* wraps docker compose. The helper
# functions taking an argument check it: called bare, docker would otherwise
# complain about an empty container name.

# Docker
alias doi='docker images'
alias dov='docker volume'
alias doe='docker exec'
alias dok='docker kill'
alias dops='docker ps'
alias dopsa='docker ps -a' ## including stopped containers
alias dorm='docker rm'
alias dormf='docker rm -f'
alias dormi='docker rmi'
alias dosa='docker start'
alias doso='docker stop'
alias dorestart='docker restart'
alias dol='docker logs'
alias dolf='docker logs -f'
alias dopl='docker pull'
alias dodf='docker system df' ## disk used by images, containers, volumes
alias docker-clear='docker system prune -f'
alias docker-clear-prune='docker system prune -f && docker image prune -af'

# Docker compose
alias da='docker compose exec php php artisan'
alias dc='docker compose'
alias dcr='docker compose run'
alias dcb='docker compose build'
alias dcbf='docker compose build --force-rm --no-cache'
alias dcu='docker compose up'
alias dcup='docker compose up'
alias dcud='docker compose up -d' ## detached
alias dcub='docker compose up -d --build' ## detached, rebuilding first
alias dcd='docker compose down'
alias dcdv='docker compose down -v' ## also drops the volumes
alias dce='docker compose exec'
alias dphp='docker compose exec php php'
alias dcsa='docker compose start'
alias dcso='docker compose stop'
alias dcrs='docker compose restart'
alias dcrm='docker compose rm'
alias dcl='docker compose logs -f'
alias dcps='docker compose ps'

# Shell into a container, preferring bash and falling back to sh
dsh() {
    [ -n "$1" ] || { echo 'usage: dsh <container>' >&2; return 2; }
    docker exec -it "$1" bash 2>/dev/null || docker exec -it "$1" sh
}

# Shell into a compose service, preferring bash and falling back to sh
dcsh() {
    [ -n "$1" ] || { echo 'usage: dcsh <service>' >&2; return 2; }
    docker compose exec "$1" bash 2>/dev/null || docker compose exec "$1" sh
}

# Follow one service's logs, last N lines (100 by default)
dclog() {
    [ -n "$1" ] || { echo 'usage: dclog <service> [lines]' >&2; return 2; }
    docker compose logs -f --tail "${2:-100}" "$1"
}

# Rebuild and restart a single service, leaving its dependencies alone
dcservice() {
    [ -n "$1" ] || { echo 'usage: dcservice <service>' >&2; return 2; }
    docker compose up -d --build --no-deps "$1"
}

# Tear the stack down with its volumes and orphans, then rebuild it
dcreset() {
    docker compose down -v --remove-orphans && docker compose up -d --build
}

# A container's IP addresses, one per attached network
dip() {
    [ -n "$1" ] || { echo 'usage: dip <container>' >&2; return 2; }
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' "$1"
}

# One-shot resource usage table (no live refresh)
dstats() {
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
}

# Published ports: every container, or just the one given
dports() {
    if [ -z "$1" ]; then
        docker ps --format "{{.Names}}\t{{.Ports}}"
    else
        docker port "$1"
    fi
}

# Prune containers, images, networks and build cache, then report disk use
dclean() {
    docker container prune -f && docker image prune -f \
        && docker network prune -f && docker builder prune -f \
        && docker system df
}
