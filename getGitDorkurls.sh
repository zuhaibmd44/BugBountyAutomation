#!/bin/bash
#Zuhaib Mohammed - July 2021
#This script is get all the urls with the organization and git dorks
#Command to run -> ./getGitDorkurls.sh <organisation> <git_worldlist> 
#Install Open Multiple URLs on Chrome to open around 25 tabs at once
org=$1
wordlist=$2

while IFS= read -r line
do
    echo "https://github.com/search?q=org:$org+'$line'&s=indexed&type=Code"

done < "$wordlist"
