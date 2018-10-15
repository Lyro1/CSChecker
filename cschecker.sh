#!/bin/sh

pError() {
if [ "$#" - ne 1]; then 
    echo "Invalid arguments: need one string."
	exit 1 
fi 
echo "\033[31m[ERROR]\033[0m $1"
}

pInfo() {
if [ "$#" - ne 1]; then 
    echo "Invalid arguments: need one string."
	exit 1 
fi 
echo "\033[32m[INFO]\033[0m $1"
}

analyse() {
if [[ "$#" - ne 1 ||  !-f "$1" ]]; then 
    pError "Invalid input to analyse code."
	exit 1
fi

if [[-z "$(echo $1 | grep '[^.]+[.]c' -E)" && -z "$(echo $1 | grep '*.h')"]]; then            
    pError "Input is not .c code. Can not analyse it." 
    exit 1 
fi 

cat "$1" | grep "[a-z][a-zA-Z0-9]* [a-z][a-zA-Z0-9]([^\)]*)"
}

if [ "$#" -eq 1 ]; then 
    if [ -d "$1" ]; then 
        pInfo "Scanning code in files located in $1" 
        for file in $(ls $1 -R); do
            analyse "$file" 
        done 
    elif [ -f "$1" ]; then
        pInfo "Scanning code in $1" 
        analyse "$1"
    else
        pError "Parameter $1 is not a valid input." 
        exit 1 
    fi
else
    pError "Invalid parameters: ./cschecker.sh <source>" 
    exit 1 
fi 

exit 0
