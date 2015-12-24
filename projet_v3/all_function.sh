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

function Create_db {
	if [[ ! -f "${db_name}"]]; then
		eval exec "sqlite3 ${db_name} < ${modele_db}" || echo "Impossible de créer la base de données ${db_name}. \n Créer la base manuellement avec le modele disponible : ${modele_db}"
	fi
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
	echo $1 | awk -F  "${2}" '{$1 = ""; print $0; }'
}

function is_value {
	sqlite3 ${db_name} "SELECT * FROM ${1}"
}

function add_value {
	sqlite3 ${db_name} "INSERT INTO ${1} VALUES (NULL,${2})"
}

function rm_value {
	sqlite3 ${db_name} "DELETE FROM ${1} WHERE id=${2}"
}

function mv_value {
	rm_value ${1} ${2}
	add_value ${1} ${2}
}

# function mv_value {
# 	array=(${2//|/ })
# 	case $1 in
# 		utilisateurs*) sqlite3 ${db_name} "UPDATE ${1} SET name=${array[1]}, first_name=${array[2]}, mail=${array[3]} WHERE id=${array[0]};";;
# 		rappatriements*) sqlite3 ${db_name} "UPDATE ${1} SET file_name=${array[1]}, local_path=${array[2]}, dist_path=${array[3]} WHERE id=${array[0]};";;
# 		stratégies*) sqlite3 ${db_name} "UPDATE ${1} SET id_user=${array[1]}, id_rapp=${array[2]}, periodicity=${array[3]} date=${array[4]} WHERE id=${array[0]};";;
# 		*) exit 1 ;;        
# 	esac
# }
