#!/bin/sh

pError() {
    if [ "$#" -ne 1 ]; then
        echo "Invalid arguments: need one string."
        exit 1
    fi
    echo "\033[31m[ERROR]\033[0m $1"
}

pInfo() {
    if [ "$#" -ne 1 ]; then
        echo "Invalid arguments: need one string."
        exit 1
    fi
    echo "\033[32m[INFO]\033[0m $1"
}

analyse() {
    if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
        pError "Invalid input to analyse code."
        exit 1
    fi
    if [ -z "$(echo $1 | grep '*.c')" ]; then
        pError "Input is not .c code. Can not analyse it."
        exit 1
    fi
    cat "$1" | grep "[a-z][a-zA-Z0-9]* [a-z][a-zA-Z0-9]([^\)]*)"
}

if [ "$#" -eq 1 ];
    if [ -d "$1" ]; then
        pInfo "Scanning code in files located in $1"
    elif [ -f "$1" ]; then
        pInfo "Scanning code in $1"
    else
        pError "Parameter $1 is not a valid input."
        exit 1
    fi
fi

exit 0
