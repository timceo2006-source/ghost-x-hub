#!/bin/bash
echo "Installing packages..."
pkg update -y > /dev/null 2>&1
pkg install python openssh psmisc lsof ncurses-utils curl -y > /dev/null 2>&1
pip install flask > /dev/null 2>&1

BASE="https://raw.githubusercontent.com/timceo2006-source/ghost-x-hub/main"
echo "Downloading server.py..."
curl -s -o server.py "$BASE/server.py"
echo "Downloading checker.sh..."
curl -s -o checker.sh "$BASE/checker.sh"
echo "Downloading start.sh..."
curl -s -o start.sh "$BASE/start.sh"
chmod +x checker.sh start.sh

echo -e "\e[32mSetup complete. Run 'bash start.sh' to open menu.\e[0m"
