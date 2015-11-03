function Gestion {
	file_data=$(cat $file_name | tr "|" " ")

	action=$(yad --list --editable --width 500 --height 300 --center --button="Ajouter:0" --button="Modifier:2" --button="Supprimer:3" --button="Acceuil:4" --button="gtk-close:1" --title="Gestion des ${1}s" \
		--column="Id:HD" --column="Nom:TEXT" --column="Prénom:TEXT" --column="Adresse mail:TEXT" \
		$file_data) 
	rep=$?
}


function Ajout {
	if (($1 == 0)); then
		value=$(yad --form --title "Ajout d'un $2" --center --button="gtk-ok:0" --button="gtk-close:1" --image=dialog-warning --text="Aucun utilisateur référencé, \n veuillez en créer un :" --field="Nom :" --field="Prénom" --field="Adresse mail :")
	else
		value=$(yad --form --title "Ajout d'un $2" --center --button="gtk-ok:0" --button="gtk-close:1" --field="Nom :" --field="Prénom" --field="Adresse mail :")
	fi
	rep=$?
	#Si on appuie sur le bouton close, on quitte le programme
	[[ $rep -eq 1 ]] && exit 0
	value=$(echo $value | sed 's/.\{1\}$//g')

	if [ -f $file_name ]; then
		prev_id=$(tail -1 $file_name | cut -f1 -d"|")
		((prev_id++))
		result="$prev_id|$value"
		chmod +w $file_name
		echo $result >> $file_name
	else
		result="1|$value"
		echo $result > $file_name
		chmod +w $file_name
	fi
	./$0
	exit 0
}

function Modif {
	if [ -f $file_name ]; then
		id=$(echo $action | cut -f1 -d"|")
		id+="|"
		initial_name=$(grep $id $file_name)
		new_name=$(echo $action | sed 's/.\{1\}$//g')
		sed -i -e "s/${initial_name}/${new_name}/" $file_name
		./launcher.sh
		exit 0
	else
		yad --title="Erreur" --width=300 --center --button="gtk-close" --image=dialog-error --text="Aucun(e) ${2}s référencés, vous devez créer un ${2} avant cela."
		./launcher.sh
		exit 1
	fi
	exit 0
}

function Supp {
	if [ -f $file_name ]; then
		value=$(echo $action | sed 's/.\{1\}$//g')
		lign_number_user=$(grep -n "$value" $file_name | cut -f1 -d":")
		sed -i "/"${lign_number_user}"/d" $file_name
		if [ ! -s $file_name ]; then
			chmod +w $file_name
			rm $file_name
		fi
		./user.sh
		exit 0
	else
		yad --title="Erreur" --width=300 --center --button="gtk-close" --image=dialog-error --text="Aucun(e) ${2}s référencés, vous devez créer un ${2} avant cela."
		./$0
		exit 1
	fi
	exit 0
}
