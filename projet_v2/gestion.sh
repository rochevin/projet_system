#! /bin/bash

##Fonctions
. ./all_function.sh

##Corps du programme
file_name=$1
name=$2
launcher=$3
script_name=${0##*/}


case $name in
	utilisateur*) 
		columns="--column=\"Id:HD\" --column=\"Nom:TEXT\" --column=\"Prénom:TEXT\" --column=\"Adresse mail:TEXT\""
		fields="--field=\"Nom:\" --field=\"Prénom\" --field=\"Adresse mail :\""
		;;
	rappatriement*) 
		columns="--column=\"Id:HD\" --column=\"Nom du fichier:TEXT\" --column=\"Emplacement local:TEXT\" --column=\"emplacement distant:TEXT\""
		fields="--field=\"Nom du fichier :\" --field=\"Emplacement local\" --field=\"Emplacement distant :\""
		;;
	stratégie*) 
		file_name="strat.txt"
		name="stratégies"
		;;
	rapport*) 
		file_name="rapp.txt"
		name="rappatriement"
		;;
	*) exit 1 ;;        
esac


if [ -f $file_name ]; then
	file_data=$(cat $file_name | tr "|" " ")

	action=$(eval exec "yad --list --editable --width 500 --height 300 --center --button=\"Ajouter:0\" --button=\"Modifier:2\" --button=\"Supprimer:3\" --button=\"Acceuil:4\" --button=\"gtk-close:1\" --title=\"Gestion des ${name}s\"" ${columns} ${file_data})
	rep=$?
	

	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0
	##Sinon on peut executer le code


	##Ajout rappatriement
	if [[ $rep -eq 0 ]]; then
		value=$(eval exec "yad --form --title \"Ajout d'un ${name}\" --center --button=\"gtk-ok:0\" --button=\"gtk-close:1\"" ${fields})
		rep=$?
		#Si on appuie sur le bouton close, on quitte le programme
		[[ $rep -eq 1 ]] && exit 0
		Ajout
	elif [[ $rep -eq 2 ]]; then
		Modif
	elif [[ $rep -eq 3 ]]; then
		Supp
	elif [[ $rep -eq 4 ]]; then
		if [[ ! -x $launcher ]]; then
			chmod +x $launcher
		fi
		./$launcher
	fi
else
	value=$(eval exec "yad --form --title \"Ajout d'un ${name}\" --center --button=\"gtk-ok:0\" --button=\"gtk-close:1\" --image=dialog-warning --text=\"Aucun ${name} référencé, \n veuillez en créer un :\"" ${fields})
	rep=$?
	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0
	Ajout $value
fi
