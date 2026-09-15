#!/bin/bash

# This script is to backup and restore your 2077 folder. Not necessary but kinda handy
# THIS USES rsync TO WORK!!
# There are a ton of comments because those using this script shouldn't follow it blindly - understand what it's doing and PLEASE scrutinize. If you don't like something, find an alternative way to do it or look up what it does and learn more

# Some vars
CP2077_DIR="$HOME/.steam/debian-installation/steamapps/common/Cyberpunk 2077"
BACKUP_DIR="$HOME/CP2077_Mod_Snapshots"

# Colors for terminal output
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
RESET='\e[0m'

# Ensure game directory exists
if [ ! -d "$CP2077_DIR" ]; then
    echo -e "${RED}Error: Cyberpunk 2077 directory not found at $CP2077_DIR${RESET}"
    exit 1
fi

mkdir -p "$BACKUP_DIR"


# This function creates a snapshot that you nme and then uses rsync to make that backup
create_snapshot() {
    # Reads your input for the tag and stores it as "tag"
    read -rp "Enter a label for this snapshot (e.g., clean_base, pre_vortex) and don't use spaces or special characters, please: " tag
    # replace spaces with underscores and drop special chars if you can't follow instructions, you bellend
    tag=$(echo "$tag" | tr ' ' '_' | sed 's/[^a-zA-Z0-9_]//g')
    
    # If you put nothing because you hit enter too quickly, you eager beaver, this still saves the tag as "snapshot"
    if [ -z "$tag" ]; then
        tag="snapshot"
    fi

    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local dest_folder="$BACKUP_DIR/${tag}_${timestamp}"

    echo -e "\n${YELLOW}==> Creating snapshot: ${timestamp}_${tag}...${RESET}"
    
    # Check if a previous snapshot exists and uses hardlinks
    # This saves on disk space for if you make a snapshot for every mod you install, one by one, like soldiers marching to their doom, one by one...
    local latest_backup
    latest_backup=$(ls -dt "$BACKUP_DIR"/*/ 2>/dev/null | head -n 1)

    # the --link-dest makes sure that you create hard links to previous backups
    if [ -n "$latest_backup" ]; then
        echo "[+] Previous snapshot found. Using --link-dest to minimize disk usage..."
        rsync -aP --link-dest="$latest_backup" "$CP2077_DIR/" "$dest_folder/"
    else
        echo "[+] No prior snapshot found. Performing full initial backup..."
        rsync -aP "$CP2077_DIR/" "$dest_folder/"
    fi

    echo -e "${GREEN}[✓] Snapshot saved to: $dest_folder${RESET}\n"
}

# If something goes wrong, break glass
restore_snapshot() {
    # List available snapshots by using Position Substituion to make an ls command into a var which is turned into an array by mapfile
    mapfile -t snapshots < <(ls -d "$BACKUP_DIR"/*/ 2>/dev/null)

    # If there's no backup, there's no restore.
    if [ ${#snapshots[@]} -eq 0 ]; then
        echo -e "${RED}[!] No snapshots found in $BACKUP_DIR${RESET}\n"
        return 0
    fi

    echo -e "\n${YELLOW}Available Snapshots:${RESET}"
    # List the snapshots with associated numbers
    for i in "${!snapshots[@]}"; do
        echo "  [$i] $(basename "${snapshots[$i]}")"
    done

    echo ""
    # The while loop is to put you back to this menu in case you SOMEHOW can't select number correctly. Math is hard, I know.
    while true; do
        read -rp "Select snapshot NUMBER to restore: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -lt "${#snapshots[@]}" ]; then
            local selected="${snapshots[$choice]}"
            echo -e "\n${RED}WARNING: Restoring will overwrite modified files in your game folder!${RESET}"
            read -rp "Are you sure you want to proceed? (y/n): " confirm

            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}==> Restoring snapshot: $(basename "$selected")...${RESET}"
                
                # Using --delete ensures any rogue mod files added AFTER the snapshot are wiped
                rsync -aP --delete --no-perms --no-owner --no-group "$selected/" "$CP2077_DIR/"
                
                echo -e "${GREEN}[✓] Game directory restored to snapshot state!${RESET}\n"
                exit 0
            else
                echo "${YELLOW}Restore operation cancelled.${RESET}"
            fi
        else
            echo -e "${RED}Invalid selection.${RESET}"
        fi
    done
}

# If you wanna list your snapshots you can with this
list_snapshots() {
    echo -e "\n${YELLOW}Current Snapshots in $BACKUP_DIR:${RESET}"
    # If block just checks if there's actually anything in there. If yes, it'll give the total size and then list all the snapshots
    if du -sh "$BACKUP_DIR"/* 2>/dev/null; then
        echo ""
        echo -e "${YELLOW}Total Snapshot Directory Size:${RESET} $(du -sh "$BACKUP_DIR" | cut -f1)"
        echo -e "\n${YELLOW}Available Snapshot List:${RESET}"
        i=0
        for snapshot in ${ls "$BACKUP_DIR"}; do
            echo "  [$i] $snapshot
            ((i++))"
        done
    else
        echo "${RED}No snapshots available.${RESET}"
    fi
    echo ""
}

# CLI menu
case "$1" in
    backup|snapshot)
        create_snapshot
        ;;
    restore)
        restore_snapshot
        ;;
    list)
        list_snapshots
        ;;
    *)
        echo -e "${YELLOW}Cyberpunk 2077 Snapshot Manager${RESET}"
        echo "Usage: $0 {backup|restore|list}"
        echo ""
        echo "Commands:"
        echo "  backup  - Create a new timestamped snapshot of the game directory"
        echo "  restore - Choose a snapshot to revert your game directory back to"
        echo "  list    - Display all stored snapshots and total disk usage"
        echo "...entering anything else puts you right back here so... pick from the above"
        echo ""
        ;;
esac