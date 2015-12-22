#! /bin/bash
file_gestion="gestion.sh"


action=$(yad --width 300 --entry --title "Planificateur de tâches" --center --button="gtk-ok:0" --button="gtk-close:1" --text "Actions :" --entry-text "Gestion utilisateurs" "Gestion rappatriements" "Gestion stratégies" "Générer rapport"
)
#Si on appuie sur le bouton close, on quitte le programme
[[ $rep -eq 1 ]] && exit 0
##Sinon on peut executer le code
action=$(echo $action | cut -f2 -d" ")

case $action in
    utilisateurs*) file_name="users.txt"
						name="utilisateur";;
    rappatriements*) file_name="rapp.txt"
						name="rappatriement";;
    stratégies*) file_name="strat.txt"
					name="stratégies";;
    rapport*) file_name="rapp.txt"
				name="rappatriement";;
    *) exit 1 ;;        
esac

if [[ ! -x $file_gestion ]]; then
	chmod +x $file_gestion
fi
eval exec "./${file_gestion} ${file_name} ${name} ${0##*/}"




