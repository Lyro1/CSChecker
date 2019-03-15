#!/bin/sh

pError() {
    if [ "$#" -ne 1 ]; then 
        echo "Invalid arguments: need one string."
	    exit 1 
    fi 
    echo "\033[31m[ KO ]\033[0m $1"
}

pSuccess() {
    if [ "$#" -ne 1 ]; then
        echo "Invalid arguments: need one string."
        exit 1
    fi
    echo "\033[32m[ OK ]\033[0m $1"
}

pInfo() {
    if [ "$#" -ne 1 ]; then 
        echo "Invalid arguments: need one string."
	    exit 1 
    fi 
    echo "\033[32m[INFO]\033[0m $1"
}

analyse() {
    if [ "$#" -ne 2 ] && [ ! -f "$1" ]; then
        pError "Invalid arguments: usage: ./cschecker.sh <source> <allowed functions>"
        exit 0
    fi
        
    if [ -z "$( echo "$1" |grep '[a-zA-Z0-9_]*[.]c$' )" ] && \
       [ -z "$( echo "$1" |grep '[a-zA-Z0-9_]*[.]h$' )" ]; then
        pError "Invalid file type. Given file ($1) is not C code."
        exit 0
    else
        pInfo "Valid format file. $1 is a C code file."
    fi

    errors=0
    pInfo "# Start analyse on $1"
    
    checkcol=$( cat $1 |grep '.\{81\}')
    if [ ! -z "$checkcol" ]; then
        pError "| - CS 2.1 file.cols: Lines MUST NOT exceed 80 columns in width, excluding the trailing newline character."
        errors=$((errors+1))
    else
        pSuccess "| - CS 2.1 file.cols: No line exceed 80 columns."
    fi

    functions="$( cat $1 |grep -E '[a-z][a-zA-Z0-9_ ]+\([a-zA-Z0-9_*\(\), ]*$' )"
    number_of_functions=$(echo "$functions" | wc -l)

    spaceinpar=$( grep '([[:blank:]]\|[[:blank:]])' "$1" )
    number_of_sip=$( echo "$spaceinpar" | wc -l )
    if [ "$number_of_sip" -ne 0 ]; then
        pError "| - CS 7.18 exp.parentheses: There MUST NOT be any whitespace following an opening parenthesis nor any"
        pError "|                            whitespace preceding a closing parenthesis."
        errors=$((errors+1))
    else
        pSuccess "| - CS 7.18 exp.parentheses: No extra whitespaces between parenthesis"
    fi

    spaceparenthesis=$( echo "$functions" |grep '[^ ]+[[:space:]]+(')
    number_of_sp=$( echo "$spaceparenthesis" |wc -l)
    if [ "$number_of_sp" -ne 0 ]; then
        pError "| - CS 7.19 exp.args: There MUST NOT be any whitespace between the function or method name and the opening"
        pError "|                     parenthesis for arguments, either in declarations or calls."
        pError "|    $1: $spaceparenthesis"
        errors=$((errors+1))
    else
        pSuccess "| - CS 7.19 exp.args: No function with whitespace between the function name and the opening parenthesis."
    fi

    noarg=$( echo "$functions" |grep '[^(]+([[:blank:]]*)')
    number_of_noargs=$( echo "$noarg" |wc -l)
    if [ "$number_of_noargs" -ne 0 ]; then
        pError "| - CS 8.5 fun.proto.void: Prototypes MUST specify void if your function does not take any argument."
        pError "|   $1: $noarg"
        errors=$((errors+1))
    else
        pSuccess "| - CS 8.5 fun.proto.void: No functions with no arguments."
    fi
    
    toomanyargs=$( echo "$functions" |grep -E '*,[^,]+,[^,]+,[^,]+,*')
    number_of_toomanyargs=$( echo "$toomanyargs" | wc -l)
    if [ "$number_of_toomanyargs" -ne 0 ]; then
        pError "| - CS 8.6 fun.arg.count: Functions MUST NOT take more than 4 arguments."
        pError "|   $1: $toomanyargs"
        errors=$((errors+1))
    else
        pSuccess "| - CS 8.6 fun.arg.count: No functions with more than 4 arguments."
    fi

    nonexported=$( echo "$functions" |grep '^static' |wc -l)
    number_of_exported=$(( $number_of_functions - $nonexported ))
    if [ "$number_of_exported" -gt 5 ]; then
        pError "| - CS 8.7 export.fun: There MUST BE at most 5 exported functions per source file."
        pError "|   currently you have $number_of_exported exported functions."
    else
        pSuccess "| - CS 8.7 export.fun: $number_of_exported exported functions (which is less than 6)"
    fi

    if [ "$?" -ge 1 ]; then
        pError "grep: failed to search the function prototype."
    else
        if [ "$number_of_functions" -gt 10 ]; then
            pError "| - CS 8.9 file.fun.count: There MUST NOT appear more than 10 functions (exported + local) per source file."
            pError "|   Currently you have $number_of_functions functions."
            errors=$((errors+1))
        else
            if [ "$number_of_functions" -eq 1 ]; then
                pSuccess "| - CS 8.9 file.fun.count: 1 function (which is less than 10)."
            else
                pSuccess "| - CS 8.9 file.fun.count: $number_of_functions functions (which is less than 10)."
            fi
        fi
    fi
    
    tabs=$( cat $1 |grep -P "\t")
    if [ ! -z "$tabs" ]; then
        errors=$((errors+1))
        pError "| - CS 2.2 file.indentation: Identation MUST be done using whitespace only, tabulations MUST NOT appear in your code."
        pError "|   $1: '$tabs'"
    else
        pSuccess "| - CS 2.2 file.identation: no tabulation detected."
    fi
	
    len="$( cat $1 | wc -l )"
    braces="$( cat $1 |grep '[{}[:blank:]]' |wc -l)"
    comments="$( cat $1 |grep '^//' |wc -l)" 
    
    if [ "$errors" -ne 0 ]; then
	if [ "$errors" -eq 1 ]; then
	    pError "| Analyse done: 1 error was detected."	
	else
            pError "| Analyse done: $errors errors were detected."
	fi
    else
        pSuccess "| Analyse done: no error has been detected."
    fi
}

if [ "$#" -eq 0 ]; then
    pError "Invalid arguments: cschecker.sh requires at least a file, a list of file or a directory"
    exit 1
fi

clear
pInfo "========================= | Coding Style Checker | ========================"
pInfo "Before processing the Coding Style Check, enter the following informations"
pInfo "What are the allowed functions of the project ? (enter the function name,"
pInfo "like so 'malloc, free, printf')"
read allowed_funcs
pInfo "Allowed functions are: $allowed_funcs"

if [ "$#" -eq 1 ] && [ -d "$1" ]; then
    pInfo "Analysing C files located in $1"
    pInfo "Results will be written in the result.txt file."
    rm result.txt
    touch result.txt
    find "$1" -name '*.c' -or -name '*.h' | while read file; do
        analyse "$file" "$allowed_funcs" >> "result.txt"
    done
else
    for arg in "$@"; do
        analyse "$arg" "$allowed_funcs"
    done
fi

exit 0
