from flask import Flask, request
import time
import threading
import os
import subprocess

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

def is_cookie_alive(cookie):
    try:
        result = subprocess.run(
            ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}",
             "-H", f"Cookie: .ROBLOSECURITY={cookie}",
             "-H", "User-Agent: Roblox/Android",
             "https://users.roblox.com/v1/users/authenticated"],
            capture_output=True, text=True, timeout=10
        )
        return result.stdout.strip() == "200"
    except:
        return False

def get_cookie_and_name(clone_id, skip_dead=True):
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
                    cookie = lines[c_index-1]
                    if skip_dead and not is_cookie_alive(cookie):
                        print(f"{RED}  ✗ Cookie for {clone_id} is DEAD. Skipping...{RESET}", flush=True)
                        return None, None
                    return "Normal_Mode", cookie
        return None, None
    else:
        combo_file = os.path.join(CONFIG_DIR, "AutoSwitch", f"{clone_id}.txt")
        if not os.path.exists(combo_file):
            return None, None

        with open(combo_file, "r") as f:
            lines = [l for l in f.read().splitlines() if l.strip()]
        if len(lines) == 0:
            return None, None

        total = len(lines)
        curr_line = clients_combo_index.get(clone_id, 0)
        checked = 0

        while checked < total:
            safe_line = curr_line % total
            line_data = lines[safe_line]
            parts = line_data.split(':', 2)

            if len(parts) == 3:
                name, cookie = parts[0], parts[2]
            else:
                name, cookie = "Unknown", line_data

            if skip_dead:
                if is_cookie_alive(cookie):
                    return name, cookie
                else:
                    print(f"{RED}  ✗ [{name}] Cookie DEAD. Trying next...{RESET}", flush=True)
                    clients_combo_index[clone_id] = curr_line + 1
                    curr_line += 1
                    checked += 1
                    time.sleep(0.5)
            else:
                return name, cookie

        print(f"{RED}  ✗ All cookies in {clone_id} are DEAD!{RESET}", flush=True)
        return None, None

def fix_permissions(path, data_dir):
    uid_cmd = f"su -c 'stat -c %u {data_dir}'"
    app_uid = os.popen(uid_cmd).read().strip()
    if app_uid:
        os.system(f"su -c 'chown {app_uid}:{app_uid} {path}'")
        os.system(f"su -c 'chmod 660 {path}'")

def inject_cookie(package_name, clone_id, acc_cookie, acc_name):
    data_dir = f"/data/data/{package_name}"
    xml_dir = f"{data_dir}/shared_prefs"
    xml_path = f"{xml_dir}/com.roblox.client_preferences.xml"
    xml_content = f"<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n<map>\n    <string name=\".ROBLOSECURITY\">{acc_cookie}</string>\n</map>"
    tmp_path = f"{CONFIG_DIR}/tmp_{clone_id}.xml"

    with open(tmp_path, "w") as tf:
        tf.write(xml_content)

    os.system(f"su -c 'mkdir -p {xml_dir}'")
    os.system(f"su -c 'rm -f {xml_path}'")
    os.system(f"su -c 'cat {tmp_path} > {xml_path}'")
    fix_permissions(xml_path, data_dir)
    os.system(f"rm -f {tmp_path}")
    print(f"{CYAN}  ↳ Cookie injected: {acc_name}{RESET}", flush=True)

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
                        time.sleep(2)

                        acc_name, acc_cookie = get_cookie_and_name(clone_id)
                        map_id = get_map_id()

                        if acc_cookie:
                            inject_cookie(package_name, clone_id, acc_cookie, acc_name)
                            if map_id:
                                os.system(f"su -c 'am start -a android.intent.action.VIEW -d \"roblox://placeId={map_id}\" -p {package_name}'")
                            else:
                                os.system(f"su -c 'monkey -p {package_name} -c android.intent.category.LAUNCHER 1'")

                            if cfg["LAUNCH_DELAY"] > 0:
                                print(f"{YELLOW}  ↳ Cooldown: Waiting {cfg['LAUNCH_DELAY']}s...{RESET}", flush=True)
                                time.sleep(cfg["LAUNCH_DELAY"])
                        else:
                            print(f"{RED}  ✗ No valid cookie available for {clone_id}. Skipping launch.{RESET}", flush=True)

                    clients_last_seen[clone_id] = time.time() + 30
                    clients_retry_count[clone_id] = retry_count + 1
                else:
                    print(f"{RED}[{display_name}] Suspended for 5 mins.{RESET}", flush=True)
                    clients_last_seen[clone_id] = current_time + 300
        time.sleep(2)

if __name__ == '__main__':
    threading.Thread(target=auto_rejoin_checker, daemon=True).start()
    app.run(host='0.0.0.0', port=5000)
