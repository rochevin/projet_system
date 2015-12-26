#! /bin/bash

#Liste des fonctions

function launch {
	if [[ ! -x $1 ]]; then
			chmod +x $1
		fi
		./$1
}

function remove_last_char {
	echo $1 | sed 's/.\{1\}$//g'
}


function get_id {
	echo $1 | cut -f1 -d"|"
}

#print all field except the first (id) with specific separator
function print_values {
	echo $1 | cut -d"${2}" -f2- 
}

function format_for_sql {
	echo $1 | awk -F "|" '{out = "\""$1"\"";for(i=2;i<=NF;i++){out=out",\""$i"\""};print out}'
}

function get_value {
	case $2 in
		strats*) sqlite3 ${1} "PRAGMA foreign_keys = ON;SELECT strats.id,users.name,users.first_name,users.mail,rapps.file_name,rapps.local_path,rapps.dist_path,strats.periodicity,strats.date FROM ${2} INNER JOIN users ON users.id = strats.id_user INNER JOIN rapps ON rapps.id = strats.id_rapp;";;
		*) sqlite3 ${1} "PRAGMA foreign_keys = ON;SELECT * FROM ${2};";;
	esac
}

function add_value {
	sqlite3 ${1} "PRAGMA foreign_keys = ON;INSERT INTO ${2} VALUES (${3});"
}

function rm_value {
	sqlite3 ${1} "PRAGMA foreign_keys = ON;DELETE FROM ${2} WHERE id=${3};"
}

function mv_value {
	rm_value ${1} ${2} ${3} 
	add_value ${1} ${2} ${4}
}

function default_function {
	###Déclaration des variables globales
	db_name=$1
	launcher=$2
	table_name=$3
	name=$4
	
	case $name in
		utilisateur*) 
			columns="--column=\"Id:HD\" --column=\"Nom:TEXT\" --column=\"Prénom:TEXT\" --column=\"Adresse mail:TEXT\""
			fields="--field=\"Nom:\" --field=\"Prénom\" --field=\"Adresse mail :\""
			;;
		rappatriement*) 
			columns="--column=\"Id:HD\" --column=\"Nom du fichier:TEXT\" --column=\"Emplacement local:TEXT\" --column=\"emplacement distant:TEXT\""
			fields="--field=\"Nom du fichier :\" --field=\"Emplacement local\" --field=\"Emplacement distant :\""
			;;
		*) exit 1 ;;        
	esac


	###Récupération des valeurs dans la base de données
	data=$(get_value ${db_name} ${table_name})
	###Affichage

	if [[ -n $data ]]; then

		file_data=$( echo $data| tr "|" " ")
		action=$(eval exec "yad --list --editable --width 500 --height 300 --center --button=\"gtk-add:10\" --button=\"gtk-edit:20\" --button=\"gtk-delete:30\" --button=\"Acceuil:0\" --button=\"gtk-close:1\" --title=\"Gestion des ${name}s\" ${columns} ${file_data}")
		rep=$?

		#Si on appuie sur le bouton close, on quitte le programme
		[[ $rep -eq 1 ]] && exit 0
		##Sinon on peut executer le code


		##Ajout rappatriement
		if [[ $rep -eq 10 ]]; then
			value=$(eval exec "yad --form --title \"Ajout d'un ${name}\" --center --button=\"gtk-ok:0\" --button=\"gtk-close:1\" ${fields}")
			rep=$?
			#Si on appuie sur le bouton close, on quitte le programme
			[[ $rep -eq 1 ]] && exit 0
			if [[ -n $value ]]; then
				add_value $db_name $table_name "NULL,"$(format_for_sql $(remove_last_char $value))
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

}

function strat_function {

	###Déclaration des variables globales
	db_name=$1
	launcher=$2
	table_name=$3
	name=$4
	columns=$5
	

	###Récupération des valeurs dans la base de données
	data=$(get_value ${db_name} ${table_name})
	###Affichage

	if [[ -n $data ]]; then

		file_data=$( echo $data| tr "|" " ")
		action=$(eval exec "yad --list --editable --width 500 --height 300 --center --button=\"gtk-add:10\" --button=\"gtk-edit:20\" --button=\"gtk-delete:30\" --button=\"Acceuil:0\" --button=\"gtk-close:1\" --title=\"Gestion des ${name}s\" --column=\"Id:HD\" --column=\"Nom:TEXT\" --column=\"Prénom:TEXT\" --column=\"Adresse mail:TEXT\" --column=\"Nom du fichier:TEXT\" --column=\"Emplacement local:TEXT\" --column=\"emplacement distant:TEXT\" --column=\"Periodicité:TEXT\" --column=\"Date:TEXT\" ${file_data}")
		rep=$?

		#Si on appuie sur le bouton close, on quitte le programme
		[[ $rep -eq 1 ]] && exit 0
		##Sinon on peut executer le code


		##Ajout rappatriement
		if [[ $rep -eq 10 ]]; then
			add_for_strat $db_name
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
		add_for_strat $db_name
	fi

}


function add_for_strat {
	user_value=$(get_value ${1} "users")
	user_value=$(echo $user_value | tr "|" " ")
	user_info=$(yad --width 300 --list --title "Sélectionner un utilisateur" --width 500 --height 300 --center --button="gtk-ok:0" --button="gtk-close:1" --column="Id:HD" --column="Nom:TEXT" --column="Prénom:TEXT" --column="Adresse mail:TEXT" $user_value)
	rapp_value=$(get_value ${1} "rapps")
	rapp_value=$(echo $rapp_value | tr "|" " ")
	rapp_info=$(yad --width 300 --list --title "Sélectionner un rappatriement" --width 500 --height 300 --center --button="gtk-ok:0" --button="gtk-close:1" --column="Id:HD" --column="Nom du fichier:TEXT" --column="Emplacement local:TEXT" --column="emplacement distant:TEXT" $rapp_value)
	periode=$(yad --width 600 --entry --title "Périodicité" --center --button="gtk-ok:0" --button="gtk-close:1" --text "Periodicité :" --entry-text "Journalier" "Hebdomadaire" "Mensuel")
	declare -A days=( ["lun."]="mon" ["mar."]="tue" ["mer."]="wed" ["jeu."]="thur" ["ven."]="fri" ["sam."]="sat" ["dim."]="sun")
	case $periode in
		Hebdomadaire*)date=${days[$(date -d @$(yad --calendar --title "Date" --center --button="gtk-ok:0" --button="gtk-close:1" --date-format='%s') +%a)]};;
		Mensuel*)date=$(yad --calendar --title "Date" --center --button="gtk-ok:0" --button="gtk-close:1" --date-format='%F'));;
		*) date="NULL";;
	esac
}

function main {

	file_gestion="gestion.sh"
	db_name="gestion.db"

	action=$(yad --width 300 --entry --title "Planificateur de tâches" --center --button="gtk-ok:0" --button="gtk-close:1" --text "Actions :" --entry-text "Gestion utilisateurs" "Gestion rappatriements" "Gestion stratégies" "Générer rapport")
	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0
	##Sinon on peut executer le code
	action=$(echo $action | cut -f2 -d" ")

	case $action in
	    utilisateurs*) default_function ${db_name} ${0##*/} "users" "utilisateur";;
	    rappatriements*) default_function ${db_name} ${0##*/} "rapps" "rappatriement";;
	    stratégies*) strat_function ${db_name} ${0##*/};;
	    rapport*) report_function ${db_name} ${0##*/};;
	    *) exit 1 ;;        
	esac

}

#On lance la fonction main

main