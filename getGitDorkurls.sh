#!/bin/bash
#Zuhaib Mohammed - July 2021
#This script is get all the urls with the required organization and git dorks
#Command to run -> ./getGitDorkurls.sh organisation git_worldlist 
#Install Open Multiple URLs on Chrome to open around 25 tabs at once
domain="Unity-Technologies"
wordlist="sampleDorks.txt"

#url example -> https://github.com/search?o=desc&q=org:Unity-Technologies+token&s=indexed&type=Code

while IFS= read -r line
do
    echo "https://github.com/search?q=org:$domain+'$line'&s=indexed&type=Code"

done < "$wordlist"
