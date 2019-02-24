#!/usr/bin/env bash
# Filename: install-adblocking-hosts
# Description: Script to automate building an adblocking hosts file
# Source: https://github.com/thuandt/dotfiles/blob/master/bin/install-adblocking-hosts
# and: https://github.com/ObliviousGmn/Dotfiles/blob/master/Scripts/Hostupd

# Need Root access
if [[ $EUID -ne 0 ]]; then
    echo
    echo "  Nah, Come on bro, Run on Root.." 1>&2
    echo
    exit 1
fi

# Perform work in temporary files
temphosts=$(mktemp)
systemhosts="/etc/hosts"
lastupdate=$(date)

# Backup hosts file
cp /etc/hosts /etc/hosts.bak

# Obtain various hosts files and merge into one
echo "Downloading ad-blocking hosts files..."
wget -q -O - "http://adaway.org/hosts.txt" >> $temphosts
wget -q -O - "http://winhelp2002.mvps.org/hosts.txt" >> $temphosts
wget -q -O - "http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext" >> $temphosts
wget -q -O - "http://www.malwaredomainlist.com/hostslist/hosts.txt" >> $temphosts
wget -q -O - "http://someonewhocares.org/hosts/zero/hosts" >> $temphosts

# Processing hosts file:
# 1. Remove MS-DOS carriage returns
# 2. Replace 127.0.0.1 with 0.0.0.0 because then we don't have to wait for the
#    resolver to fail
# 3. Delete all lines that don't begin with 0.0.0.0
# 4. Delete any lines containing the word localhost because we'll obtain that
#    from the original hosts file
# 5. Delete any comments on lines
# 5. Convert tabs to spaces
# 6. Remove extra spaces
echo "Parsing and merging hosts files..."
sed -i -e 's/\r//' -e 's/127.0.0.1/0.0.0.0/' -e '/^0.0.0.0/!d' -e '/localhost/d' -e 's/#.*$//' -e 's/\t/ /g' -e 's/  */ /g' $temphosts

# Combine system hosts with adblocks
echo "Merging with original system hosts..."
# Delete all line from mark line (old data)
sed -i '/There is no place like 127.0.0.1/,$d' $systemhosts
# Add new line for next update
echo "# There is no place like 127.0.0.1" >> $systemhosts
echo "# Last update at $lastupdate" >> $systemhosts

# Remove duplicate using sort and add them to system hosts file
sort -u $temphosts >> $systemhosts

