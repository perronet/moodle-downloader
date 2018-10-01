#!/bin/bash

#########CONFIGURAZIONE###########
#Id corrispondenti ai link dei vari corsi, separati da spazi
#Puoi trovare l'id del corso alla fine del link della sua pagina su moodle
#Esempio: corsi=(1565 1608 1612 1576 1622)
corsi=()

#Nomi delle cartelle corrispondenti agli id dei corsi, separati da spazi
#Esempio: cartelle=(LPP MFI Reti Prog3 Tweb)
cartelle=()

#Username di moodle
#Esempio: user='mario.coppo'
user=''

#Se vuoi scaricare anche una copia html della pagina moodle cancella il # dalla riga dopo questa
#html=true
##################################

#Per eventuali bug contattami su telegram @v4lley
#Disclaimer: Se lo script è lento è colpa della connessione, specialmente se state usando quella dell'uni ;)
#Disclaimer: Se lo script mette i file in sottocartelle sbagliate generalmente è perchè i prof li hanno caricati nelle cartelle sbagliate

link='informatica.i-learn.unito.it/course/view.php?id='

if [ -z $user ]
	then
	echo 'Inserisci il tuo nome utente:'
	read user
fi

echo 'Inserisci la password di moodle. (Non ti rubo la password, lo script deve entrare su moodle)'
read -s pass

#Login
wget --save-cookies cookies.txt \
	--keep-session-cookies \
	--post-data 'username='$user'&password='$pass \
	--delete-after \
	https://informatica.i-learn.unito.it/login/index.php

#Download dei file per ogni corso
for ((i=0;i<${#corsi[@]};i++))
do
	#wget su link "/mod/resource", generalmente fanno un redirect su un altro link su cui si trova il file
	#wget su link "/mod_resource/content/", generalmente link diretti al file
	#wget su link "/mod/folder/", intere cartelle TODO implementare lo "scarica cartella" per separare le diverse cartelle
	wget --load-cookies cookies.txt \
		--recursive \
		--accept-regex 'informatica.i-learn.unito.it/(mod/resource/.*|mod/folder/.*|.*/mod_resource/content/.*|.*/mod_folder/content/.*)' \
		--reject-regex 'informatica.i-learn.unito.it/mod/resource/.*&lang=.*' \
		-nH \
		--cut-dirs=5 \
		--content-disposition \
		--no-clobber \
		-P './'${cartelle[i]} \
		$link${corsi[i]}

	if [ $html ]
		then
		mv ${cartelle[i]}/view.php?id=${corsi[i]} ${cartelle[i]}/${cartelle[i]}Moodle.html
	fi
done

find -name 'view.php?*' -type f -delete
rm cookies.txt
echo 'Download completato.'
