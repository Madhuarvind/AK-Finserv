import mysql.connector

def fix_mysql_schema():
    try:
        conn = mysql.connector.connect(
            host='localhost',
            user='root',
            password='MYSQL',
            database='vasool_drive'
        )
        cursor = conn.cursor()
        
        # Check for legacy 'amount' column
        cursor.execute("DESCRIBE loans")
        columns = [col[0] for col in cursor.fetchall()]
        
        if 'amount' in columns:
            print("Dropping legacy column 'amount' from 'loans' table...")
            cursor.execute("ALTER TABLE loans DROP COLUMN amount")
            conn.commit()
            print("Successfully dropped 'amount'.")
        else:
            print("'amount' column not found (correct).")
            
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    fix_mysql_schema()
