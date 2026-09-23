#!/bin/bash

echo "Installing packages..."
pkg update -y > /dev/null 2>&1
pkg install python openssh psmisc lsof ncurses-utils -y > /dev/null 2>&1
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
clients_usernames = {}
clients_combo_index = {}

MAX_RETRIES = 3
CONFIG_DIR = "/storage/emulated/0/GhostXHub"
APPS_PACKAGE_NAMES = {}

GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
CYAN = '\033[96m'
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

def get_settings():
    settings = {"CHECK_INTERVAL": 30, "TIMEOUT": 40, "LAUNCH_DELAY": 20}
    set_file = os.path.join(CONFIG_DIR, "settings.txt")
    if os.path.exists(set_file):
        with open(set_file, "r") as f:
            for line in f:
                if "=" in line:
                    k, v = line.strip().split("=", 1)
                    if k in settings:
                        try: settings[k] = int(v)
                        except: pass
    return settings

def get_map_id():
    map_file = os.path.join(CONFIG_DIR, "map.txt")
    if os.path.exists(map_file):
        with open(map_file, "r") as f:
            return f.read().strip()
    return ""

def get_cookie_and_name(clone_id):
    try:
        c_index = int(clone_id.split('_')[1])
    except:
        c_index = 1

    status_file = os.path.join(CONFIG_DIR, "switch_status.txt")
    switch_on = False
    if os.path.exists(status_file):
        with open(status_file, "r") as f:
            if "ON" in f.read():
                switch_on = True

    if not switch_on:
        cookie_file = os.path.join(CONFIG_DIR, "cookie.txt")
        if os.path.exists(cookie_file):
            with open(cookie_file, "r") as f:
                lines = f.read().splitlines()
                if len(lines) >= c_index:
                    return "Normal_Mode", lines[c_index-1]
        return None, None
    else:
        combo_file = os.path.join(CONFIG_DIR, "AutoSwitch", f"{clone_id}.txt")
        curr_line = clients_combo_index.get(clone_id, 0)
        if os.path.exists(combo_file):
            with open(combo_file, "r") as f:
                lines = [l for l in f.read().splitlines() if l.strip()]
                if len(lines) == 0:
                    return None, None
                safe_line = curr_line % len(lines)
                line_data = lines[safe_line]
                parts = line_data.split(':', 2)
                if len(parts) == 3:
                    return parts[0], parts[2]
                else:
                    return "Unknown", line_data
        return None, None

load_apps()

for cid in APPS_PACKAGE_NAMES.keys():
    clients_last_seen[cid] = 0
    clients_retry_count[cid] = 0
    clients_usernames[cid] = cid
    clients_combo_index[cid] = 0

@app.route('/heartbeat', methods=['POST'])
def heartbeat():
    data = request.json
    clone_id = data.get("clone_id")
    username = data.get("username")
    if clone_id:
        clients_last_seen[clone_id] = time.time()
        clients_retry_count[clone_id] = 0
        if username:
            clients_usernames[clone_id] = username
    return "OK", 200

@app.route('/task_complete', methods=['POST'])
def task_complete():
    data = request.json
    clone_id = data.get("clone_id")
    if clone_id:
        display_name = clients_usernames.get(clone_id, clone_id)
        print(f"\n{CYAN}=========================================={RESET}")
        print(f"{CYAN}🎉 [{display_name}] FINISHED TASK! Switching account...{RESET}")
        print(f"{CYAN}=========================================={RESET}\n", flush=True)
        clients_combo_index[clone_id] = clients_combo_index.get(clone_id, 0) + 1
        clients_last_seen[clone_id] = 0
    return "OK", 200

def auto_rejoin_checker():
    time.sleep(3)
    last_report_time = 0

    while True:
        current_time = time.time()
        cfg = get_settings()

        if current_time - last_report_time >= cfg["CHECK_INTERVAL"]:
            print(f"\n{CYAN}--- [ STATUS REPORT ] ---{RESET}")
            for cid in APPS_PACKAGE_NAMES.keys():
                l_seen = clients_last_seen.get(cid, 0)
                d_name = clients_usernames.get(cid, cid)
                if l_seen == 0 or (current_time - l_seen) > cfg["TIMEOUT"]:
                    print(f"{RED}✗ [{d_name}] OFFLINE (Rejoining soon...){RESET}")
                else:
                    print(f"{GREEN}✓ [{d_name}] ONLINE{RESET}")
            print(f"{CYAN}-------------------------{RESET}\n", flush=True)
            last_report_time = current_time

        for clone_id, last_seen in list(clients_last_seen.items()):
            if current_time - last_seen > cfg["TIMEOUT"]:
                retry_count = clients_retry_count.get(clone_id, 0)
                display_name = clients_usernames.get(clone_id, clone_id)

                if retry_count < MAX_RETRIES:
                    if retry_count == 0:
                        print(f"{YELLOW}▶ [{display_name}] Starting App...{RESET}", flush=True)
                    else:
                        print(f"{YELLOW}▶ [{display_name}] Disconnected. Retry: {retry_count}/{MAX_RETRIES}{RESET}", flush=True)

                    package_name = APPS_PACKAGE_NAMES.get(clone_id)
                    if package_name:
                        os.system(f"su -c 'am force-stop {package_name}'")
                        time.sleep(1.5)

                        acc_name, acc_cookie = get_cookie_and_name(clone_id)
                        map_id = get_map_id()

                        if acc_cookie:
                            print(f"{CYAN}  ↳ Injecting Cookie via Intent: {acc_name}{RESET}", flush=True)
                            uri = f"roblox://placeId={map_id}" if map_id else "roblox://"
                            intent_cmd = f"su -c 'am start -a android.intent.action.VIEW -d \"{uri}\" --es \".ROBLOSECURITY\" \"{acc_cookie}\" -p {package_name}'"
                            os.system(intent_cmd)
                        else:
                            if map_id:
                                os.system(f"su -c 'am start -a android.intent.action.VIEW -d \"roblox://placeId={map_id}\" -p {package_name}'")
                            else:
                                os.system(f"su -c 'monkey -p {package_name} -c android.intent.category.LAUNCHER 1'")

                        if cfg["LAUNCH_DELAY"] > 0:
                            print(f"{YELLOW}  ↳ Cooldown: Waiting {cfg['LAUNCH_DELAY']}s...{RESET}", flush=True)
                            time.sleep(cfg["LAUNCH_DELAY"])

                    clients_last_seen[clone_id] = time.time() + 30
                    clients_retry_count[clone_id] = retry_count + 1
                else:
                    print(f"{RED}[{display_name}] Suspended for 5 mins.{RESET}", flush=True)
                    clients_last_seen[clone_id] = current_time + 300
        time.sleep(2)

if __name__ == '__main__':
    threading.Thread(target=auto_rejoin_checker, daemon=True).start()
    app.run(host='0.0.0.0', port=5000)
EOF

echo "Creating start.sh..."
cat << 'EOF' > start.sh
#!/bin/bash
CONFIG_DIR="/storage/emulated/0/GhostXHub"
SWITCH_DIR="$CONFIG_DIR/AutoSwitch"
su -c "mkdir -p $CONFIG_DIR" 2>/dev/null
mkdir -p "$CONFIG_DIR" 2>/dev/null
mkdir -p "$SWITCH_DIR" 2>/dev/null

if [ ! -f "$CONFIG_DIR/settings.txt" ]; then
    echo "CHECK_INTERVAL=30" > "$CONFIG_DIR/settings.txt"
    echo "TIMEOUT=40" >> "$CONFIG_DIR/settings.txt"
    echo "LAUNCH_DELAY=20" >> "$CONFIG_DIR/settings.txt"
fi

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

stty sane 2>/dev/null
tput reset 2>/dev/null
clear

echo -e "${YELLOW}Initializing Ghost X Hub...${RESET}"
kill -9 $(lsof -t -i:5000) 2>/dev/null
su -c 'kill -9 $(lsof -t -i:5000)' 2>/dev/null
fuser -k -9 5000/tcp 2>/dev/null
killall -9 python 2>/dev/null
pkill -9 -f python
killall -9 ssh 2>/dev/null
rm -f "$CONFIG_DIR/tunnel.log"

echo -e "${CYAN}Establishing Secure Tunnel...${RESET}"
ssh -o StrictHostKeyChecking=no -R 80:localhost:5000 serveo.net > "$CONFIG_DIR/tunnel.log" 2>&1 &

for i in {1..10}; do
    url=$(grep -Eo 'https://[^ ]+\.serveousercontent\.com' "$CONFIG_DIR/tunnel.log" | head -n 1)
    if [ -n "$url" ]; then
        su -c "echo '$url' > /storage/emulated/0/Delta/Workspace/server_url.txt"
        break
    fi
    sleep 1
done

scan_apps() {
    stty sane 2>/dev/null
    clear
    echo -e "${CYAN}====================================${RESET}"
    echo -e "${YELLOW}  Scanning for Roblox Apps...${RESET}"
    echo -e "${CYAN}====================================${RESET}"

    > "$CONFIG_DIR/apps.txt"
    su -c 'pm list packages' | grep -i roblox | cut -d':' -f2 | tr -d '\r' | tr -d ' ' > "$CONFIG_DIR/apps.txt"

    app_count=$(grep -c . "$CONFIG_DIR/apps.txt")
    if [ "$app_count" -gt 0 ]; then
        echo -e "${GREEN}  Found $app_count App(s):${RESET}"
        local i=1
        while IFS= read -r pkg; do
            if [ -n "$pkg" ]; then
                echo -e "  [$i] ${GREEN}$pkg${RESET}"
                i=$((i+1))
            fi
        done < "$CONFIG_DIR/apps.txt"
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
    stty sane 2>/dev/null
    clear

    SWITCH_STATUS=$(cat "$CONFIG_DIR/switch_status.txt" 2>/dev/null || echo "OFF")
    if [ "$SWITCH_STATUS" == "ON" ]; then
        MODE_COLOR="${GREEN}ON${RESET}"
    else
        MODE_COLOR="${RED}OFF${RESET}"
    fi

    echo -e "${GREEN}====================================${RESET}"
    echo -e "${GREEN}          GHOST X HUB MENU          ${RESET}"
    echo -e "${GREEN}====================================${RESET}"
    echo -e "  [Current Mode: Auto-Switch is $MODE_COLOR]"
    echo -e "${GREEN}====================================${RESET}"
    echo -e "  [1] Start System"
    echo -e "  [2] Refresh/Scan Roblox Apps"
    echo -e "  [3] Setup Cookies & Map Config"
    echo -e "  [4] Tool Settings (Timeouts/Delays)"
    echo -e "  [6] Kill All Roblox Apps"
    echo -e "  [7] Toggle Auto-Switch Mode"
    echo -e "  [0] Exit"
    echo -e "${GREEN}====================================${RESET}"
    read -p "  Select Option: " opt

    case $opt in
        1)
            app_count=$(grep -c . "$CONFIG_DIR/apps.txt")
            if [ "$SWITCH_STATUS" == "OFF" ]; then
                cookie_count=$(grep -c . "$CONFIG_DIR/cookie.txt" 2>/dev/null || echo 0)
                if [ "$cookie_count" -lt "$app_count" ] || [ "$cookie_count" -eq 0 ]; then
                    echo -e "\n${RED}  [Error] Normal mode: Missing cookies!${RESET}"
                    sleep 3
                    continue
                fi
            else
                if [ ! -f "$SWITCH_DIR/clone_1.txt" ]; then
                    echo -e "\n${RED}  [Error] Switch mode: No combo files found!${RESET}"
                    sleep 3
                    continue
                fi
            fi

            stty sane 2>/dev/null
            clear

            python -u server.py &
            PY_PID=$!

            echo -e "\n${CYAN}====================================${RESET}"
            echo -e "${GREEN}  ▶ SYSTEM IS RUNNING!${RESET}"
            echo -e "${YELLOW}  Mode: $( [ "$SWITCH_STATUS" == "ON" ] && echo "Auto-Switch" || echo "Normal" )${RESET}"
            echo -e "${YELLOW}  Press [ENTER] to STOP and return to Menu${RESET}"
            echo -e "${CYAN}====================================${RESET}\n"

            read -r

            echo -e "${RED}Stopping System...${RESET}"
            kill -9 $PY_PID 2>/dev/null
            pkill -9 -f server.py 2>/dev/null
            sleep 1
            ;;
        2)
            scan_apps
            ;;
        3)
            stty sane 2>/dev/null
            clear
            app_count=$(grep -c . "$CONFIG_DIR/apps.txt")
            echo -e "${CYAN}====================================${RESET}"
            echo -e "${YELLOW}  Setup Normal Cookies for $app_count Clones${RESET}"
            echo -e "${CYAN}====================================${RESET}"

            > "$CONFIG_DIR/cookie.txt"

            for i in $(seq 1 $app_count); do
                pkg=$(sed -n "${i}p" "$CONFIG_DIR/apps.txt")
                echo -e "\n${GREEN}Clone $i (${pkg})${RESET}"
                read -p "  Paste Cookie: " cookie_data </dev/tty
                echo "$cookie_data" >> "$CONFIG_DIR/cookie.txt"
            done

            echo -e "\n${CYAN}====================================${RESET}"
            read -p "  Enter Map ID (Leave blank to skip): " map_data </dev/tty
            if [ -n "$map_data" ]; then
                echo "$map_data" > "$CONFIG_DIR/map.txt"
            else
                > "$CONFIG_DIR/map.txt"
            fi

            echo -e "\n${GREEN}  Config saved successfully!${RESET}"
            sleep 2
            ;;
        4)
            stty sane 2>/dev/null
            clear
            echo -e "${CYAN}====================================${RESET}"
            echo -e "${YELLOW}  Global Settings Configuration${RESET}"
            echo -e "${CYAN}====================================${RESET}"

            read -p "  Status Check Interval (secs) [Default 30]: " val1 </dev/tty
            read -p "  Timeout Threshold (secs) [Default 40]: " val2 </dev/tty
            read -p "  Launch Cooldown (secs) [Default 20]: " val3 </dev/tty

            val1=${val1:-30}
            val2=${val2:-40}
            val3=${val3:-20}

            echo "CHECK_INTERVAL=$val1" > "$CONFIG_DIR/settings.txt"
            echo "TIMEOUT=$val2" >> "$CONFIG_DIR/settings.txt"
            echo "LAUNCH_DELAY=$val3" >> "$CONFIG_DIR/settings.txt"

            echo -e "\n${GREEN}  Settings saved successfully!${RESET}"
            sleep 2
            ;;
        6)
            echo -e "\n${RED}  Killing all Roblox apps...${RESET}"
            su -c 'pm list packages | grep roblox | cut -d":" -f2 | xargs -I {} am force-stop {}'
            echo -e "${GREEN}  All Roblox processes cleared!${RESET}"
            sleep 2
            ;;
        7)
            stty sane 2>/dev/null
            clear
            if [ "$SWITCH_STATUS" == "OFF" ]; then
                echo "ON" > "$CONFIG_DIR/switch_status.txt"
                app_count=$(grep -c . "$CONFIG_DIR/apps.txt")
                for i in $(seq 1 $app_count); do
                    touch "$SWITCH_DIR/clone_${i}.txt"
                done
                echo -e "${CYAN}====================================${RESET}"
                echo -e "${GREEN}  Auto-Switch Mode: ENABLED!${RESET}"
                echo -e "${YELLOW}  Files created in GhostXHub/AutoSwitch/${RESET}"
                echo -e "\n${YELLOW}  Format => Username:Password:Cookie${RESET}"
                echo -e "${CYAN}====================================${RESET}"
            else
                echo "OFF" > "$CONFIG_DIR/switch_status.txt"
                echo -e "${CYAN}====================================${RESET}"
                echo -e "${RED}  Auto-Switch Mode: DISABLED!${RESET}"
                echo -e "${CYAN}====================================${RESET}"
            fi
            read -p "  Press [ENTER] to return..." </dev/tty
            ;;
        0)
            stty sane 2>/dev/null
            clear
            exit 0
            ;;
        *)
            echo -e "\n${RED}  Invalid Option!${RESET}"
            sleep 1
            ;;
    esac
done
EOF

chmod +x start.sh

echo -e "\e[32mSetup complete. Run 'bash start.sh' to open menu.\e[0m"
