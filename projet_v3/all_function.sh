#! /bin/bash
function launch {
	if [[ ! -x $1 ]]; then
			chmod +x $1
		fi
		./$1
}

function remove_last_char {
	echo $1 | sed 's/.\{1\}$//g'
}

function replace {
	echo $1 | tr "${2}" "${3}"
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


function display_value {
	case $1 in
		utilisateur*) 
			columns="--column=\"Id:HD\" --column=\"Nom:TEXT\" --column=\"Prénom:TEXT\" --column=\"Adresse mail:TEXT\""
			;;
		rappatriement*) 
			columns="--column=\"Id:HD\" --column=\"Nom du fichier:TEXT\" --column=\"Emplacement local:TEXT\" --column=\"emplacement distant:TEXT\""
			;;
		stratégies*)
			columns="--column=\"Id:HD\" --column=\"Nom:TEXT\" --column=\"Prénom:TEXT\" --column=\"Adresse mail:TEXT\" --column=\"Nom du fichier:TEXT\" --column=\"Emplacement local:TEXT\" --column=\"emplacement distant:TEXT\" --column=\"Periodicité:TEXT\" --column=\"Date:TEXT\""
			;;
		*) exit 1 ;;        
	esac

	eval exec "yad --list --editable --width 500 --height 300 --center --button=\"gtk-add:10\" --button=\"gtk-edit:20\" --button=\"gtk-delete:30\" --button=\"Acceuil:0\" --button=\"gtk-close:1\" --title=\"Gestion des ${1}s\" ${columns} ${2}"
}