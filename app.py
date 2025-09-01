from flask import Flask, request, render_template, jsonify
from flask_cors import CORS
import requests
from bs4 import BeautifulSoup
import re

app = Flask(__name__, template_folder=".")
CORS(app)  # allow calls from Flutter

ERP_BASE = "http://sue.su.edu.bd:5081/sonargaon_erp"


# ------------------------
# Function: scrape profile
# ------------------------
def scrape_name_and_id(userid: str, password: str):
    """Logs in and scrapes name + ID. Returns (name, sid) or raises ValueError."""
    login_url = f"{ERP_BASE}/"
    profile_url = f"{ERP_BASE}/student/profile/profileList/{userid}"

    session = requests.Session()
    session.headers.update({
        "User-Agent": "Mozilla/5.0 (compatible; SU-Scraper/1.0)"
    })

    # Step 1: Login
    login_resp = session.post(login_url, data={"email": userid, "password": password}, timeout=15)
    if login_resp.status_code != 200:
        raise ValueError(f"Login failed (status {login_resp.status_code}).")

    # Step 2: Fetch profile
    profile_resp = session.get(profile_url, timeout=15)
    if profile_resp.status_code != 200:
        raise ValueError(f"Could not load profile page (status {profile_resp.status_code}).")

    # Step 3: Parse
    soup = BeautifulSoup(profile_resp.text, "html.parser")
    table = soup.find("table")
    if not table:
        raise ValueError("Could not find profile table. Maybe login failed.")

    # find first data row (not header)
    row = None
    for tr in table.find_all("tr"):
        if tr.find("td"):  # only pick rows with <td>
            row = tr
            break
    if not row:
        raise ValueError("Could not find data row in profile table.")

    cells = row.find_all("td")
    if not cells:
        raise ValueError("Profile row has no cells.")

    raw_name = cells[0].get_text(strip=True)
    m = re.search(r"\(([^)]+)\)", raw_name)
    name = m.group(1) if m else raw_name

    return name, userid


# ------------------------
# Route 1: HTML form (old)
# ------------------------
@app.route("/", methods=["GET", "POST"])
def index():
    name = sid = error = None
    if request.method == "POST":
        userid = request.form["userid"]
        password = request.form["password"]
        try:
            name, sid = scrape_name_and_id(userid, password)
        except ValueError as e:
            error = str(e)
    return render_template("index.html", name=name, sid=sid, error=error)


# ------------------------
# Route 2: JSON API (new)
# ------------------------
@app.route("/api/login", methods=["POST"])
def api_login():
    """
    JSON in: {"userid":"...", "password":"..."}
    JSON out:
      success -> {"ok": true, "name": "...", "sid": "..."}
      error   -> {"ok": false, "error": "..."}
    """
    data = request.get_json(silent=True) or {}
    userid = data.get("userid", "").strip()
    password = data.get("password", "")

    if not userid or not password:
        return jsonify({"ok": False, "error": "userid and password are required"}), 400

    try:
        name, sid = scrape_name_and_id(userid, password)
        return jsonify({"ok": True, "name": name, "sid": sid})
    except ValueError as e:
        return jsonify({"ok": False, "error": str(e)}), 400
    except Exception as e:
        return jsonify({"ok": False, "error": "Unexpected server error"}), 500


# ------------------------
# Run server
# ------------------------
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
