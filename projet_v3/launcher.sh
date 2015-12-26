#! /bin/bash
file_gestion="gestion.sh"
db_name="gestion.db"

action=$(yad --width 300 --entry --title "Planificateur de tâches" --center --button="gtk-ok:0" --button="gtk-close:1" --text "Actions :" --entry-text "Gestion utilisateurs" "Gestion rappatriements" "Gestion stratégies" "Générer rapport")
#Si on appuie sur le bouton close, on quitte le programme
[[ $rep -eq 1 ]] && exit 0
##Sinon on peut executer le code
action=$(echo $action | cut -f2 -d" ")

case $action in
    utilisateurs*) table_name="users"
						name="utilisateur";;
    rappatriements*) table_name="rapps"
						name="rappatriement";;
    stratégies*) table_name="strats"
					name="stratégies";;
    rapport*) table_name="rapp.txt"
				name="rappatriement";;
    *) exit 1 ;;        
esac

if [[ ! -x $file_gestion ]]; then
	chmod +x $file_gestion
fi
eval exec "./${file_gestion} ${table_name} ${name} ${db_name} ${0##*/}"




