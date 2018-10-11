#!/bin/bash

#Per eventuali bug contattami su telegram @v4lley
#Disclaimer: Se lo script è lento è colpa della connessione, specialmente se state usando quella dell'uni ;)
#Disclaimer: Se lo script mette i file in sottocartelle sbagliate generalmente è perchè i prof li hanno caricati nelle cartelle sbagliate

source configurazione.sh

if [[ -z $user ]]
	then
	echo 'Inserisci il tuo nome utente:'
	read -r user
fi

echo 'Inserisci la password di moodle. (Non ti rubo la password, lo script deve entrare su moodle)'
read -s -r pass

#Login
wget --save-cookies cookies.txt \
	--keep-session-cookies \
	--post-data "username=$user&password=$pass" \
	--delete-after \
	https://informatica.i-learn.unito.it/login/index.php

#Download dei file per ogni corso
for ((i=0;i<${#corsi[@]};i++))
do
	#Dowload delle cartelle
	#wget su link "/mod/folder/", cartelle
	#folders contiene i link di tutte le cartelle presenti nel corso
	folders="$(wget --load-cookies cookies.txt \
	-O - \
	"${corsi[i]}" \
	| grep -Po 'http://informatica.i-learn.unito.it/mod/folder/view.php\?id=\d+')"

	#Trova i nomi corretti delle cartelle
	k=0
	for a in $folders
	do
		#foldernames contiene i nomi corrispondenti alle cartelle
		foldernames[k]="$(wget --load-cookies cookies.txt \
		-O - \
		"$a" \
		| grep -Po '(?<=<title>).*(?=</title>)' \
		| cut -d ':' -f 2- \
		| tr / - \
		| sed -e 's/^[[:space:]]*//')"

		((k++))
	done	

	#Trasforma in array
	mapfile -t folders < <(echo "$folders")

	#Scarica le cartelle coi rispettivi nomi
	for ((k=0;k<${#folders[@]};k++))
	do
		wget --load-cookies cookies.txt \
		--recursive \
		--accept-regex 'informatica.i-learn.unito.it/.*/mod_folder/content/.*' \
		-nH \
		--cut-dirs=5 \
		--content-disposition \
		--no-clobber \
		-P "./${cartelle[i]}/${foldernames[k]}" \
		"${folders[k]}"
	done	

	#Dowload dei file fuori dalle cartelle
	#wget su link "/mod/resource", generalmente fanno un redirect su un altro link su cui si trova il file
	#wget su link "/mod_resource/content/", generalmente link diretti al file
	wget --load-cookies cookies.txt \
		--recursive \
		--accept-regex 'informatica.i-learn.unito.it/(mod/resource/.*|.*/mod_resource/content/.*)' \
		--reject-regex 'informatica.i-learn.unito.it/mod/resource/.*&lang=.*' \
		-nH \
		--cut-dirs=5 \
		--content-disposition \
		--no-clobber \
		-P "./${cartelle[i]}" \
		"${corsi[i]}"

	#Copia della pagina html del corso
	idcorso="$(echo "${corsi[i]}" | grep -Po 'informatica.i-learn.unito.it/course/view.php\?id=\K\d+')"
	mv "${cartelle[i]}/view.php?id=$idcorso" "${cartelle[i]}/${cartelle[i]}Moodle.html"
done

find . -name 'view.php?*' -type f -delete
rm cookies.txt
echo 'Download completato.'