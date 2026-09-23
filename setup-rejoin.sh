#!/bin/bash

echo "Installing packages..."
pkg update -y > /dev/null 2>&1
pkg install python openssh psmisc lsof -y > /dev/null 2>&1
pip install flask > /dev/null 2>&1

echo "Creating server.py..."
cat << 'EOF' > server.py
from flask import Flask, request
import time
import threading
import os

app = Flask(__name__)
clients_last_seen = {}
clients_retry_count = {}
MAX_RETRIES = 3
CONFIG_DIR = "/storage/emulated/0/GhostXHub"
APPS_PACKAGE_NAMES = {}

GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
RESET = '\033[0m'

def load_apps():
    app_file = os.path.join(CONFIG_DIR, "apps.txt")
    APPS_PACKAGE_NAMES.clear()
    if os.path.exists(app_file):
        with open(app_file, "r") as f:
            lines = f.read().splitlines()
            for i, pkg in enumerate(lines):
                if pkg.strip():
                    APPS_PACKAGE_NAMES[f"clone_{i+1}"] = pkg.strip()
    
    if not APPS_PACKAGE_NAMES:
        APPS_PACKAGE_NAMES["clone_1"] = "com.roblox.client"

load_apps()

@app.route('/heartbeat', methods=['POST'])
def heartbeat():
    data = request.json
    clone_id = data.get("clone_id")
    if clone_id:
        clients_last_seen[clone_id] = time.time()
        clients_retry_count[clone_id] = 0 
        print(f"{GREEN}[{clone_id}] Online ({time.strftime('%H:%M:%S')}){RESET}", flush=True)
    return "OK", 200

def auto_rejoin_checker():
    while True:
        current_time = time.time()
        for clone_id, last_seen in list(clients_last_seen.items()):
            if current_time - last_seen > 30:
                retry_count = clients_retry_count.get(clone_id, 0)
                if retry_count < MAX_RETRIES:
                    print(f"{YELLOW}[{clone_id}] Disconnected. Retry: {retry_count + 1}/{MAX_RETRIES}{RESET}", flush=True)
                    package_name = APPS_PACKAGE_NAMES.get(clone_id)
                    if package_name:
                        os.system(f"su -c 'am force-stop {package_name}'")
                        time.sleep(2)
                        os.system(f"su -c 'monkey -p {package_name} -c android.intent.category.LAUNCHER 1'")
                    clients_last_seen[clone_id] = current_time + 60 
                    clients_retry_count[clone_id] = retry_count + 1
                else:
                    print(f"{RED}[{clone_id}] Suspended for 5 mins.{RESET}", flush=True)
                    clients_last_seen[clone_id] = current_time + 300 
        time.sleep(5)

if __name__ == '__main__':
    threading.Thread(target=auto_rejoin_checker, daemon=True).start()
    app.run(host='0.0.0.0', port=5000)
EOF

echo "Creating start.sh..."
cat << 'EOF' > start.sh
#!/bin/bash
CONFIG_DIR="/storage/emulated/0/GhostXHub"
su -c "mkdir -p $CONFIG_DIR" 2>/dev/null
mkdir -p "$CONFIG_DIR" 2>/dev/null

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

scan_apps() {
    clear
    echo -e "${CYAN}====================================${RESET}"
    echo -e "${YELLOW}  Scanning for Roblox Apps...${RESET}"
    echo -e "${CYAN}====================================${RESET}"
    
    # ดึงชื่อแอปและลบตัวอักษรซ่อนเร้น (\r) ที่ทำให้สคริปต์บัคทิ้งให้หมด
    su -c 'pm list packages | grep com.roblox' | cut -d':' -f2 | tr -d '\r' > "$CONFIG_DIR/apps.txt"
    
    app_count=$(cat "$CONFIG_DIR/apps.txt" | wc -l)
    if [ "$app_count" -gt 0 ]; then
        echo -e "${GREEN}  Found $app_count App(s):${RESET}"
        cat "$CONFIG_DIR/apps.txt" | awk '{print "  ["NR"] \033[92m" $0 "\033[0m"}'
    else
        echo -e "${RED}  Warning: No apps found!${RESET}"
        echo "com.roblox.client" > "$CONFIG_DIR/apps.txt"
        echo -e "  [1] Default: com.roblox.client"
    fi
    
    echo -e "\n${YELLOW}  Returning to menu in 3 seconds...${RESET}"
    sleep 3
}

if [ ! -f "$CONFIG_DIR/apps.txt" ]; then
    scan_apps
fi

while true; do
    clear
    echo -e "${GREEN}====================================${RESET}"
    echo -e "${GREEN}          GHOST X HUB MENU          ${RESET}"
    echo -e "${GREEN}====================================${RESET}"
    echo -e "  [1] Start Auto-Rejoin System"
    echo -e "  [2] Refresh/Scan Roblox Apps"
    echo -e "  [3] Setup Cookie & Map Config"
    echo -e "  [0] Exit"
    echo -e "${GREEN}====================================${RESET}"
    read -p "  Select Option [0-3]: " opt

    case $opt in
        1)
            app_count=$(cat "$CONFIG_DIR/apps.txt" | wc -l)
            cookie_count=$(grep -c . "$CONFIG_DIR/cookie.txt" 2>/dev/null || echo 0)
            
            if [ "$cookie_count" -lt "$app_count" ] || [ "$cookie_count" -eq 0 ]; then
                echo -e "\n${RED}  [Error] You have $app_count apps but only $cookie_count cookies set.${RESET}"
                echo -e "${YELLOW}  Please use Option 3 to setup cookies!${RESET}"
                sleep 3
                continue
            fi
            break
            ;;
        2)
            scan_apps
            ;;
        3)
            clear
            app_count=$(cat "$CONFIG_DIR/apps.txt" | wc -l)
            echo -e "${CYAN}====================================${RESET}"
            echo -e "${YELLOW}  Setup Cookies for $app_count Clones${RESET}"
            echo -e "${CYAN}====================================${RESET}"
            
            > "$CONFIG_DIR/cookie.txt" 
            
            # เปลี่ยนมาใช้ for loop ป้องกันบัคข้ามบรรทัด
            for i in $(seq 1 $app_count); do
                pkg=$(sed -n "${i}p" "$CONFIG_DIR/apps.txt")
                echo -e "\n${GREEN}Clone $i (${pkg})${RESET}"
                read -p "  Paste Cookie: " cookie_data
                echo "$cookie_data" >> "$CONFIG_DIR/cookie.txt"
            done
            
            echo -e "\n${CYAN}====================================${RESET}"
            echo -e "${YELLOW}*Tip: You can edit map.txt directly in folder: GhostXHub${RESET}"
            read -p "  Enter Map ID (Leave blank to skip): " map_data
            if [ -n "$map_data" ]; then
                echo "$map_data" > "$CONFIG_DIR/map.txt"
            fi
            
            echo -e "\n${GREEN}  Config saved successfully!${RESET}"
            sleep 2
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "\n${RED}  Invalid Option!${RESET}"
            sleep 1
            ;;
    esac
done

clear
echo -e "${YELLOW}Clearing old processes...${RESET}"
kill -9 $(lsof -t -i:5000) 2>/dev/null
su -c 'kill -9 $(lsof -t -i:5000)' 2>/dev/null
fuser -k -9 5000/tcp 2>/dev/null
killall -9 python 2>/dev/null
pkill -9 -f python
killall -9 ssh 2>/dev/null
killall -9 node 2>/dev/null
sleep 2

echo -e "${GREEN}Starting server...${RESET}"
python -u server.py &
sleep 3

echo -e "${GREEN}Opening tunnel...${RESET}"
ssh -o StrictHostKeyChecking=no -R 80:localhost:5000 serveo.net 2>&1 | grep --line-buffered -Eo 'https://[^ ]+\.serveousercontent\.com' | while read -r url; do
    echo -e "${GREEN}URL: $url${RESET}"
    su -c "echo '$url' > /storage/emulated/0/Delta/Workspace/server_url.txt"
    echo -e "${GREEN}URL saved to workspace.${RESET}"
    break
done &
wait
EOF

chmod +x start.sh

echo -e "\e[32mSetup complete. Run 'bash start.sh' to open menu.\e[0m"
