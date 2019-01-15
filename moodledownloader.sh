#!/bin/bash

#For any bugs contact me on telegram @v4lley
#Disclaimer: If the script is slow, it's the connection's fault, especially if you are using our university's connection ;)
#Disclaimer: If the script puts the files in wrong subfolders it's generally because the professors uploaded them in the wrong folders.

source config.sh

if [[ -z $user ]]
	then
	echo 'Insert your username:'
	read -r user
fi

echo "Insert your password. (I won't steal your password, the script must access Moodle)"
read -s -r pass

#Login
wget --save-cookies cookies.txt \
	--keep-session-cookies \
	--post-data "username=$user&password=$pass" \
	--delete-after \
	https://informatica.i-learn.unito.it/login/index.php

#Download files for each course
for ((i=0;i<${#courses[@]};i++))
do
	#Download folders on the course page
	#wget on links "/mod/folder/", these pages contain a list of every file in the folder
	#'folders' contains a link for each folder in the course
	folders="$(wget --load-cookies cookies.txt \
	-O - \
	"${courses[i]}" \
	| grep -Po 'https://informatica.i-learn.unito.it/mod/folder/view.php\?id=\d+')"

	#Find proper folder names
	k=0
	for a in $folders
	do
		#'foldernames' contains names corresponding to the folders
		foldernames[k]="$(wget --load-cookies cookies.txt \
		-O - \
		"$a" \
		| grep -Po '(?<=<title>).*(?=</title>)' \
		| cut -d ':' -f 2- \
		| tr / - \
		| sed -e 's/^[[:space:]]*//')"

		((k++))
	done	

	#Convert into array
	mapfile -t folders < <(echo "$folders")

	#Download every folder in the course with the respective name
	for ((k=0;k<${#folders[@]};k++))
	do
		wget --load-cookies cookies.txt \
		--recursive \
		--accept-regex 'https://informatica.i-learn.unito.it/.*/mod_folder/content/.*' \
		-nH \
		--cut-dirs=5 \
		--content-disposition \
		--no-clobber \
		-P "./${coursesfolder[i]}/${foldernames[k]}" \
		"${folders[k]}"
	done	

	#Download single files outside of the course's folders
	#wget on links "/mod/resource", they redirect on another link on which the file is located
	#wget on links "/mod_resource/content/", direct links to the file
	wget --load-cookies cookies.txt \
		--recursive \
		--accept-regex 'https://informatica.i-learn.unito.it/(mod/resource/.*|.*/mod_resource/content/.*)' \
		--reject-regex 'https://informatica.i-learn.unito.it/mod/resource/.*&lang=.*' \
		-nH \
		--cut-dirs=5 \
		--content-disposition \
		--no-clobber \
		-P "./${coursesfolder[i]}" \
		"${courses[i]}"

	#Make a copy of the html page
	courseid="$(echo "${courses[i]}" | grep -Po 'https://informatica.i-learn.unito.it/course/view.php\?id=\K\d+')"
	mv "${coursesfolder[i]}/view.php?id=$courseid" "${coursesfolder[i]}/${coursesfolder[i]}Moodle.html"
done

find . -name 'view.php?*' -type f -delete
find . -name 'index.php' -type f -delete
rm cookies.txt
echo 'Download completed.'
