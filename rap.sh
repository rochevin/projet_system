#! /bin/bash

file_name="rappatriements.txt"


action=$(yad --width 300 --entry --title "Gestion des rappatriements" --center --button="gtk-ok:0" --button="gtk-close:1" --text "Actions :" --entry-text "Ajout rappatriement" "Modification rappatriement" "Supression rappatriement")
rep=$?

#Si on appuie sur le bouton close, on quitte le programme
[[ $rep -eq 1 ]] && exit 0
##Sinon on peut executer le code
action=$(echo $action | cut -f1 -d" ")

case $action in
	Ajout*) cmd=1 ;;
	Modification*) cmd=2 ;;
	Supression*) cmd=3 ;;
	*) exit 1 ;;        
esac

##Ajout rappatriement
if ((cmd == 1)); then
	action=$(yad --width 300 --title "Planifier un rappatriement" --center --button="gtk-ok:0" --button="gtk-close:1" --form --field="Nom du fichier :" --field="Adresse du serveur distant :" --field="Répertoire distant :" --field="Choix du répertoire local:DIR"
	)
	rep=$?
	action=$(echo $action | sed 's/.\{1\}$//g')
	if [ -f $file_name ]; then
		prev_id=$(tail -1 $file_name | cut -f1 -d"|")
		((prev_id++))
		result="$prev_id|$action"
		echo $result >> $file_name
	else
		result="1|$action"
		echo $result > $file_name
		chmod +w $file_name || echo "Impossible de donner les droits d'écriture sur $file_name, tenter : chmod +w $file_name"
	fi
	exit 0
##Modification d'un utilisateur
elif ((cmd ==2)); then
	if [ -f $file_name ]; then
		rapp=$(cat $file_name | cut -f2,3,4,5 -d"|" | tr "|" " " | tr "\n" "," | sed 's/.\{1\}$//g')
		value=$(yad --width=300 --center --button="gtk-ok:0" --button="gtk-close:1" --title="Modifier un rappatriement" --text="Sélectionner un rappatriement" --form --item-separator="," --field="Rappatriement":CB --form --field="Nom du fichier :" --field="Adresse du serveur distant :" --field="Répertoire distant :" --field="Choix du répertoire local:DIR" "$rapp")
		rep=$?
		#Si on appuie sur le bouton close, on quitte le programme
		[[ $rep -eq 1 ]] && exit 0
		value=$(echo $value | sed -e "s/|/;/")
		initial_name=$(echo $value | cut -f1 -d";" | tr " " "|")
		new_name=$(echo $value | cut -f2 -d";" | sed 's/.\{1\}$//g')
		sed -i -e "s/$initial_name/$new_name/" $file_name
	else
		yad --title="Erreur" --width=300 --center --button="gtk-close:1" --image=dialog-error --text="Pas de rappatriements référencés, vous devez créer un utilisateur avant cela."
		rep=$?
		#Si on appuie sur le bouton close, on quitte le programme
		[[ $rep -eq 1 ]] && exit 0
		./launcher.sh
	fi
##Suppression d'un utilisateur
elif ((cmd == 3)); then
	if [ -f $file_name ]; then
		users=$(cat $file_name | cut -f2,3 -d"|" | tr "|" " " | tr "\n" "," | sed 's/.\{1\}$//g')
		value=$(yad --width=300 --center --button="gtk-ok" --button="gtk-close" --title="Supprimmer un utilisateur" --text="Sélectionner un utilisateur" --form --item-separator="," --field="Utilisateur":CB "$users")
		value=$(echo $value | tr " " "|")
		lign_number_user=$(grep -n "$value" users.txt | cut -f1 -d":")
		lign_number_user+="d"
		sed -i "$lign_number_user" $file_name
	else
		yad --title="Erreur" --width=300 --center --button="gtk-close" --image=dialog-error --text="Pas d'utilisateurs référencés, vous devez créer un utilisateur avant cela."
		./launcher.sh
	fi
	exit 0
else
	echo "PAS ENCORE FAIT HAHA"
	exit 1
fi


