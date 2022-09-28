#!/bin/bash

#*****************************************#
#          ICON SUBSET GENERATOR          #
#                                         #
# Author: Oscar Olivares                  #
# Email: oscarolivares625@gmail.com       #
# Date: 27 de Septiembre del 2022         #
#*****************************************#

# Root directories to scan (will be scanned recursively)
inputDir=("./input")

# Extensions of the files to be scanned
extensions=("html" "php" "js" "json")

# Icon prefixes to look for
prefix=("fa-")

# SVG asset location
svgs="./svgs"

# Output root directory
output="./output"


#Case sensitive extensions, set "0" to disable
iprefix="1"

#Extracted svg directory
extractedSvgs="$output/svgs"


while getopts i:e:o:s:p: flag
do
    case "${flag}" in
        i) inputDir=(${OPTARG});;
        e) extensions=(${OPTARG});;
        o) output=${OPTARG};;
        s) svgs=${OPTARG};;
        p) prefix=(${OPTARG});;

        *)
          exit 1
        ;;
    esac
done


iconFound="$output/icon-found.txt"
matchedIcon="$output/icon-matching.txt"
missingIcon="$output/icon-missing.txt"
auxTxt="aux.txt"


function get_files {
  if [ "$extDistinct" = "0" ]; then
    name="-iname"
  else
    name="-name"
  fi;

  ext=""
  for var2 in "${extensions[@]}"
  do
    ext="$ext$name *.$var2 -o "
  done
  ext=$(echo $ext |sed 's/.\{3\}$//')

  tmpFiles=($(find ${inputDir[@]} -type f ${ext[@]}))
}

function extract {
  echo
  echo
  echo $"$(tput setaf 2)Extracting...$(tput sgr 0)"
  echo

  mkdir -p $extractedSvgs

  for var4 in $(cat $matchedIcon)
  do
    cp $svgs/$var4.svg $extractedSvgs &>/dev/null
  done

  echo
  echo
  echo $"$(tput setaf 2)Done$(tput sgr 0)"
  echo
  echo
  echo -n "Press ENTER..."
  read -rs input
}

function scan {
  echo
  echo
  echo $"$(tput setaf 2)Scaning...$(tput sgr 0)"
  echo

  mkdir -p $inputDir $svgs

  for i in "${inputDir[@]}"
  do
    echo -n "$(tput setaf 3)$i$(tput sgr 0), "
  done
  echo
  echo
  
  get_files
  
  unset matchFiles
  fileList="0"
  aux=""

  if [ "${#tmpFiles[@]}" != 0 ]; then 

    mkdir -p $output
    truncate -s0 $iconFound
    truncate -s0 $matchedIcon
    truncate -s0 $missingIcon
    truncate -s0 $auxTxt

    # Prepare string of prefixes for grep command
    prefixToFind=${prefix[0]}
    for (( i=1; i<${#prefix[*]} ; i++ ))
    do
      prefixToFind="$prefixToFind|${prefix[i]}"
    done

    for (( i=0; i<${#tmpFiles[*]} ; i++ ))
    do
      aux="$(cat $iconFound)"

      cat ${tmpFiles[$i]} | tr [:space:] '\n' | tr '"' '\n' | tr "\'" '\n' | grep -oP "(?<=$prefixToFind).*" | sort -u >> $iconFound;

      if [ "$aux" != "$(cat $iconFound)" ]; then
        matchFiles[$i]="${tmpFiles[$i]}"
      fi;
    done
    
    cat $iconFound | sort -u > $auxTxt
    cat $auxTxt > $iconFound
    
    if [ "${#matchFiles[@]}" != 0 ]; then
      fileList="$(echo ${matchFiles[@]} | tr [:space:] '\n')"
    else
      fileList="0"
    fi;
    
    rm -f $auxTxt
  
    for var4 in $(cat $iconFound)
    do
      aux=$(find $svgs -type f -name "$var4.svg")
      if [ -z $aux ]; then
        echo $var4 >> $missingIcon
      fi;
    done

    diff $iconFound $missingIcon | grep -oP '(?<=< ).*' > $matchedIcon

    countFound=$(wc -l $iconFound | tr -cd [:digit:];)
    countMatches=$(wc -l $matchedIcon | tr -cd [:digit:];)
    countMissings=$(wc -l $missingIcon | tr -cd [:digit:];)
  
  else
    countFound="0"
    countMatches="0"
    countMissings="0"
  fi; 
  
  
  loop="1"
  while [ $loop = "1" ]
  do
    clear
    clear
    echo
    echo "$(tput setaf 6)Scanned Directories:$(tput sgr 0)"
    echo
    for i in "${inputDir[@]}"
    do
      echo -n "$(tput setaf 3)$i$(tput sgr 0), "
    done
    echo
    echo
    echo "$(tput setaf 6)Files with icons:$(tput sgr 0)"
    echo 
    echo "$(tput setaf 3)$fileList$(tput sgr 0)"
    echo 
    echo "$(tput setaf 6)Found icons:"
    echo
    echo "$(tput setaf 3)$countFound$(tput sgr 0)"
    echo
    echo "$(tput setaf 6)Matched icons:"
    echo
    echo "$(tput setaf 3)$countMatches$(tput sgr 0)"
    echo
    echo "$(tput setaf 6)Missing icons:"
    echo
    echo "$(tput setaf 3)$countMissings$(tput sgr 0)"
    
    if [ "$fileList" != 0 ]; then
      echo
      echo
      echo -n "[$(tput setaf 2)d$(tput sgr 0)] details, [$(tput setaf 2)e$(tput sgr 0)] extract icons, [$(tput setaf 2)q$(tput sgr 0)] quit: "
      read input

      if [ "$input" = "d" -o "$input" = "D" ]; then
        clear
        clear
        echo
        echo "$(tput setaf 6)Matched icons (to be exported):"
        echo
        echo "$(tput setaf 3)$(cat $matchedIcon;)$(tput sgr 0)"
        if [ $countMissings != 0 ]; then
          echo
          echo "$(tput setaf 6)Missing icons (no SVG available):"
          echo
          echo "$(tput setaf 3)$(cat $missingIcon;)$(tput sgr 0)"
        fi;
        echo
        echo
        echo -n "Press ENTER..."
        read -rs input
      elif [ "$input" = "e" -o "$input" = "E" ]; then
        clear
        clear

        extract
      else
        loop="0"
      fi;
    else
      echo
      echo
      echo -n "Press ENTER..."
      read -rs input
      loop="0"
    fi;
  done
}

function start_menu {

  while :
  do
    clear
    clear
    echo
    echo $'\t\t'"$(tput setaf 5)<ICON SUBSET GENERATOR>"
    echo
    echo "    Icon subset generator from website project files$(tput sgr 0)"
    echo
    echo
    echo "$(tput setaf 6)Defined params:$(tput sgr 0)"
    echo
    echo "- Directories to scan  =  $(tput setaf 3)${inputDir[@]}$(tput sgr 0)"
    echo "- Files to be scanned  =  $(tput setaf 3)${extensions[@]}$(tput sgr 0)"
    echo "- Icon prefixes        =  $(tput setaf 3)${prefix[@]}$(tput sgr 0)"
    echo "- SVG location         =  $(tput setaf 3)$svgs$(tput sgr 0)"
    echo "- Output root          =  $(tput setaf 3)$output$(tput sgr 0)"
    echo
    echo
    echo -n "[$(tput setaf 2)run$(tput sgr 0)] run scan, [$(tput setaf 2)exit$(tput sgr 0)] close this tool: "
    read option
    echo $(tput sgr 0)
    
    case $option in

    ("run")
      clear
      clear

      scan;;

    ("exit")
      clear
      clear
      break;;
      
    esac
  done
}

start_menu