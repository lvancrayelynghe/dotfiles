#!/usr/bin/env bash

git filter-branch --env-filter '
OLD_EMAIL="old.email@example.com"
CORRECT_NAME="Luc Vancrayelynghe"
CORRECT_EMAIL="luc.vancrayelynghe@gmail.com"
if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_COMMITTER_NAME="$CORRECT_NAME"
    export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_AUTHOR_NAME="$CORRECT_NAME"
    export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
fi
' --tag-name-filter cat -- --branches --tags

echo ""
echo "Review the new Git history for errors then push with"
echo "  git push --force --tags origin 'refs/heads/*'"

