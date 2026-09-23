#!/bin/bash

echo "Installing packages..."
pkg update -y > /dev/null 2>&1
# เพิ่ม lsof เข้าไปในชุดติดตั้ง
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
APPS_PACKAGE_NAMES = {
    "clone_1": "com.roblox.clienu"
}

@app.route('/heartbeat', methods=['POST'])
def heartbeat():
    data = request.json
    clone_id = data.get("clone_id")
    if clone_id:
        clients_last_seen[clone_id] = time.time()
        clients_retry_count[clone_id] = 0 
        print(f"[{clone_id}] Online ({time.strftime('%H:%M:%S')})", flush=True)
    return "OK", 200

def auto_rejoin_checker():
    while True:
        current_time = time.time()
        for clone_id, last_seen in list(clients_last_seen.items()):
            if current_time - last_seen > 30:
                retry_count = clients_retry_count.get(clone_id, 0)
                if retry_count < MAX_RETRIES:
                    print(f"[{clone_id}] Disconnected. Retry: {retry_count + 1}/{MAX_RETRIES}", flush=True)
                    package_name = APPS_PACKAGE_NAMES.get(clone_id)
                    if package_name:
                        os.system(f"su -c 'am force-stop {package_name}'")
                        time.sleep(2)
                        os.system(f"su -c 'monkey -p {package_name} -c android.intent.category.LAUNCHER 1'")
                    clients_last_seen[clone_id] = current_time + 60 
                    clients_retry_count[clone_id] = retry_count + 1
                else:
                    print(f"[{clone_id}] Suspended for 5 mins.", flush=True)
                    clients_last_seen[clone_id] = current_time + 300 
        time.sleep(5)

if __name__ == '__main__':
    threading.Thread(target=auto_rejoin_checker, daemon=True).start()
    app.run(host='0.0.0.0', port=5000)
EOF

echo "Creating start.sh..."
cat << 'EOF' > start.sh
#!/bin/bash
echo "Clearing old processes..."
# ท่าไม้ตาย: เล็งเป้าเตะเฉพาะคนที่ถือพอร์ต 5000 (ทั้งแบบปกติและแบบ Root)
kill -9 $(lsof -t -i:5000) 2>/dev/null
su -c 'kill -9 $(lsof -t -i:5000)' 2>/dev/null

fuser -k -9 5000/tcp 2>/dev/null
killall -9 python 2>/dev/null
pkill -9 -f python
killall -9 ssh 2>/dev/null
killall -9 node 2>/dev/null
sleep 2

echo "Starting server..."
python -u server.py &
sleep 3

echo "Opening tunnel..."
ssh -o StrictHostKeyChecking=no -R 80:localhost:5000 serveo.net 2>&1 | grep -Eo 'https://[^ ]+\.serveousercontent\.com' | while read -r url; do
    echo "URL: $url"
    su -c "echo '$url' > /storage/emulated/0/Delta/Workspace/server_url.txt"
    echo "URL saved to workspace."
    break
done &
wait
EOF

chmod +x start.sh

echo "Setup complete. Run 'bash start.sh' to start."
