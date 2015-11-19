#! /bin/bash

##Fonctions
. ./all_function.sh

##Corps du programme
file_name="users.txt"
name="utilisateur"
launcher="launcher.sh"

if [ -f $file_name ]; then
	file_data=$(cat $file_name | tr "|" " ")


	action=$(yad --list --editable --width 500 --height 300 --center --button="Ajouter:0" --button="Modifier:2" --button="Supprimer:3" --button="Acceuil:4" --button="gtk-close:1" --title="Gestion des ${1}s" \
	--column="Id:HD" --column="Nom:TEXT" --column="Prénom:TEXT" --column="Adresse mail:TEXT" \
	$file_data)
	rep=$?
	

	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0
	##Sinon on peut executer le code


	##Ajout utilisateurs
	if [[ $rep -eq 0 ]]; then
		value=$(yad --form --title "Ajout d'un ${name}" --center --button="gtk-ok:0" --button="gtk-close:1" --field="Nom:" --field="Prénom" --field="Adresse mail :")
		#Si on appuie sur le bouton close, on quitte le programme
		[[ $rep -eq 1 ]] && exit 0
		Ajout $value
	elif [[ $rep -eq 2 ]]; then
		Modif $action $launcher $name
	elif [[ $rep -eq 3 ]]; then
		Supp $action $launcher $name
	elif [[ $rep -eq 4 ]]; then
		if [[ ! -x $launcher ]]; then
			chmod +x $launcher
		fi
		./$launcher
	fi
else
	value=$(yad --form --title "Ajout d'un ${name}" --center --button="gtk-ok:0" --button="gtk-close:1" --image=dialog-warning --text="Aucun ${name} référencé, \n veuillez en créer un :" --field="Nom:" --field="Prénom" --field="Adresse mail :")
	rep=$?
	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0
	Ajout $value
fi