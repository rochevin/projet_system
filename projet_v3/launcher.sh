#! /bin/bash


#Liste des fonctions
function mv_value {
	id=$(get_id $3)
	rm_value ${1} ${2} ${id} ""
	if [ $2 = "strats" ]; then
		add_strat ${1}
	else
		value=$(remove_last_char $3)
		value=$(print_values $value "|")
		value=$(format_for_sql $value)
		add_value ${1} ${2} ${id}","${value}
	fi
}



function add_user {
	value=$(yad --form --title "Ajout d'un utilisateur" --center --button="gtk-ok:0" --button="gtk-close:1" --field="Nom :" --field="Prénom :" --field="Adresse mail :")
	rep=$?
	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0
	if [[ -n $value ]]; then
		add_value $1 "users" "NULL,"$(format_for_sql $(remove_last_char $value))
	fi
}

function add_rapp {
	value=$(yad --form --title "Ajout d'un rappatriement" --center --button="gtk-ok:0" --button="gtk-close:1" --field="Nom du fichier :" --field="Emplacement local ::DIR" --field="Emplacement distant :")
	rep=$?
	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0
	if [[ -n $value ]]; then
		add_value $1 "rapps" "NULL,"$(format_for_sql $(remove_last_char $value))
	fi
}


function add_strat {

	cron_shell=$(realpath "exec_cron.sh")

	user_list=$(get_value $1 "users")
	user_list=$(echo $user_list | tr " " "!")
	user_list=$(echo $user_list | tr "|" " ")

	rapp_list=$(get_value $1 "rapps")
	rapp_list=$(echo $rapp_list | tr " " "!")
	rapp_list=$(echo $rapp_list | tr "|" " ")

	period_list="Journalier!Hebdomadaire!Mensuel!Annuel"


	result=$(yad --width 500 --height 200 --center --title="Programmer un téléchargement" --button="gtk-ok:0" --button="gtk-close:1" --form --date-format='%F' --separator=';' --field="Utilisateur::cb" "$user_list" --field="Rappatriement::cb" "$rapp_list" --field="Périodicité::cb" "$period_list" --field="Date::DT" --field="Heure (format HH:mm) :")
	rep=$?
	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0


	user=$(echo $result | cut -f1 -d";")
	user_id=$(echo $user | cut -f1 -d" ")


	rapp=$(echo $result | cut -f2 -d";")
	rapp_id=$(echo $rapp | cut -f1 -d" ")
	rapp_file=$(echo $rapp | cut -f2 -d" ")
	rapp_local=$(echo $rapp | cut -f3 -d" ")
	rapp_dist=$(echo $rapp | cut -f4 -d" ")


	periodicite=$(echo $result | cut -f3 -d";")


	date=$(echo $result | cut -f4 -d";")


	temps=$(echo $result | cut -f5 -d";")
	[[ ! -n $temps ]] && temps="00:00"
	heure=$(echo $temps | cut -f1 -d":")
	min=$(echo $temps | cut -f2 -d":")
    
    




	[[ $rep -eq 1 ]] && exit 0

	
	case $periodicite in
		Hebdomadaire*)
			date=$(date -d ${date} +%w)
			cron_date="${min} ${heure} * * ${date}"
				;;
		Mensuel*)
			date=$(date -d ${date} +%d)
			cron_date="${min} ${heure} ${date} * *"
				;;
		Journalier*)
			date="NULL"
			cron_date="${min} ${heure} * * *"
				;;
		Annuel*)
			date=$(date -d ${date} "+%d %m")
			cron_date="${min} ${heure} ${date} *"
	esac

	

	strat_values=",\""$user_id"\",\""$rapp_id"\",\""$periodicite"\",\""$date"\",\""$temps"\""

	if [[ -n $2 ]]; then
		strat_values=$2$strat_values
		add_value $db_name "strats" $strat_values
	else 
		strat_values="NULL"$strat_values
		last_id=$(sqlite3 ${db_name} "INSERT INTO strats VALUES (${strat_values});SELECT last_insert_rowid();")
		data=$(get_strat_fro_cron ${db_name} ${last_id})
		crontab < <(crontab -l ; echo "${cron_date} bash ${cron_shell} \"${db_name}\" \"${data}\"")
	fi
	


}

function generate_report {
	template=$1
	input=$2
	output=$3
	pandoc -s -S --toc -c ${template}  ${input} -o ${output}
}

function report_interface {
	db_name=$1
	template=$2
	modele=$3
	temp_report=$(mktemp --tmpdir tab4.XXXXXXXX)
	temp_modele=$(mktemp --tmpdir tab5.XXXXXXXX)



	user_list=$(get_value $db_name "users")
	user_list=$(echo $user_list | tr " " "!")
	user_list=$(echo $user_list | tr "|" " ")

	period_list="Toutes!Journalier!Hebdomadaire!Mensuel!Annuel"

	action=$(yad --width 500 --height 200 --center --button="gtk-ok:0" --button="gtk-close:1" --form --separator=';' --field="Utilisateur::cb" "$user_list" --field="Périodicité::cb" "$period_list")
	rep=$?

	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0

	user_info=$(echo $action | cut -f1 -d";")
	period_info=$(echo $action | cut -f2 -d";")

	user_id=$(get_id $user_info)
	name=$(echo $user_info | cut -f2 -d" ")
	first_name=$(echo $user_info | cut -f3 -d" ")
	mail=$(echo $user_info | cut -f4 -d" ")


	query_strat=";"
	query_cron=";"

	if [[ ! $period_info = "Toutes" ]]; then
		result_strat=$(sqlite3 -header ${db_name} "SELECT rapps.file_name,rapps.local_path,rapps.dist_path,strats.periodicity,strats.date,strats.time FROM strats INNER JOIN rapps ON rapps.id = strats.id_rapp WHERE id_user=${user_id} AND periodicity=${period_info};")
		result_cron=$(sqlite3 -header ${db_name} "SELECT rapps.file_name,rapps.local_path,rapps.dist_path,cron_task.periodicity,cron_task.date,cron_task.time,cron_task.date_complete,cron_task.status FROM cron_task INNER JOIN rapps ON rapps.id = cron_task.id_rapp WHERE id_user=${user_id} AND periodicity=${period_info};")
	else
		result_strat=$(sqlite3 -header ${db_name} "SELECT rapps.file_name,rapps.local_path,rapps.dist_path,strats.periodicity,strats.date,strats.time FROM strats INNER JOIN rapps ON rapps.id = strats.id_rapp WHERE id_user=${user_id};")
		result_cron=$(sqlite3 -header ${db_name} "SELECT rapps.file_name,rapps.local_path,rapps.dist_path,cron_task.periodicity,cron_task.date,cron_task.time,cron_task.date_complete,cron_task.status FROM cron_task INNER JOIN rapps ON rapps.id = cron_task.id_rapp WHERE id_user=${user_id};")
	fi

	

	strat_row="#Stratégies programmées\n\n"
	cron_row="#Stratégies terminées\n\n"
	
	i=1
	if [[ -n $result_strat ]]; then

		for row in $result_strat; do
			[[ $i -eq 2 ]] && strat_row+=$(echo $row | awk -F "|" '{out = "|";for(i=1;i<=NF;i++){out=out":-:|"};print out}')  && strat_row+="\n"
			strat_row+=$row"\|\n"
			i=$i+1
		done
		strat_row+=": Stratégies programmées pour ${first_name} ${name}\n"
	else
		strat_row="Aucune stratégie prévue pour ${first_name} ${name}"
	fi
	i=1
	if [[ -n $result_cron ]]; then
		for row in $result_cron; do
			[[ $i -eq 2 ]] && cron_row+=$(echo $row | awk -F "|" '{out = "|";for(i=1;i<=NF;i++){out=out":-:|"};print out}') && cron_row+="\n"
			cron_row+=$row"\|\n"
			i=$i+1
		done
		cron_row+=": Stratégie terminées pour ${first_name} ${name}\n"
	else
		cron_row="Aucune stratégie terminée pour ${first_name} ${name}"
	fi

	cat $modele > $temp_modele
	echo -e $strat_row >> $temp_modele
	echo -e $cron_row >> $temp_modele

	sed -i -e "s%TITRE%Rapport des stratégies pour ${first_name} ${name}%g" $temp_modele
	sed -i -e "s%DATE%$(date +%F)%g" $temp_modele
	sed -i -e "s%UTILISATEUR%${first_name} ${name}%g" $temp_modele
	sed -i -e "s%NAME%${name}%g" $temp_modele
	sed -i -e "s%FIRST%${first_name}%g" $temp_modele
	sed -i -e "s%MAIL_ADRESS%${mail}%g" $temp_modele
	sed -i -e "s%STRAT_CONTENT%${strat_row}%g" $temp_modele
	sed -i -e "s%CRON_CONTENT%${cron_row}%g" $temp_modele



	generate_report $template $temp_modele $temp_report && yad --html --browser --uri="$temp_report" --width 800 --height 800 --center --button="gtk-save:10" --button="gtk-close:1" --title="Rapport des stratégies pour ${first_name} ${name}"
	rep=$?

	report=$(cat $temp_report)
	rm -f $temp_modele $temp_report $strat_write $cron_write



	report_file="Rapport_${first_name}_${name}_$(date +%F).html"



	[[ $rep -eq 10 ]] && echo $report > $report_file && exit 0 && yad --center --image=dialog-info --title="Fichier produit" --text="Le rapport à été enregistré sous le nom $report_file"

	#Si l'utilisateur clique sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0

	
}

function main {

	#Définition des variables
	directory=$(realpath "scripts") #repertoire ou sont stockés les differents fichier essentiels au fonctionnement du script
	launcher=${0##*/} #Nom du script à lancer
	db_name=$directory"/gestion.db" #Nom du fichier contenant la base de données
	modele_db=$directory"/modele_db.txt" #Nom du fichier contenant le modèle de la base de données
	modele_md=$directory"/modele_md.txt" #Nom du fichier contenant le modèle du rapport
	func_script=$directory"/__sql_func__.sh"
	template=$directory"/buttondown.css"

	KEY="12345" #Clé utilisée par yad pour lier les onglets au yad principal

	#On test si le repertoire contenant tous les fichiers existe, sinon, on affiche un message d'erreur et on quitte le programme
	[[ ! -d $directory ]] && yad --center --image=dialog-warning --title="Erreur" --text="${directory} inexistant, impossible de charger les fonctions et données essentielles au programme." && exit 1

	[[ -f $func_script ]] && source $func_script

	#On vérifie que la base de données n'existe pas, si le test renvoie TRUE, on utilise le modèle pour la créer
	[[ ! -f $db_name ]] && sqlite3 $db_name < $modele_db 

	#On créer des fichiers temporaires qui contiendrons les données saisis par l'utilisateur lors de son utilisation de yad
	user_file=$(mktemp --tmpdir tab1.XXXXXXXX)
	rapp_file=$(mktemp --tmpdir tab2.XXXXXXXX)
	strat_file=$(mktemp --tmpdir tab3.XXXXXXXX)


	#On récupère les données des utilisateurs, rappatriements et stratégies en faisant une requête dans la BDD
	##utilisateurs
	user_data=$(get_value ${db_name} "users")
	user_data=$( echo $user_data| tr "|" " ")
	##rappatriements
	rapp_data=$(get_value ${db_name} "rapps")
	rapp_data=$( echo $rapp_data| tr "|" " ")
	##stratégies
	strat_data=$(get_value ${db_name} "strats")
	strat_data=$( echo $strat_data| tr "|" " ")


	#Onglet yad pour les utilisateurs
	yad --plug=$KEY --tabnum=1 --list --editable --multiple --regex-search --column="Id:HD" --column="Nom:TEXT" --column="Prénom:TEXT" --column="Adresse mail:TEXT" ${user_data} > $user_file &

	
	#Onglet yad pour les rappatriements
	yad --plug=$KEY --tabnum=2 --list --editable --multiple --regex-search --column="Id:HD" --column="Nom du fichier:TEXT" --column="Emplacement local:TEXT" --column="emplacement distant:TEXT" ${rapp_data} > $rapp_file &

	
	#Onlet yad pour les stratégies
	yad --plug=$KEY --tabnum=3 --list --editable --multiple --column="Id:HD" --column="Nom:TEXT" --column="Prénom:TEXT" --column="Adresse mail:TEXT" --column="Nom du fichier:TEXT" --column="Emplacement local:TEXT" --column="emplacement distant:TEXT" --column="Periodicité:TEXT" --column="Date:TEXT" --column="Heure:TEXT" ${strat_data} > $strat_file &

	#Yad principal, regroupe les trois onglets utilisateurs,rappatriement et stratégie
	yad --notebook --key=$KEY --tab="Utilisateurs" --tab="Rappatriements" --tab="Stratégies" --width 700 --height 500 --center --button="gtk-add:10" --button="gtk-edit:20" --button="gtk-delete:30" --button="Générer rapport!gtk-dnd:40" --button="gtk-close:1" --title="Gestion automatisée des rappatriements" --image=gnome-icon-theme --image-on-top --text="Sélections des données :"
	rep=$? #On enregistre l'ID du bouton sur lequel l'utilisateur à cliquer 

	#On recupère les données des trois fichiers 
	user=$(cat $user_file)
	rapp=$(cat $rapp_file)
	strat=$(cat $strat_file)
	#Puis on les supprime
	rm -f $user_file $strat_file $rapp_file

	#Si l'utilisateur clique sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0

	#En fonction du bouton sur lequel clique l'utilisateur, on applique differentes procédures
	#rep=10 : Ajout de données (utilisateur, rappatriement, stratégie)
	if [[ $rep -eq 10 ]]; then

		action=$(yad --width 300 --entry --title "Ajouter des informations" --center --button="gtk-ok:0" --button="gtk-close:1" --text "Ajout :" --entry-text "Utilisateurs" "Rappatriements" "Stratégies")
		rep=$?
		#Si on appuie sur le bouton close, on quitte le programme
		[[ $rep -eq 1 ]] && exit 0
		##Sinon on peut executer le code

		#On vérifie quel type de données l'utilisateur veut ajouter et on applique une fonction liée au type
		case $action in
		    Utilisateurs*) add_user $db_name;;
		    Rappatriements*) add_rapp $db_name;;
		    Stratégies*) add_strat $db_name;;
		    *) exit 1 ;;        
		esac
	elif [[ $rep -eq 40 ]]; then
		report_interface ${db_name} ${template} ${modele_md}
	#Si il ne veut pas ajouter ni générer de rapport, on prend en compte les trois types de données
	else
		#user n'est pas vide, c'est que l'utilisateur veut modifier/suprimmer un utilisateur
		if [[ -n $user ]]; then

			#rep=20 : modification d'un utilisateur
			if [[ $rep -eq 20 ]]; then
				mv_value $db_name "users" $user #On renvoit vers la fonction de modification de données
			elif [[ $rep -eq 30 ]]; then
				id=$(get_id $user) #On récupère l'id et on renvoit vers la fonction de suppression de données
				rm_value $db_name "users" $id "PRAGMA foreign_keys = ON;"
			fi
		fi

		if [[ -n $rapp ]]; then

			if [[ $rep -eq 20 ]]; then
				mv_value $db_name "rapps" $rapp
			elif [[ $rep -eq 30 ]]; then
				id=$(get_id $rapp)
				rm_value $db_name "rapps" $id "PRAGMA foreign_keys = ON;"
			fi
		fi

		if [[ -n $strat ]]; then

			if [[ $rep -eq 20 ]]; then
				mv_value $db_name "strats" $strat
			elif [[ $rep -eq 30 ]]; then
				id=$(get_id $strat)
				data=$(get_strat_fro_cron ${db_name} ${id})
				crontab -l | grep -v "${data}" | crontab
				rm_value $db_name "strats" $id "PRAGMA foreign_keys = ON;"

			fi
		fi

		
	fi
	launch $launcher

}

#On lance la fonction main

main