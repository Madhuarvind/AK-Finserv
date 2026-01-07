import sys
import os

# Add backend to sys.path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from backend.extensions import db
from backend.models import User
from backend.app import create_app
import bcrypt

app = create_app()

with app.app_context():
    admin = User.query.filter_by(username='admin').first()
    if admin:
        password = 'admin'
        hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        admin.password_hash = hashed
        db.session.commit()
        print(f"Admin password reset to: {password}")
    else:
        print("Admin user not found")
