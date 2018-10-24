#!/usr/bin/env bash

echo "Type de projet ?"
echo "1) Vierge"
echo "2) Base Web"
read -n 1 action

echo ""
echo "Nom du projet (défaut au nom du dossier courant) ?"
read project

echo ""
echo "Chemin du projet (défaut au dossier courant) ?"
read project_path

echo ""
echo "Description ?"
read description


if [[ "$project" == "" ]]; then
	project="$(basename $PWD)"
fi
if [[ "$project_path" == "" ]]; then
	project_path="$PWD"
    project_path="${project_path/$DESK_PROJECTS_PATH/\$DESK_PROJECTS_PATH}"
fi

if [ -e $HOME/.desk/desks/$project.sh ]; then
    echo "Le desk existe déjà"
    exit 1
fi


if [[ "$action" == "1" ]]; then
	echo "# Description: $description" > $HOME/.desk/desks/$project.sh
	echo "#" >> $HOME/.desk/desks/$project.sh
	echo "" >> $HOME/.desk/desks/$project.sh
	echo "source \$HOME/.desk/base-project.sh $project_path" >> $HOME/.desk/desks/$project.sh
elif [[ "$action" == "2" ]]; then
	echo ""
	echo ""
	echo "Nom de domaine du projet ?"
	read host

	echo "# Description: $description" > $HOME/.desk/desks/$project.sh
	echo "#" >> $HOME/.desk/desks/$project.sh
	echo "" >> $HOME/.desk/desks/$project.sh
	echo "source \$HOME/.desk/base-project.sh $project_path" >> $HOME/.desk/desks/$project.sh
	echo "source \$HOME/.desk/web-project.sh $project_path $project $project $host" >> $HOME/.desk/desks/$project.sh
fi
