import sqlite3

# התחברות למסד הנתונים (ייווצר קובץ חדש)
conn = sqlite3.connect('users.db')
cursor = conn.cursor()

# יצירת טבלת משתמשים
cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        password TEXT NOT NULL
    )
''')

# הכנסת משתמש לדוגמה (במציאות סיסמאות נשמרות מוצפנות, אבל לצורך המטלה נשמור טקסט רגיל)
cursor.execute("INSERT INTO users (username, password) VALUES ('admin', '12345')")

conn.commit()
conn.close()
print("מסד הנתונים נוצר בהצלחה!")