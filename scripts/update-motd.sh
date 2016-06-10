#!/usr/bin/env bash

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
purple=$(tput setaf 5)
cyan=$(tput setaf 6)

bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

echo_header() { printf "\n${bold}${purple}==================  %s  ==================${reset}\n" "$@"; }
echo_success() { printf "${green}${bold}» %s${reset}\n" "$@"; }
echo_error() { printf "${red}${bold}» %s${reset}\n" "$@"; }
echo_warning() { printf "${yellow}${bold}» %s${reset}\n" "$@"; }
echo_underline() { printf "${underline}%s${reset}\n" "$@"; }
echo_bold() { printf "${bold}%s${reset}\n" "$@"; }
echo_note() { printf "${underline}${bold}${cyan}Note:${reset} ${cyan}${bold}%s${reset}\n" "$@"; }

# clear motd
printf "" > /etc/motd

# add new content
echo_header "Packages" >> /etc/motd
echo_success "Apache `apache2 -v | grep version`" >> /etc/motd
echo_success "`php -v | grep "PHP 5."`" >> /etc/motd
echo_success "`mysql --version`" >> /etc/motd
echo_success "ElasticSearch `curl http://localhost:9200 2>&1 | grep number | sed 's/    "number" : "//g' | sed 's/",//g'`" >> /etc/motd

# echo_header "Todo" >> /etc/motd
# echo_warning "This that" >> /etc/motd

printf "\n\n" >> /etc/motd

cat /etc/motd
