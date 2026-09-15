# Cyberpunk-2077-Linux-Modding-Scripts
Mod Cyberpunk 2077 In Linux Using Scripts

Written by Johan Maree (motivated by my brother).

BLUF:
2077_snapshot.sh: Creates uncompressed backups of your game folder. The first backup is full size; all subsequent snapshots use hardlinks to take up near-zero extra disk space. Restores cleanly by scrubbing modified files.
2077_framework_mod_install.sh: Deploys essential framework dependencies in strict execution order, validates file integrity, and configures Wine/Proton DLL overrides automatically.
2077_generic_mod_install.sh: Scans your staging folder, unpacks, deploys via rsync, and verifies arbitrary Nexus .zip archives.

Even after mods are deployed and DLL overrides are applied, use these launch options in Steam for optimal Proton/DXVK performance and zero launcher fluff:
gamemoderun %command% -dx12 --launcher-skip -skipStartScreen

Prerequisites: These scripts rely heavily on rsync and unzip. Ensure they are installed via your package manager.
Environment: Assumes Cyberpunk 2077 is installed via Steam on a single drive ($HOME/.steam/debian-installation/...). Adjust CP2077_DIR inside the scripts if your Steam library lives on another mount point.

Manual Downloading: Due to Nexus API restrictions/403 blocks, all mods must be manually downloaded as .zip files and placed into the designated staging folders outlined in the scripts.

Please read the scripts before running! There are important instructions!

Read Before Running: I encourage anyone and everyone to carefully read each line of these scripts before execution. I've added comments explaining what every single command does. Never blindly trust shell scripts from the internet. No sudo is involved, so your system files remain completely untouched.

Shell Compatibility: Written specifically for Bash. If Bash isn't your default shell, execute scripts explicitly:
bash script.sh

You do not have to clone this repo if you don't want - copy it right from the github menus and just make sure you do a "chmod +x" to the scripts. 

_____________________________________________________________________________

SNAPSHOT:
Creating a snapshot:
This tool creates instant, uncompressed backup states of your game directory using rsync --link-dest.
2077_snapshot.sh backup
The initial baseline backup will take standard space (~86 GB). Subsequent snapshots hardlink unchanged files, taking only seconds to build and consuming virtually 0 MB of extra disk space.
Restoring a snapshot:
2077_snapshot.sh restore
Interactively select a snapshot state to restore. It will scrub any modified/added files in your game directory back to that exact baseline. Ideal for testing experimental mod lists risk-free.


FRAMEWORKS:
This is a dependency deployer.
Installs the 8 core framework mods in their strictly required load order:
1. Cyber Engine Tweaks (CET)
2. RED4ext
3. redscript
4. ArchiveXL
5. TweakXL
6. Codeware
7. ModSettings
8. Native Settings UI
Download the framework zip files into the ~/Downloads/CP2077_Framework_mods/ folder and run the script.
Note: This script automatically handles the version.dll Proton override for CET directly via Wine registry hooks, eliminating the need for Protontricks or bloated launch strings.

OTHER MODS:
This one is very easy: 
Drop your downloaded mod .zip archives directly into ~/Downloads/CP2077_Mods/ folder and run the script.



License:

Open-source / Edit, strip, adapt, and modify as you see fit.