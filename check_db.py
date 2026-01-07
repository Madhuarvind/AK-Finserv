import pymysql
import os

connection = pymysql.connect(
    host='localhost',
    user='root',
    password='MYSQL',
    database='vasool_drive',
    cursorclass=pymysql.cursors.DictCursor
)

try:
    with connection.cursor() as cursor:
        print("--- Customers ---")
        cursor.execute("SELECT id, name, mobile_number, status FROM customers WHERE id = 5")
        cust = cursor.fetchone()
        print(cust)
        
        print("\n--- Loans for Customer 5 ---")
        cursor.execute("SELECT id, loan_id, customer_id, principal_amount, status FROM loans WHERE customer_id = 5")
        loans = cursor.fetchall()
        for l in loans:
            print(l)
finally:
    connection.close()
