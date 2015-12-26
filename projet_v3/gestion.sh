#! /bin/bash

##Fonctions
. ./all_function.sh

##Corps du programme
table_name=$1
name=$2
db_name=$3
launcher=$4
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
	stratégies*)
		columns="--column=\"Id:HD\" --column=\"Nom:TEXT\" --column=\"Prénom:TEXT\" --column=\"Adresse mail:TEXT\" --column=\"Nom du fichier:TEXT\" --column=\"Emplacement local:TEXT\" --column=\"emplacement distant:TEXT\" --column=\"Periodicité:TEXT\" --column=\"Date:TEXT\""
		fields=""
		;;
	*) exit 1 ;;        
esac

empty_table=$(get_value ${db_name} ${table_name})
if [[ -n $empty_table ]]; then

	file_data=$( echo $empty_table | tr "|" " ")

	action=$(eval exec "yad --list --editable --width 500 --height 300 --center --button=\"gtk-add:10\" --button=\"gtk-edit:20\" --button=\"gtk-delete:30\" --button=\"Acceuil:0\" --button=\"gtk-close:1\" --title=\"Gestion des ${name}s\"" ${columns} ${file_data})
	rep=$?

	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0
	##Sinon on peut executer le code


	##Ajout rappatriement
	if [[ $rep -eq 10 ]]; then
		if [[ -n $fields ]]; then
			value=$(eval exec "yad --form --title \"Ajout d'un ${name}\" --center --button=\"gtk-ok:0\" --button=\"gtk-close:1\" ${fields}")
			rep=$?
			#Si on appuie sur le bouton close, on quitte le programme
			[[ $rep -eq 1 ]] && exit 0
			add_value $db_name $table_name "NULL,"$(format_for_sql $(remove_last_char $value))
		else
			user_value=$(get_value ${db_name} "users")
			user_info=$(yad --width 300 --entry --title "Sélectionner un utilisateur" --center --button="gtk-ok:0" --button="gtk-close:1" --text "Utilisateurs :" --entry-text $user_value)
			rapp_value=$(get_value ${db_name} "rapps")
			rapp_info=$(yad --width 600 --entry --title "Sélectionner un rappatriement" --center --button="gtk-ok:0" --button="gtk-close:1" --text "Rappatriements :" --entry-text $rapp_value)
			periode=$(yad --width 600 --entry --title "Périodicité" --center --button="gtk-ok:0" --button="gtk-close:1" --text "Periodicité :" --entry-text "Journalier" "Hebdomadaire" "Mensuel")
			date=$(yad --calendar --title "Date" --center --button="gtk-ok:0" --button="gtk-close:1" --date-format='%F')
			
		fi
		
		launch $launcher
	elif [[ $rep -eq 20 ]]; then
		if [[ -n $action ]]; then
			id=$(get_id $action)
			value=$(remove_last_char $action)
			value=$(print_values $value "|")
			value=$(format_for_sql $value)		
			mv_value $db_name $table_name $id $id","$value
		fi
		launch $launcher
	elif [[ $rep -eq 30 ]]; then

		id=$(get_id $action)
		rm_value $db_name $table_name $id
		launch $launcher
	elif [[ $rep -eq 0 ]]; then
		launch $launcher
	fi
else
	value=$(eval exec "yad --form --title \"Ajout d'un ${name}\" --center --button=\"gtk-ok:0\" --button=\"gtk-close:1\" --image=dialog-warning --text=\"Aucun ${name} référencé, \n veuillez en créer un :\" ${fields}")
	rep=$?
	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0
	add_value $db_name $table_name "NULL,"$(format_for_sql $(remove_last_char $value))
	launch $launcher
fi
