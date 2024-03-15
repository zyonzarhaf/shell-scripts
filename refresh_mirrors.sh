#!/bin/bash

# refresh_mirrors - A script to prompt the user for country-specific mirrors

ROOT_UID=0
E_NOTROOT=87

# Check root privileges
if [ $UID -ne $ROOT_UID ]; then
    echo "Must be root to run this script."
    exit $E_NOTROOT
fi

echo "
    -----------------------------------------------
    Prompting the user for country-specific mirrors
    -----------------------------------------------
"

mirrors=()
selected_mirrors=()
selected_mirrors_string=
continue=true
IFS=$'\n' read -r -d '' -a mirrors < <( reflector --list-countries | tail -n +3 | sed -E 's/([A-Z]{2}|\b[0-9]+\b)//g' && printf '\0' )

while $continue
do
    PS3="Select a country from the list: "
    select m in "${mirrors[@]}" # This will add extra space characters at the end of the country
    do
        echo "Selected mirror: $m"
        selected_mirrors+=("$(echo "$m" | sed 's/[[:space:]]*$//')") # This will remove them
        break
    done
    read -r -p "Select additional country? (y/n): " reply
    clear
    if [ "$reply" != "y" ]; then continue=false; fi
done

selected_mirrors_string="${selected_mirrors[0]}"

for (( i = 1; i < "${#selected_mirrors[@]}"; i++ ))
do 
    selected_mirrors_string+=",${selected_mirrors[$i]}"
done

pacman -Qi reflector rsync &> /dev/null
[ $? -eq 1 ] && pacman -S --no-confirm reflector rsync
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
reflector --country "$selected_mirrors_string" --save /etc/pacman.d/mirrorlist
pacman -Sy

exit
