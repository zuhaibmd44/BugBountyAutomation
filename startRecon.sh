#!/bin/bash
#Zuhaib Mohammed - July 2021
#This script is automate the initial recon for bug bounty
#Command to run -> ./startRecon.sh example.com

domain=$1
wordlist="/root/wordlists/top500.txt"
resolver="/root/wordlists/resolvers.txt"
get_ip="massdns -r $resolver -t A -o S -w"

subdomain_enum() {
    #Create all the directories and subdirectories
    mkdir -p $domain $domain/sources $domain/recon $domain/recon/nuclei $domain/recon/waybackurls $domain/recon/gf $domain/recon/wordlists $domain/recon/massdns

    #Subdomain Enumeration
    subfinder -d $domain -o $domain/sources/s1.txt
    assetfinder --subs-only $domain | tee $domain/sources/s2.txt
    amass enum -passive -d $domain -config /root/config/amass_config.ini -o $domain/sources/s3.txt
    curl -s https://dns.bufferover.run/dns?q=.$domain | jq -r .FDNS_A[] | cut -d',' -f2 | sort -u | tee $domain/sources/s4.txt
    crtsh $domain | tee $domain/sources/s5.txt

    #bruteforce subdomain using wordlist
    shuffledns -d $domain -w $wordlist -r $resolver -o $domain/sources/s6.txt

    #add chaos afftet getting API key

    #Sort and Extract all the Unqiue domains
    cat $domain/sources/*.txt >$domain/sources/all.txt
    cat $domain/sources/all.txt | sort -u >$domain/allUnique.txt
}
subdomain_enum

resolve_domains() {

    #Resolve the subdomains
    shuffledns -d $domain -list $domain/allUnique.txt -o $domain/finalDomains.txt -r $resolver

}
resolve_domains

http_probing() {

    #check the valid HTTP and HTTPS domains
    cat $domain/finalDomains.txt | httpx -threads 100 -o $domain/recon/httpx.txt
}
http_probing

nuclei_scanner() {

    #Finding known and common vulns using nuclei
    cat $domain/recon/httpx.txt | nuclei -t /root/nuclei-templates/cves/ -c 50 -o $domain/recon/nuclei/cves.txt
    cat $domain/recon/httpx.txt | nuclei -t /root/nuclei-templates/takeovers/ -c 50 -o $domain/recon/nuclei/takeovers.txt
    cat $domain/recon/httpx.txt | nuclei -t /root/nuclei-templates/technologies/ -c 50 -o $domain/recon/nuclei/technologies.txt
    cat $domain/recon/httpx.txt | nuclei -t /root/nuclei-templates/vulnerabilities/ -c 50 -o $domain/recon/nuclei/vulnerabilities.txt
    cat $domain/recon/httpx.txt | nuclei -t /root/nuclei-templates/file/ -c 50 -o $domain/recon/nuclei/file.txt

}
nuclei_scanner

waybackdata() {

    #Extract the url using waybackuels
    cat $domain/finalDomains.txt | waybackurls | tee $domain/recon/waybackurls/tmp.txt
    #Using egrep inverse function to remove url ending with unwanted extensions
    cat $domain/recon/waybackurls/tmp.txt | egrep -v "\.css|\.ico|.\svg|.\js|.\ttf|.\woff" | sed 's/:80//g;s/:443//g' | sort -u >$domain/recon/waybackurls/waybackurls.txt
    rm $domain/recon/waybackurls/tmp.txt

}
waybackdata

fuzzer() {

    #Fuzzing all the wayback urls for valid or alive urls
    ffuf -c -u "FUZZ" -w $domain/recon/waybackurls/waybackurls.txt -mc 200,301 -of csv -o $domain/recon/waybackurls/alive-temp.txt
    #Perform clening to get proper url only data
    cat $domain/recon/waybackurls/alive-temp.txt | grep http | awk -F ',' '{print $1}' >$domain/recon/waybackurls/alive.txt
    rm $domain/recon/waybackurls/alive-temp.txt

}
fuzzer

gf_patterns() {

    #find possible ndpints for common vulns
    gf xss $domain/recon/waybackurls/alive.txt | tee $domain/recon/gf/xss.txt
    gf sqli $domain/recon/waybackurls/alive.txt | tee $domain/recon/gf/sqli.txt
    gf lfi $domain/recon/waybackurls/alive.txt | tee $domain/recon/gf/lfi.txt
    gf idor $domain/recon/waybackurls/alive.txt | tee $domain/recon/gf/idor.txt

}

gf_patterns

custom_wordlist() {

    cat $domain/recon/waybackurls/waybackurls.txt | unfurl -unique paths >$domain/recon/wordlists/path.txt
    #cat path.txt | sed 's/\// /g' | awk '{print $1}' | sort -u
    cat $domain/recon/waybackurls/waybackurls.txt | unfurl -unique keys >$domain/recon/wordlists/keys.txt

}

custom_wordlist

get_ip() {

    $resolve_domain $domain/recon/massdns/results.txt
    gf ip $domain/recon/massdns/results.txt | sort -u $domain/recon/massdns/ip.txt

}

get_ip
