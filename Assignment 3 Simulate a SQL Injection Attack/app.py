from flask import Flask, request, render_template_string
import sqlite3

app = Flask(__name__)

# פונקציית עזר להתחברות למסד הנתונים
def get_db_connection():
    conn = sqlite3.connect('users.db')
    conn.row_factory = sqlite3.Row
    return conn

# דף הבית עם הטופס (UI פשוט)
@app.route('/')
def index():
    return render_template_string('''
        <h2>SQL Injection Demo</h2>
        <form action="/login_vulnerable" method="POST">
            <h3>Vulnerable Login</h3>
            Username: <input type="text" name="username"><br>
            Password: <input type="password" name="password"><br>
            <input type="submit" value="Login (Vulnerable)">
        </form>
        <hr>
        <form action="/login_secure" method="POST">
            <h3>Secure Login</h3>
            Username: <input type="text" name="username"><br>
            Password: <input type="password" name="password"><br>
            <input type="submit" value="Login (Secure)">
        </form>
    ''')

# --- החלק הפגיע ---
@app.route('/login_vulnerable', methods=['POST'])
def login_vulnerable():
    username = request.form['username']
    password = request.form['password']
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # טעות קריטית: חיבור מחרוזות ישיר!
    query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
    print(f"Executing Query: {query}") # נדפיס לטרמינל כדי לראות את הזרקת הקוד
    
    user = cursor.execute(query).fetchone()
    conn.close()
    
    if user:
        return f"<h1>Success! Logged in as: {user['username']}</h1>"
    else:
        return "<h1>Login Failed!</h1>"

# --- החלק המאובטח ---
@app.route('/login_secure', methods=['POST'])
def login_secure():
    username = request.form['username']
    password = request.form['password']
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # התיקון: שימוש בסימני שאלה (Parameterized Query)
    query = "SELECT * FROM users WHERE username = ? AND password = ?"
    print(f"Executing Secure Query: {query} with parameters: ({username}, {password})")
    
    user = cursor.execute(query, (username, password)).fetchone()
    conn.close()
    
    if user:
        return f"<h1>Success! Logged in as: {user['username']}</h1>"
    else:
        return "<h1>Login Failed! (The injection didn't work)</h1>"

if __name__ == '__main__':
    app.run(debug=True)