#Fonction pour rendre un script executable et le lancer
function launch {
	if [[ ! -x $1 ]]; then
			chmod +x $1
		fi
		./$1
}

#Fonction qui retire le dernier élément d'une chaine
function remove_last_char {
	echo $1 | sed 's/.\{1\}$//g'
}

#Fonction qui récupère le premier élément d'une chaine en prenant en compte le séparateur "|"
function get_id {
	echo $1 | cut -f1 -d"|"
}

#Retourne tous les champs sauf le premier
function print_values {
	echo $1 | cut -d"${2}" -f2- 
}


#Fonction qui va formater la chaine au format SQL pour un INSERT
function format_for_sql {
	echo $1 | awk -F "|" '{out = "\""$1"\"";for(i=2;i<=NF;i++){out=out",\""$i"\""};print out}'
}

#Fonction qui récupère les valeurs de la base de données
function get_value {
	case $2 in
		strats*) sqlite3 ${1} "PRAGMA foreign_keys = ON;SELECT strats.id,users.name,users.first_name,users.mail,rapps.file_name,rapps.local_path,rapps.dist_path,strats.periodicity,strats.date,strats.time FROM ${2} INNER JOIN users ON users.id = strats.id_user INNER JOIN rapps ON rapps.id = strats.id_rapp;";;
		*) sqlite3 ${1} "PRAGMA foreign_keys = ON;SELECT * FROM ${2};";;
	esac
}

#Fonction qui récupère les valeurs d'une stratégie nécessaires à l'éxecution du script pour cron
function get_strat_fro_cron {
	sqlite3 $1 "PRAGMA foreign_keys = ON;SELECT rapps.file_name,rapps.local_path,rapps.dist_path,strats.id,strats.id_user,strats.id_rapp,strats.periodicity,strats.date,strats.time FROM strats INNER JOIN users ON users.id = strats.id_user INNER JOIN rapps ON rapps.id = strats.id_rapp WHERE strats.id=$2;"
}


#Fonction qui ajoute une valeur dans la base de données
function add_value {
	sqlite3 ${1} "PRAGMA foreign_keys = ON;INSERT INTO ${2} VALUES (${3});"
}

#Fonction qui suprimme une valeur dans la base de données, et affiche un message d'erreur en cas de contrainte d'integritée
function rm_value {
	sqlite3 ${1} "${4}DELETE FROM ${2} WHERE id=${3};" || yad --center --image=dialog-warning --title="Erreur de supression" --text="Impossible de supprimer l'utilisateur ou le rappatriement lorsqu'il est utilisé par une stratégie."
}
