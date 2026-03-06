#!/bin/bash

set -e

export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export NC='\033[0m'

scripts_to_run=(
    "scripts/install-yay.sh"
    "scripts/install-packages.sh"
    "scripts/install-dotfiles.sh"
    "scripts/docker-setup.sh"
)

echo -e "\n${BLUE}### Starting Setup Process ###${NC}"
echo -e "${BLUE}The following scripts will be executed:${NC}"
for s in "${scripts_to_run[@]}"; do
    echo " - $s"
done
echo ""

for script in "${scripts_to_run[@]}"; do
    if [ -f "$script" ]; then
        echo -e "\n${GREEN}--- Running script: $script ---${NC}"
        if bash "$script"; then
            echo -e "${GREEN}--- Finished: $script ---${NC}"
        else
            echo -e "${RED}--- Failed: $script ---${NC}"
        fi
    else
        echo -e "${RED}Error: File not found: $script${NC}"
    fi
done

echo -e "\n${BLUE}### Setup Process Complete! ###${NC}"
echo -e "${BLUE}### Ensure to reboot to finish setup ###${NC}"
