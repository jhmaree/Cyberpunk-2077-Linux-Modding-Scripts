#!/bin/bash

# Few caveats: 
# This script uses rsync so please download that through terminal first
# There are a ton of comments because those using this script shouldn't follow it blindly - understand what it's doing and PLEASE scrutinize. If you don't like something, find an alternative way to do it or look up what it does and learn more

# This is where 2077 is installed on a single drive through steam. If you have it installed somewhere else, just point to that instead. 
CP2077_DIR="$HOME/.steam/debian-installation/steamapps/common/Cyberpunk 2077"
## MOVE YOUR ZIP FILES TO THIS FOLDER!!!!!!!!!!!!!
STAGING_DIR="$HOME/Downloads/CP2077_Mods"
TEMP_DIR="/tmp/cp2077_local_staging"

# Colors for terminal output
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
RESET='\e[0m'

# Make the temp dir
mkdir -p "$TEMP_DIR"

# Check if 2077 is installed
if [ ! -d "$CP2077_DIR" ]; then
    echo -e "${RED}Error: Cyberpunk 2077 directory not found at $CP2077_DIR${RESET}"
    exit 1
fi

# Create install function
install_mod_function() {
    # Setup vars
    local name="$1"
    local zip_file="$2"
    local target_dir="$3"

    # This reads as "I have a zip file, it'll take the zip file and make a directory of it" 
    echo -e "${GREEN}[+] Processing $name...${RESET}"
    local extract_dir="$TEMP_DIR/${name}_extracted"

    # Make and extract to the extract dir
    mkdir -p "$extract_dir" 
    unzip -q -o "$zip_file" -d "$extract_dir"

    # This step is to map the files/audit them for verfication after the rsync
    # Reads as (you have to read this somewhat backwards):
    # 1. Go into the extract_dir and finds all files within it
    # 2. Take the previous input and uses sed (the pipes are the delimeters here rather than the standard /) to match the start of the line, that matches a literal "." and then a /, then replaces that with nothing. So ./ becomes nothing
    # 3. The weird overall thing of < <(...) isn't tank shooting a round, it's a bash specific feature called Process Substitution: does a weird thing of making whatever is in the parentheses and redirects it backwards. This allows you to use command outputs into other commands that normally only work with files
    # 4. map the files (aka readarray) and stores them as arrays, in this case "mod_files"
    mapfile -t mod_files < <(cd "$extract_dir" && find . -type f | sed 's|^\./||')

    # Copy the files from the mod to your 2077 folder. 
    rsync -av --no-perms --no-owner --no-group "$extract_dir/" "$target_dir/"

    # Verification step 
    local missing_count=0
    echo -e "  ${YELLOW}[?] Verifying installation of $name...${RESET}"
    
    # For every relevant file in the variable mod_files (that's what the @ does), check to see if it's in the 2077 dir. If not, it'll print out. It also increases the missing_count by 1 every time, causing an exit 1 and stopping the script. Safety net!
    for rel_file in "${mod_files[@]}"; do
        if [ ! -f "$target_dir/$rel_file" ]; then
            echo -e "      ${RED}[MISSING] $rel_file${RESET}"
            ((missing_count++))
        fi
    done

    if [ "$missing_count" -eq 0 ]; then
        echo -e "  ${GREEN}[✓] Verified ${#mod_files[@]} file(s) for $name.${RESET}\n"
        echo -e "${GREEN}[✓] $name installed successfully.${RESET}"
    else
        echo -e "  ${RED}[!] Verification failed: $missing_count file(s) missing for $name.${RESET}\n"
        exit 1
    fi
}

# Loop over all zip files dropped into the staging folder and then use the install function to install them.
for zip_path in "$STAGING_DIR"/*.zip; do
    [ -e "$zip_path" ] || continue
    
    mod_name=$(basename "$zip_path" .zip)
    echo -e "${YELLOW}[+] Found local mod archive: $mod_name${RESET}"
    
    # Pass the local zip path directly into your install/verification function
    install_mod_function "$mod_name" "$zip_path" "$CP2077_DIR"
done

# Clean up
rm -rf "$TEMP_DIR"
echo -e "${GREEN}==> You installed additional mods! Now get out there and fuck, marry, kill!${RESET}"