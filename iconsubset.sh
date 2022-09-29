#!/bin/bash

#*****************************************#
#          ICON SUBSET GENERATOR          #
#                                         #
# Author: Oscar Olivares                  #
# Email: oscarolivares625@gmail.com       #
# Date: 27 de Septiembre del 2022         #
#*****************************************#


#--------- Configs ----------#

#### General config ####
# Root directories to scan (will be scanned recursively)
inputDir=("./input")

# Extensions of the files to be scanned
extensions=("html" "php" "js" "json")
#Case sensitive extensions scanning, set "0" to disable
extDistinct="1"

# Icon prefixes to look for
prefix=("fa-")

# Input SVG location
svgs="./svgs"

# Script output folder
output="./output"

#### Icon subset results ####
# css output folder (may be different than output folder)
faCssDir="$output/css"

# Font output folder (may be different than output folder)
faFontDir="$output/font"

# Font src url in css classes (Font folder path is relative to css output folder)
faFontsUrl="../$(echo $faFontDir | rev | cut -d '/' -f 1 | rev )"
#faFontsUrl="../font"

#-------- End Configs --------#

while getopts i:e:p:s:o: flag
do
    case "${flag}" in
        i) inputDir=(${OPTARG});;
        e) extensions=(${OPTARG});;
        p) prefix=(${OPTARG});;
        s) svgs=${OPTARG};;
        o) output=${OPTARG};;

        *)
          exit 1
        ;;
    esac
done


iconFound="$output/icon-found.txt"
matchedIcon="$output/icon-matching.txt"
missingIcon="$output/icon-missing.txt"
auxTxt="aux.txt"
extractedSvgs="$output/svgs"

faCONF=$(cat << END
module.exports = {
  inputDir: '$extractedSvgs',
  outputDir: '$faFontDir',
  fontTypes: ['eot', 'ttf', 'woff', 'woff2', 'svg'],
  assetTypes: ['css'],
  fontsUrl: '$faFontsUrl',
  pathOptions: {
    css: '$faCssDir/icons.css',
  },
};
END
)

# Get files to be scanned
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

# Extract matching svg
function extract {
  mkdir -p $extractedSvgs

  for var4 in $(cat $matchedIcon)
  do
    cp $svgs/$var4.svg $extractedSvgs &>/dev/null
  done
}

# Scan files and get icon matches
function scan {
  mkdir -p $inputDir $svgs
  
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
}

# Generate fonts and css
function compile {
  mkdir -p $faFontDir $faCssDir

  truncate -s0 "$output/.fantasticonrc"
  truncate -s0 "$faCssDir/icons.css"
  echo "$faCONF" > "$output/.fantasticonrc"

  fantasticon --config "$output/.fantasticonrc"
}

# Scan messages
function scan_verbose {
  clear
  clear
  echo $"$(tput setaf 6)Scaning...$(tput sgr 0)"
  echo
  
  scan

  while :
  do
    if [ "$fileList" != 0 ]; then
      clear
      clear
      echo
      echo "$(tput setaf 6)Files with icons:$(tput sgr 0)"
      echo 
      echo "$fileList"
      echo 
      echo "$(tput setaf 6)Found icons:$(tput sgr 0)"
      echo
      echo "$countFound"
      echo
      echo "$(tput setaf 6)Matched icons:$(tput sgr 0)"
      echo
      echo "$countMatches"
      echo
      echo "$(tput setaf 6)Missing icons:$(tput sgr 0)"
      echo
      echo "$countMissings"
      echo
      echo
      echo -n "[$(tput setaf 2)d$(tput sgr 0)] details, [$(tput setaf 2)r$(tput sgr 0)] return, [$(tput setaf 2)q$(tput sgr 0)] quit: "
      read -n1 input

      if [ "$input" = "d" -o "$input" = "D" ]; then
        input=""
        until [ $input == "r" ]
        do
          clear
          clear
          echo
          echo "$(tput setaf 6)Matched icons (to be exported):$(tput sgr 0)"
          echo
          echo "$(cat $matchedIcon;)"
          if [ $countMissings != 0 ]; then
            echo
            echo "$(tput setaf 6)Missing icons (no SVG available):$(tput sgr 0)"
            echo
            echo "$(cat $missingIcon;)"
          fi;
          echo
          echo
          echo -n "[$(tput setaf 2)r$(tput sgr 0)] return: "
          read -n1 input
        done
      elif [ "$input" = "r" -o "$input" = "R" ]; then
        break
      elif [ "$input" = "q" -o "$input" = "Q" ]; then
        exit
      fi;
    else
      clear
      clear
      echo $"$(tput setaf 3)no icons found$(tput sgr 0)"
      echo
      echo
      echo -n "Press ENTER..."
      read -rs input
      break
    fi;
  done
}

# Extract messages
function extract_verbose {
  clear
  clear
  echo $"$(tput setaf 6)Scaning...$(tput sgr 0)"
  echo
  
  scan
  
  if [ "$fileList" != 0 ]; then
    echo $"$(tput setaf 2)done$(tput sgr 0)"
    echo
    echo $"$(tput setaf 6)Extracting...$(tput sgr 0)"
    echo

    extract

    clear
    clear
    echo $"$(tput setaf 2)success$(tput sgr 0)"
    echo
    echo
    echo "$(tput setaf 6)$countMatches icons were extracted in $extractedSvgs $(tput sgr 0)"
  else
    clear
    clear
    echo $"$(tput setaf 3)nothing to do (no icons found)$(tput sgr 0)"
  fi
  echo
  echo
  echo -n "Press ENTER..."
  read -rs input
}

# Compile messages
function compile_verbose {
  clear
  clear
  echo $"$(tput setaf 6)Scaning...$(tput sgr 0)"
  echo
  
  scan
  
  if [ "$fileList" != 0 ]; then
    echo $"$(tput setaf 2)done$(tput sgr 0)"
    echo
    echo $"$(tput setaf 6)Extracting...$(tput sgr 0)"
    echo

    extract

    echo $"$(tput setaf 2)done$(tput sgr 0)"
    echo
    #echo $"$(tput setaf 6)Compiling...$(tput sgr 0)"
    #echo

    compile

  else
    clear
    clear
    echo $"$(tput setaf 3)nothing to do (no icons found)$(tput sgr 0)"
  fi
  echo
  echo
  echo -n "Press ENTER..."
  read -rs input
}

# Main
function start {
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
    echo "- Directories to scan  =  $(tput setaf 4)${inputDir[@]}$(tput sgr 0)"
    echo "- Files to be scanned  =  $(tput setaf 4)${extensions[@]}$(tput sgr 0)"
    echo "- Icon prefixes        =  $(tput setaf 4)${prefix[@]}$(tput sgr 0)"
    echo "- SVG location         =  $(tput setaf 4)$svgs$(tput sgr 0)"
    echo "- Output root          =  $(tput setaf 4)$output$(tput sgr 0)"
    echo
    echo
    echo -n "[$(tput setaf 2)s$(tput sgr 0)] scan, [$(tput setaf 2)e$(tput sgr 0)] extract, [$(tput setaf 2)c$(tput sgr 0)] compile, [$(tput setaf 2)q$(tput sgr 0)] quit: "
    read -n1 option
    echo $(tput sgr 0)
    
    case $option in

    ("s"|"S")
      scan_verbose;;

    ("e"|"E")
      extract_verbose;;

    ("c"|"C")
      compile_verbose;;

    ("q"|"Q")
      clear
      clear
      exit;;
    esac
  done
}

start