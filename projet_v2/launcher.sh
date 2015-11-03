#! /bin/bash

action=$(yad --width 300 --entry --title "Planificateur de tâches" --center --button="gtk-ok:0" --button="gtk-close:1" --text "Actions :" --entry-text "Gestion utilisateurs" "Gestion rappatriements" "Gestion stratégies" "Générer rapport"
)
#Si on appuie sur le bouton close, on quitte le programme
[[ $rep -eq 1 ]] && exit 0
##Sinon on peut executer le code
action=$(echo $action | cut -f2 -d" ")

case $action in
    utilisateurs*) cmd="./user.sh" ;;
    rappatriements*) cmd="./rap.sh" ;;
    stratégies*) cmd="echo -e 'Gestion stratégies'" ;;
    rapport*) cmd="echo -e 'Générer un rapport'" ;;
    *) exit 1 ;;        
esac

eval exec $cmd
