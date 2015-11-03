#! /bin/bash

##Fonctions
. ./all_function.sh

##Corps du programme
file_name="users.txt"
name="utilisateur"


if [ -f $file_name ]; then
	Gestion $name
	

	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0
	##Sinon on peut executer le code


	##Ajout utilisateurs
	if [[ $rep -eq 0 ]]; then
		Ajout 1 $name
	elif [[ $rep -eq 2 ]]; then
		Modif
	elif [[ $rep -eq 3 ]]; then
		Supp
	elif [[ $rep -eq 4 ]]; then
		./launcher.sh
	fi
else
	Ajout 0 $name
fi


