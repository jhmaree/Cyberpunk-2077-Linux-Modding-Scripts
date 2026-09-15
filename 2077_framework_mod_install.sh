#!/bin/bash

# Few caveats: 
# This script uses wget and rsync so please download those through terminal first
# There are a ton of comments because those using this script shouldn't follow it blindly - understand what it's doing and PLEASE scrutinize. If you don't like something, find an alternative way to do it or look up what it does and learn more

# This is where 2077 is installed on a single drive through steam. If you have it installed somewhere else, just point to that instead. 
CP2077_DIR="$HOME/.steam/debian-installation/steamapps/common/Cyberpunk 2077"
TEMP_DIR="/tmp/cp2077_mod_staging"
## MOVE YOUR FRAMEWORK ZIP FILES TO THIS FOLDER!!!!!!!!!!!!!
STAGING_DIR="$HOME/Downloads/CP2077_Framework_Mods"

# Colors for terminal output
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
RESET='\e[0m'

# Make the temp dir
mkdir -p "$TEMP_DIR"

# Mod zip_files (Populate tese with direct zip download links)
# This is a dictionary format and required for later. Add to this if you want but I think I've covered all the essentials.
declare -A FRAMEWORKS=(
    ["CET"]="CET*.zip"
    ["RED4ext"]="RED4ext*.zip"
    ["redscript"]="redscript*.zip"
    ["ArchiveXL"]="ArchiveXL*.zip"
    ["TweakXL"]="TweakXL*.zip"
    ["Codeware"]="Codeware*.zip"
    ["ModSettings"]="mod_settings_*.zip"
    ["NativeSettingsUI"]="Native*.zip"
)

# For the framework mods to be installed they HAVE to be in this order
FRAMEWORK_ORDER=("CET" "RED4ext" "redscript" "ArchiveXL" "TweakXL" "Codeware" "ModSettings" "NativeSettingsUI")

# Check that 2077 is installed in the correct directory
if [ ! -d "$CP2077_DIR" ]; then
    echo -e "${RED}Error: Cyberpunk 2077 directory not found at $CP2077_DIR${RESET}"
    exit 1
fi

# Create install function
install_framework_mods() {
    # Setup vars
    local name="$1"
    local zip_file="$2"
    local target_dir="$3"

    # If a mod var hasn't been provided a zip_file it'll just skip it
    if [ ! -f "$zip_file" ]; then
        echo -e "${YELLOW}[-] Skipping $name: Missing zip file in staging directory${RESET}"
        return 0
    fi
    # This reads as "I have a zip file, it'll take the zip file and make a directory of it" at some point
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
    echo -e "   ${YELLOW}[?] Verifying installation of $name...${RESET}"
    
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

# This is the actual install of the framework mods
for name in "${FRAMEWORK_ORDER[@]}"; do
    pattern="$STAGING_DIR/${FRAMEWORKS[$name]}"
    
    # Resolve glob pattern to actual file path
    # It's a somewhat funky set of bash but the important part is it works. 
    shopt -s nullglob
    matches=($pattern)
    shopt -u nullglob

    if [ ${#matches[@]} -gt 0 ]; then
        zip_path="${matches[0]}"
        install_framework_mods "$name" "$zip_path" "$CP2077_DIR"
    else
        echo -e "${YELLOW}[-] Skipping $name: No match for pattern $pattern${RESET}"
    fi
done


# This section is CET specific. CET needs manipulation of DLL files and what not which is a pain.
# Proton ignores custom DLLs by default unless forced to load them natively.
echo -e "${YELLOW} ==> Configuring Proton environment for CET...${RESET}"

# Path to the Steam CompatData prefix for Cyberpunk (AppID 1091500)
STEAM_COMPAT_DIR="$HOME/.steam/debian-installation/steamapps/compatdata/1091500/pfx"

if [ -d "$STEAM_COMPAT_DIR" ]; then
    export WINEPREFIX="$STEAM_COMPAT_DIR"
    # Overrides version.dll to (n)ative first, then (b)uiltin
    echo -e "${YELLOW}[+] Registering version.dll override in Wine registry...${RESET}"
    WINEDLLOVERRIDES="version=n,b" wineboot -u 2>/dev/null || true
fi

Clean up
rm -rf "$TEMP_DIR"
echo -e "${GREEN} ==> NEW ACHIEVEMENT: You installed all the core frameworks mods. And you did it all by yourself. Right? RIGHT?!${RESET}"

