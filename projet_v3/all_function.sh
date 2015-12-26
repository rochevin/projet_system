#! /bin/bash

function no_ref {
	yad --title="Erreur" --width=300 --center --button="gtk-close" --image=dialog-error --text="Aucun(e) ${file_name}s référencés, vous devez créer un ${file_name} avant cela."
	./$launcher
	exit 1
}

function Ajout {
	value=$(echo $value | sed 's/.\{1\}$//g')

	[ -z $(echo $value | grep  [a-z]) ] && ./$script_name && exit 1

	if [ ! -s "$file_name" ]; then
		if [[ ! -x "$file_name" ]]; then
			chmod +x $file_name
		fi
		rm $file_name
	fi
	if [ -f "$file_name" ]; then
		prev_id=$(tail -1 $file_name | cut -f1 -d"|")
		((prev_id++))
		result="$prev_id|$value"
		if [[ ! -x $file_name ]]; then
			chmod +x $file_name
		fi
		echo $result >> $file_name
	else
		result="1|$value"
		echo $result > $file_name
		if [[ ! -x $file_name ]]; then
			chmod +x $file_name
		fi
	fi
	./$script_name
	exit 0
}


function Modif {
	if [ ! -s "${file_name}" ]; then
		if [[ ! -x "${file_name}" ]]; then
			chmod +x ${file_name}
		fi
		rm ${file_name}
	fi
	if [ -f "${file_name}" ]; then
		id=$(echo $action | cut -f1 -d"|")
		id+="|"
		initial_name=$(grep $id ${file_name})
		new_name=$(echo $action | sed 's/.\{1\}$//g')
		sed -i -e "s/${initial_name}/${new_name}/" ${file_name}
		./${script_name}
		exit 0
	else
		no_ref
	fi
	exit 0
}

function Supp {
	if [ ! -s "$file_name" ]; then
		if [[ ! -x "$file_name" ]]; then
			chmod +x "$file_name"
		fi
		rm $file_name
	fi
	if [ -f "$file_name" ]; then
		value=$(echo $action | sed 's/.\{1\}$//g')
		lign_number_user=$(grep -n "${value}" ${file_name} | cut -f1 -d":")
		sed -i -e "${lign_number_user}d" ${file_name}
		
		if [ ! -s "$file_name" ]; then
			if [[ ! -x "$file_name" ]]; then
				chmod +x $file_name
			fi
			rm $file_name
		fi
		./$script_name
		exit 0
	else
		no_ref
	fi
	exit 0
}

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

# function mv_value {
# 	array=(${2//|/ })
# 	case $1 in
# 		utilisateurs*) sqlite3 ${1} "UPDATE ${1} SET name=${array[1]}, first_name=${array[2]}, mail=${array[3]} WHERE id=${array[0]};";;
# 		rappatriements*) sqlite3 ${1} "UPDATE ${1} SET file_name=${array[1]}, local_path=${array[2]}, dist_path=${array[3]} WHERE id=${array[0]};";;
# 		stratégies*) sqlite3 ${1} "UPDATE ${1} SET id_user=${array[1]}, id_rapp=${array[2]}, periodicity=${array[3]} date=${array[4]} WHERE id=${array[0]};";;
# 		*) exit 1 ;;        
# 	esac
# }
