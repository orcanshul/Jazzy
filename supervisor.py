import os
import time
import requests

STATUS_URL = os.getenv("GATEWAY_STATUS_URL", "http://localhost:8080/status")
WAKEUP_URL = os.getenv("EMERGENCY_WAKEUP_URL")
AUTH_TOKEN = os.getenv("CLOUD_API_TOKEN")

def run_diagnostics():
    print("[SUPERVISOR] Dispatching health validation ping across network endpoints...")
    try:
        response = requests.get(STATUS_URL, timeout=10)
        if response.status_code == 200:
            metrics = response.json()
            if not metrics.get("worker_connected", False):
                print("[ALERT] Gateway infrastructure running empty! Triggering node recovery...")
                fire_emergency_override()
            else:
                print("[HEALTH] Cluster operations operating inside optimal normal parameters.")
        else:
            print(f"[WARN] Invalidation warning code returned: {response.status_code}")
            fire_emergency_override()
    except requests.RequestException as error:
        print(f"[CRITICAL] Main gateway endpoint unreachable: {error}")
        fire_emergency_override()

def fire_emergency_override():
    if not WAKEUP_URL:
        print("[ERROR] Recovery skipped: EMERGENCY_WAKEUP_URL target variables empty.")
        return
    try:
        headers = {"Authorization": f"Bearer {AUTH_TOKEN}"} if AUTH_TOKEN else {}
        res = requests.post(WAKEUP_URL, headers=headers, timeout=15)
        print(f"[RECOVERY] Override call finished with execution code: {res.status_code}")
    except Exception as failure:
        print(f"[CRITICAL] Network failed to execute fallback boot scripts: {failure}")

if __name__ == "__main__":
    # Ping every 4 minutes (240s) to comfortablybeat Render's 15-minute inactivity spin-down timer
    while True:
        run_diagnostics()
        time.sleep(240)