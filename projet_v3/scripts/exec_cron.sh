#! /bin/bash
func_script="scripts/__sql_func__.sh" #Nom du fichier contenant toutes les fonctions utiles au bon fonctionnement du programme
[[ ! -f $func_script ]] && exit 1
source $func_script

#On récupère le nom de la base de données, ainsi que les données formatées
db_name=$1
data=$2


#On créer un fichier temporaire
wget_output=$(mktemp --tmpdir tab1.XXXXXXXX)



#Si on a pas de données, on quitte le programme sans rien executer
[[ ! -n $data ]] && exit 1

#sinon, on execute le programme 
#On récupère l'identifiant et les valeurs contenus dans data
id=$(echo $data | cut -f4 -d"|")
value=$(echo $data | cut -f5- -d"|")
#Et on formate au format sql
sql_value=$(format_for_sql $value)

#On récupère également le rappatriement pour le wget
rapp_file=$(echo $data | cut -f1 -d"|")
rapp_local=$(echo $data | cut -f2 -d"|")
rapp_dist=$(echo $data | cut -f3 -d"|")

#Si le repertoire distant contient un / à la fin, on le suprimme
[[ ${rapp_dist: -1} = "/" ]] && rapp_dist=$(remove_last_char ${rapp_dist})

#On execute le wget
error=0
wget -a ${wget_output} -N -v -P "${rapp_local}" "${rapp_dist}/${rapp_file}" || error=1

#On récupère la dernière ligne non vide de l'output de wget
status=$(cat ${wget_output} | tail -5 | sed '/^$/d' | tail -1)
date=$(date)
#Puis on maj la base de données comme tache terminée
if [[ $error -eq 0 ]];then
	add_value ${db_name} "cron_task" "NULL,${sql_value},\"${date}\",\"${status}\""
else
	add_value ${db_name} "cron_task" "NULL,${sql_value},\"${date}\",\"Impossible de télécharger ${rapp_dist}/${rapp_file}\""
fi
#enfin on suprimme le fichier temporaire
rm -f $wget_output
