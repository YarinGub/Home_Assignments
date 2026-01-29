# SQL Injection Simulation & Mitigation

This project demonstrates a SQL Injection attack on a simple Flask web application and provides a secure implementation using Parameterized Queries.

## Requirements
* Python 3.x
* Flask

## Setup
1. Install dependencies:
   `pip install -r requirements.txt`
2. Initialize the database:
   `python init_db.py`
3. Run the application:
   `python app.py`

## The Attack
To demonstrate the vulnerability, use the following payload in the "Vulnerable Login" username field:
`' OR 1=1 --`

## Mitigation
The secure login route uses **Parameterized Queries** to prevent SQL injection by separating the SQL command from the user data.