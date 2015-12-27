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
	id=$(get_id $3)
	rm_value ${1} ${2} ${id}
	if [ "$2" = "strats"]; then
		add_strat ${1} ${id}
	else
		value=$(remove_last_char $3)
		value=$(print_values $value "|")
		value=$(format_for_sql $value)
		add_value ${1} ${2} ${id}","${value}
	fi
}



function add_user {
	value=$(yad --form --title "Ajout d'un utilisateur" --center --button="gtk-ok:0" --button="gtk-close:1" --field="Nom:" --field="Prénom" --field="Adresse mail :")
	rep=$?
	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0
	if [[ -n $value ]]; then
		add_value $1 "users" "NULL,"$(format_for_sql $(remove_last_char $value))
	fi
}

function add_rapp {
	value=$(yad --form --title "Ajout d'un rappatriement" --center --button="gtk-ok:0" --button="gtk-close:1" --field="Nom du fichier :" --field="Emplacement local" --field="Emplacement distant :")
	rep=$?
	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0
	if [[ -n $value ]]; then
		add_value $1 "rapps" "NULL,"$(format_for_sql $(remove_last_char $value))
	fi
}


function add_strat {

	user_list=$(get_value $1 "users")
	user_list=$(echo $user_list | tr " " "!")
	user_list=$(echo $user_list | tr "|" " ")

	rapp_list=$(get_value $1 "rapps")
	rapp_list=$(echo $rapp_list | tr " " "!")
	rapp_list=$(echo $rapp_list | tr "|" " ")

	period_list="Journalier!Hebdomadaire!Mensuel"


	result=$(yad --width 500 --height 200 --center --form --separator=':' --field="Utilisateur::cb" "$user_list" --field="Rappatriement::cb" "$rapp_list" --field="Périodicité::cb" "$period_list")

	user=$(echo $result | cut -f1 -d":")
	rapp=$(echo $result | cut -f2 -d":")
	periodicite=$(echo $result | cut -f3 -d":")
    user_id=$(echo $user | cut -f1 -d" ")
    rapp_id=$(echo $rapp | cut -f1 -d" ")


	[[ $rep -eq 1 ]] && exit 0

	declare -A days=( ["lun."]="mon" ["mar."]="tue" ["mer."]="wed" ["jeu."]="thur" ["ven."]="fri" ["sam."]="sat" ["dim."]="sun")
	
	case $periodicite in
		Hebdomadaire*)
			date=${days[$(date -d @$(yad --calendar --title "Date" --center --button="gtk-ok:0" --button="gtk-close:1" --date-format='%s') +%a)]}
				;;
		Mensuel*)
			date=$(yad --calendar --title "Date" --center --button="gtk-ok:0" --button="gtk-close:1" --date-format='%F')
				;;
		*)
			date="NULL"
				;;
	esac
	if [[ -n $2 ]]; then
		strat_values=$2",\""$user_id"\",\""$rapp_id"\",\""$periodicite"\",\""$date"\""
	else 
		strat_values="NULL,\""$user_id"\",\""$rapp_id"\",\""$periodicite"\",\""$date"\""
	fi
	add_value $db_name $table_name $strat_values
}
function main {

	launcher=${0##*/}
	db_name="gestion.db"
	KEY="12345"

	user_file=$(mktemp --tmpdir tab1.XXXXXXXX)
	rapp_file=$(mktemp --tmpdir tab2.XXXXXXXX)
	strat_file=$(mktemp --tmpdir tab3.XXXXXXXX)

	file_gestion="gestion.sh"
	db_name="gestion.db"

	user_data=$(get_value ${db_name} "users")
	user_data=$( echo $user_data| tr "|" " ")

	yad --plug=$KEY --tabnum=1 --list --editable --multiple --regex-search --column="Id:HD" --column="Nom:TEXT" --column="Prénom:TEXT" --column="Adresse mail:TEXT" ${user_data} > $user_file &

	rapp_data=$(get_value ${db_name} "rapps")
	rapp_data=$( echo $rapp_data| tr "|" " ")

	yad --plug=$KEY --tabnum=2 --list --editable --multiple --regex-search --column="Id:HD" --column="Nom du fichier:TEXT" --column="Emplacement local:TEXT" --column="emplacement distant:TEXT" ${rapp_data} > $rapp_file &

	strat_data=$(get_value ${db_name} "strats")
	strat_data=$( echo $strat_data| tr "|" " ")

	yad --plug=$KEY --tabnum=3 --list --editable --multiple --column="Id:HD" --column="Nom:TEXT" --column="Prénom:TEXT" --column="Adresse mail:TEXT" --column="Nom du fichier:TEXT" --column="Emplacement local:TEXT" --column="emplacement distant:TEXT" --column="Periodicité:TEXT" --column="Date:TEXT" ${strat_data} > $strat_file &


	yad --notebook --key=$KEY --tab="Utilisateurs" --tab="rappatriements" --tab="Stratégies" --width 700 --height 500 --center --button="gtk-add:10" --button="gtk-edit:20" --button="gtk-delete:30" --button="gtk-close:1" --title="Gestion automatisée des rappatriements" --image=gnome-icon-theme --image-on-top --text="Sélections des données :"
	rep=$?

	user=$(cat $user_file)
	rapp=$(cat $rapp_file)
	strat=$(cat $strat_file)

	rm -f $user_file $strat_file $rapp_file

	[[ $rep -eq 1 ]] && exit 0

	if [[ $rep -eq 10 ]]; then

		action=$(yad --width 300 --entry --title "Ajouter des informations" --center --button="gtk-ok:0" --button="gtk-close:1" --text "Ajout :" --entry-text "Utilisateurs" "Rappatriements" "Stratégies")
		rep=$?
		#Si on appuie sur le bouton close, on quitte le programme
		[[ $rep -eq 1 ]] && exit 0
		##Sinon on peut executer le code

		case $action in
		    Utilisateurs*) add_user $db_name;;
		    Rappatriements*) add_rapp $db_name;;
		    Stratégies*) add_strat $db_name;;
		    *) exit 1 ;;        
		esac

		launch $launcher
	fi

	i=0
	for type in $user $rapp $strat ;do
		case $i in
			0*)table="users";;
			1*)table="rapps";;
			2*)table="strats";;
			*) exit 1 ;;
		esac

		if [[ -n $type ]]; then

			if [[ $rep -eq 20 ]]; then
				mv_value $db_name $table $type
			fi

			if [[ $rep -eq 30 ]]; then
				id=$(get_id $type)
				rm_value $db_name $table $id
			fi

		fi
		i+=1
	done

	launch $launcher
}

#On lance la fonction main

main