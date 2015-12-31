#! /bin/bash


#Liste des fonctions

##Fonction qui modifie une valeur dans la base de données
function mv_value {
	id=$(get_id $3) #On récupère l'identifiant
	rm_value ${1} ${2} ${id} "" #On suprimme l'ancienne ligne sans prendre en compte la contrainte des clés étrangères
	#Les opérations diffèrent en fonction de si on veut suprimmer une stratégie ou un autre type de données
	#Puis on recréer la ligne avec les nouvelles valeurs :
	if [ $2 = "strats" ]; then
		add_strat ${1} #On appelle la fonction add_strat qui va créer une nouvelle valeur avec le même identifiant que l'ancienne
	else
		value=$(remove_last_char $3) #On suprimme le dernier caractère "|"
		value=$(print_values $value "|") #On affiche les valeurs sans l'identifiant
		value=$(format_for_sql $value) #On formate la chaine pour qu'elle soit acceptée par sqlite
		add_value ${1} ${2} ${id}","${value} #Puis on appelle la fonction add_value qui va créer une nouvelle valeur avec le même identifiant que l'ancienne
	fi
}


##Fonction qui va gérer l'interface pour ajouter un utilisateur
function add_user {
	value=$(yad --form --title "Ajout d'un utilisateur" --center --button="gtk-ok:0" --button="gtk-close:1" --field="Nom :" --field="Prénom :" --field="Adresse mail :")
	rep=$?
	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0
	if [[ -n $value ]]; then
		add_value $1 "users" "NULL,"$(format_for_sql $(remove_last_char $value)) #On appelle la fonction add_value qui va créer un utilisateur avec l'autoincrementation
	fi
}


##Fonction qui va gérer l'interface pour ajouter un rappatriement
function add_rapp {
	value=$(yad --form --title "Ajout d'un rappatriement" --center --button="gtk-ok:0" --button="gtk-close:1" --field="Nom du fichier :" --field="Emplacement local ::DIR" --field="Emplacement distant :")
	rep=$?
	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0
	if [[ -n $value ]]; then
		add_value $1 "rapps" "NULL,"$(format_for_sql $(remove_last_char $value)) #On appelle la fonction add_value qui va créer un rappatriement avec l'autoincrementation
	fi
}


##Fonction qui va gérer l'interface pour ajouter une stratégie
function add_strat {

	#On recupère le path du script qui va gérer le telechargement du fichier
	cron_shell=$(realpath "scripts/exec_cron.sh")

	#On récupère les utilisateurs
	user_list=$(get_value $1 "users") #Via sqlite avec la fonction get_value
	user_list=$(echo $user_list | tr " " "!") #On remplace les espaces par des ! => séparateur dans yad
	user_list=$(echo $user_list | tr "|" " ") #On remplace les | pour l'affichage par des espaces

	#On récupère les rappatriements
	rapp_list=$(get_value $1 "rapps") #Via sqlite avec la fonction get_value
	rapp_list=$(echo $rapp_list | tr " " "!") #On remplace les espaces par des ! => séparateur dans yad
	rapp_list=$(echo $rapp_list | tr "|" " ") #On remplace les | pour l'affichage par des espaces

	#On définit des periodes de façon fixe
	period_list="Journalier!Hebdomadaire!Mensuel!Annuel"

	#Puis on affiche l'interface
	result=$(yad --width 500 --height 200 --center --title="Programmer un téléchargement" --button="gtk-ok:0" --button="gtk-close:1" --form --date-format='%F' --separator=';' --field="Utilisateur::cb" "$user_list" --field="Rappatriement::cb" "$rapp_list" --field="Périodicité::cb" "$period_list" --field="Date::DT" --field="Heure (format HH:mm) :")
	rep=$?
	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0

	#On récupère l'utilisteur sélectionné
	user=$(echo $result | cut -f1 -d";")
	user_id=$(echo $user | cut -f1 -d" ")

	#On récupère le rappatriement sélectionné
	rapp=$(echo $result | cut -f2 -d";")
	rapp_id=$(echo $rapp | cut -f1 -d" ")
	rapp_file=$(echo $rapp | cut -f2 -d" ")
	rapp_local=$(echo $rapp | cut -f3 -d" ")
	rapp_dist=$(echo $rapp | cut -f4 -d" ")

	#On récupère la période sélectionnée
	periodicite=$(echo $result | cut -f3 -d";")

	#On récupère la valeur du champ date
	date=$(echo $result | cut -f4 -d";")
	[[ ! -n $date ]] && date="2015-01-01" #Si la date ne vaut rien, on assigne le premier jour de l'an
	#On récupère la valeur du champ de l'heure
	temps=$(echo $result | cut -f5 -d";")
	[[ ! -n $temps ]] && temps="00:00" #Si l'heure est vide, on fourni minuit par défaut
	heure=$(echo $temps | cut -f1 -d":") #On récupère les heures
	min=$(echo $temps | cut -f2 -d":") #Puis les minutes
    [[ $heure -gt "23" ]] && heure="00"
    [[ $min -gt "59" ]] && heure="00"
    
	#Si l'utilisateur clique sur quitter 
	[[ $rep -eq 1 ]] && exit 0

	#En fonction de la période sélectionnée, on applique à date une opération différente
	case $periodicite in
		Hebdomadaire*)
			date=$(date -d ${date} +%w) #On converti la date en 0...6 pour le jour de la semaine
			cron_date="${min} ${heure} * * ${date}" #Puis on formate pour crontab
				;;
		Mensuel*)
			date=$(date -d ${date} +%d) #On converti la date en 1..31 pour le jour du mois
			cron_date="${min} ${heure} ${date} * *"
				;;
		Journalier*)
			date="NULL" #On affiche NULL pour journalier
			cron_date="${min} ${heure} * * *"
				;;
		Annuel*)
			date=$(date -d ${date} "+%d %m") #On converti la date en jour plus mois
			cron_date="${min} ${heure} ${date} *"
	esac

	
	#On formate pour insérer dans la base de données
	strat_values=",\""$user_id"\",\""$rapp_id"\",\""$periodicite"\",\""$date"\",\""$temps"\""


	if [[ -n $2 ]]; then
		strat_values=$2$strat_values
		add_value $db_name "strats" $strat_values
		data=$(get_strat_fro_cron ${db_name} ${2}) #On récupère la query qui est dans le crontab
		crontab -l | grep -v "${data}" | crontab #Puis on suprimme la ligne du crontab qui contient cette query
		crontab < <(crontab -l ; echo "${cron_date} bash -x ${cron_shell} \"${db_name}\" \"${data}\" 2> /home/rochevin/Documents/rochevin_repository/projet_system/projet_v3/coucou.txt ") #Et on remplace par la nouvelle
	else 
		#Si on a pas fourni d'id, on en créer une nouvelle stratégie, sans ecraser l'ancienne dans le crontab
		strat_values="NULL"$strat_values
		last_id=$(sqlite3 ${db_name} "INSERT INTO strats VALUES (${strat_values});SELECT last_insert_rowid();")
		data=$(get_strat_fro_cron ${db_name} ${last_id})
		crontab < <(crontab -l ; echo "${cron_date} bash -x ${cron_shell} \"${db_name}\" \"${data}\" 2> /home/rochevin/Documents/rochevin_repository/projet_system/projet_v3/coucou.txt ")
	fi
	


}

##Fonction qui génére un rapport avec pandoc, en fournissant un fichier markdown, et produit un html
function generate_report {
	template=$1
	input=$2
	output=$3
	pandoc -s -S --toc -c ${template}  ${input} -o ${output}
}

##Fonction qui gère l'interface pour le rapport
function report_interface {
	#On récupère les variables et on créer les fichiers temporaires pour le rapport
	db_name=$1
	template=$2
	modele=$3
	temp_report=$(mktemp --tmpdir tab4.XXXXXXXX)
	temp_modele=$(mktemp --tmpdir tab5.XXXXXXXX)

	strat_query=$(mktemp --tmpdir tab6.XXXXXXXX)
	cron_query=$(mktemp --tmpdir tab7.XXXXXXXX)

	#On récupère les utilisateurs
	user_list=$(get_value $db_name "users")
	user_list=$(echo $user_list | tr " " "!")
	user_list=$(echo $user_list | tr "|" " ")

	#Ainsi que la période
	period_list="Toutes!Journalier!Hebdomadaire!Mensuel!Annuel"

	#On créer l'interface yad pour génerer le rapport en fonction de l'user et de la période
	action=$(yad --width 500 --height 200 --center --button="gtk-ok:0" --button="gtk-close:1" --form --separator=';' --field="Utilisateur::cb" "$user_list" --field="Périodicité::cb" "$period_list")
	rep=$?

	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0

	#On récupère l'utilisateur et la période sélectionné
	user_info=$(echo $action | cut -f1 -d";")
	period_info=$(echo $action | cut -f2 -d";")

	#On récupère les informations sur l'utilisateur pour le rapport
	user_id=$(get_id $user_info)
	name=$(echo $user_info | cut -f2 -d" ")
	first_name=$(echo $user_info | cut -f3 -d" ")
	mail=$(echo $user_info | cut -f4 -d" ")


	#Si l'utilisateur veut toutes les périodes, on ne spécifie pas de WHERE pour la periode, sinon, on spécifie pour ne récupèrer que la période voulue.
	#On fait une réquête pour obtenir les stratégie en cours, et celles qui sont terminées
	if [[ ! $period_info = "Toutes" ]]; then
		sqlite3 -header ${db_name} "SELECT rapps.file_name,rapps.local_path,rapps.dist_path,strats.periodicity,strats.date,strats.time FROM strats INNER JOIN rapps ON rapps.id = strats.id_rapp WHERE strats.id_user=${user_id} AND strats.periodicity=${period_info};" > $strat_query
		sqlite3 -header ${db_name} "SELECT rapps.file_name,rapps.local_path,rapps.dist_path,cron_task.periodicity,cron_task.date,cron_task.time,cron_task.date_complete,cron_task.status FROM cron_task INNER JOIN rapps ON rapps.id = cron_task.id_rapp WHERE cron_task.id_user=${user_id} AND cron_task.periodicity=${period_info};" > $cron_query
	else
		sqlite3 -header ${db_name} "SELECT rapps.file_name,rapps.local_path,rapps.dist_path,strats.periodicity,strats.date,strats.time FROM strats INNER JOIN rapps ON rapps.id = strats.id_rapp WHERE id_user=${user_id};" > $strat_query
		sqlite3 -header ${db_name} "SELECT rapps.file_name,rapps.local_path,rapps.dist_path,cron_task.periodicity,cron_task.date,cron_task.time,cron_task.date_complete,cron_task.status FROM cron_task INNER JOIN rapps ON rapps.id = cron_task.id_rapp WHERE id_user=${user_id};" > $cron_query
	fi

	#On écrit le modèle de base dans le fichier temporaire
	cat $modele > $temp_modele

	#Puis on commence à ecrire dans le fichier temporaire pour les stratégies en cours, puis finie

	printf "%s\n\n" "#Stratégies programmées" >> $temp_modele
	i=1 #On déclare un compteur à un pour le numéro de ligne
	IFS=$'\n' #On déclare le séparateur d'élement comme étant un retour chariot
	if [[ -s $strat_query ]]; then #On vérifie que la requête à aboutie
		for row in $(cat $strat_query); do #Puis on parcours chaque élément de la requête (chaque ligne)
			[[ $i -eq 2 ]] && printf "%s\n" "$(echo $row | awk -F "|" '{out = "";for(i=1;i<=NF;i++){out=out":-----:|"};print substr(out,1,length(out) -1)}')" >> $temp_modele #Si on est sur la deuxieme ligne, on a dépassé le header, on ecrit au format markdown pour signifier qu'on arrive dans les valeurs
			printf "%s\n" "$(echo $row | awk -F "|" '{out = "";for(i=1;i<=NF;i++){out=out$i" | "};print substr(out,1,length(out) -3)}')" >> $temp_modele #Dans tous les cas on ecris les valeurs avec un " |" à la fin, sauf pour le dernier
			i=$i+1
		done
		printf "\n%s\n\n" ": Stratégies programmées pour ${first_name} ${name}" >> $temp_modele
	else
		printf "\n%s\n\n" "Aucune stratégie prévue pour ${first_name} ${name}"  >> $temp_modele
	fi

	#On écrit la même chose pour les stratégies terminées
	printf "%s\n\n" "#Stratégies terminées" >> $temp_modele
	i=1
	if [[ -s $cron_query ]]; then #On vérifie que la requête à aboutie
		for row in $(cat $cron_query); do #Puis on parcours chaque élément de la requête (chaque ligne)
			[[ $i -eq 2 ]] && printf "%s\n" "$(echo $row | awk -F "|" '{out = "";for(i=1;i<=NF;i++){out=out":-----:|"};print substr(out,1,length(out) -1)}')" >> $temp_modele
			printf "%s\n" "$(echo $row | awk -F "|" '{out = "";for(i=1;i<=NF;i++){out=out$i" | "};print substr(out,1,length(out) -3)}')" >> $temp_modele
			i=$i+1
		done
		printf "\n%s\n\n" ": Stratégies terminées pour ${first_name} ${name}" >> $temp_modele
	else
		printf "\n%s\n\n" "Aucune stratégie terminées pour ${first_name} ${name}"  >> $temp_modele
	fi
	unset IFS #On remet à zero le séparateur d'élément

	sed -i -e "s%DATE%$(date +%F)%g" $temp_modele #On remplace la date par la date du jour
	sed -i -e "s%UTILISATEUR%${first_name} ${name}%g" $temp_modele #On remplace par le nom de l'utilisateur
	sed -i -e "s%NAME%${name}%g" $temp_modele #On remplace par le nom
	sed -i -e "s%FIRST%${first_name}%g" $temp_modele #On remplace par le prénom
	sed -i -e "s%MAIL_ADRESS%${mail}%g" $temp_modele #On remplace par l'adresse mail

	#On appelle la fonction pour générer le rapport, puis on affiche le résultat directement avec yad
	generate_report $template $temp_modele $temp_report && yad --html --browser --uri="$temp_report" --width 800 --height 800 --center --button="gtk-save:10" --button="gtk-close:1" --title="Rapport des stratégies pour ${first_name} ${name}"
	rep=$?

	#On enregistre le contenu du fichier temporaire dans une variable
	report=$(cat $temp_report)
	#Puis on suprimme tous les fichiers
	rm -f $temp_modele $temp_report $cron_query $strat_query


	#On créer le nom du rapport en fonction du nom, de la periode, et de la date du jour
	report_file="Rapport_${first_name}_${name}_${period_info}_$(date +%F).html"


	#Si l'utilisateur clique sur rapport, on génère le fichier à partir de la variable report
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
	func_script=$directory"/__sql_func__.sh" #Nom du fichier contenant toutes les fonctions utiles au bon fonctionnement du programme
	template=$directory"/buttondown.css" #template utilisé pour le rapport

	KEY="12345" #Clé utilisée par yad pour lier les onglets au yad principal
	[[ -n $1 ]] && KEY=$1 #Si l"utilisateur précise une clé, c'est cette valeur qui est prise
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
	user_data=$( echo $user_data| tr "|" " ") #On remplace les | par des espaces pour l'integration dans yad
	##rappatriements
	rapp_data=$(get_value ${db_name} "rapps")
	rapp_data=$( echo $rapp_data| tr "|" " ") #On remplace les | par des espaces pour l'integration dans yad
	##stratégies
	strat_data=$(get_value ${db_name} "strats")
	strat_data=$( echo $strat_data| tr "|" " ") #On remplace les | par des espaces pour l'integration dans yad


	#Onglet yad pour les utilisateurs
	yad --plug=$KEY --tabnum=1 --list --editable --multiple --regex-search --column="Id:HD" --column="Nom:TEXT" --column="Prénom:TEXT" --column="Adresse mail:TEXT" ${user_data} > $user_file &

	
	#Onglet yad pour les rappatriements
	yad --plug=$KEY --tabnum=2 --list --editable --multiple --regex-search --column="Id:HD" --column="Nom du fichier:TEXT" --column="Emplacement local:TEXT" --column="emplacement distant:TEXT" ${rapp_data} > $rapp_file &

	
	#Onlet yad pour les stratégies
	yad --plug=$KEY --tabnum=3 --list --editable --column="Id:HD" --column="Nom:TEXT" --column="Prénom:TEXT" --column="Adresse mail:TEXT" --column="Nom du fichier:TEXT" --column="Emplacement local:TEXT" --column="emplacement distant:TEXT" --column="Periodicité:TEXT" --column="Date:TEXT" --column="Heure:TEXT" ${strat_data} > $strat_file &

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
		if [[ -n $user ]]; then #On vérifie que la variable n'est pas vide
			for u in $user; do #On parcours chaque ligne proposé par l'utilisateur (multiligne)
				#rep=20 : modification d'un utilisateur
				if [[ $rep -eq 20 ]]; then
					mv_value $db_name "users" $u #On renvoit vers la fonction de modification de données
				#rep=30 : supression d'un utilisateur
				elif [[ $rep -eq 30 ]]; then
					id=$(get_id $u) #On récupère l'id et on renvoit vers la fonction de suppression de données
					rm_value $db_name "users" $id "PRAGMA foreign_keys = ON;"
				fi
			done
		fi

		if [[ -n $rapp ]]; then #On vérifie que la variable n'est pas vide
			for r in $rapp; do #On parcours chaque ligne proposé par l'utilisateur (multiligne)
				#rep=20 : modification d'un rappatriement
				if [[ $rep -eq 20 ]]; then
					mv_value $db_name "rapps" $r #On renvoit vers la fonction de modification de données
				#rep=30 : supression d'un rappatriement
				elif [[ $rep -eq 30 ]]; then
					id=$(get_id $r) #On récupère l'id et on renvoit vers la fonction de suppression de données
					rm_value $db_name "rapps" $id "PRAGMA foreign_keys = ON;"
				fi
		done
		fi

		if [[ -n $strat ]]; then #On vérifie que la variable n'est pas vide
			#rep=20 : modification d'une strategie
			if [[ $rep -eq 20 ]]; then 
				mv_value $db_name "strats" $strat #On renvoit vers la fonction de modification de données
			#rep=30 : supression d'une strategie
			elif [[ $rep -eq 30 ]]; then
				id=$(get_id $strat) #On récupère l'identifiant
				data=$(get_strat_fro_cron ${db_name} ${id}) #On récupère la query qui est dans le crontab
				crontab -l | grep -v "${data}" | crontab #Puis on suprimme la ligne du crontab qui contient cette query
				rm_value $db_name "strats" $id "PRAGMA foreign_keys = ON;" #On récupère l'id et on renvoit vers la fonction de suppression de données

			fi
		fi

		
	fi
	launch $launcher #On lance le launcher après application des paramètres

}

#On lance la fonction main
main $1