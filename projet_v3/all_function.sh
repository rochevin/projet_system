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
	eval exec "sqlite3 ${db_name} < ${modele_db}" || echo "Impossible de créer la base de données ${db_name}. \n Créer la base manuellement avec le modele disponible : ${modele_db}"
}

function remove_last_char {
	echo $1 | sed 's/.\{1\}$//g'
}

function replace {
	echo $1 | tr "${2}" "${3}"
}