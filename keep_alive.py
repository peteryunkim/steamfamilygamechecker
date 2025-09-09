import os
import datetime
from flask import Flask
from threading import Thread

app = Flask('')

@app.route('/')
def home():
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Ping received from {request.remote_addr}")
    print(f"staying alive")
    return "I'm alive!"

def run():
    port = int(os.environ.get("PORT", 8080))  # Render assigns a dynamic port
    app.run(host='0.0.0.0', port=port)

def keep_alive():
    t = Thread(target=run)
    t.start()
