#!/bin/bash

CONFIG_DIR="config"

echo -e "\n${BLUE}### Deploying configurations to ~/.config ###${NC}"
cp -rT "$CONFIG_DIR/" "$HOME/.config"
echo -e "${GREEN}All files copied.${NC}"

echo -e "\n${BLUE}### Moving 'ly' configuration to /etc/ ###${NC}"
if [ -d "$HOME/.config/ly" ]; then
    echo -e "${YELLOW}Moving ~/.config/ly to /etc/ly (requires sudo)${NC}"
    sudo cp -rT "$HOME/.config/ly/" "/etc/ly/" && rm -rf "$HOME/.config/ly"
fi

echo -e "\n${GREEN}### Dotfiles deployment complete! ###${NC}"
