from extensions import db, bcrypt
from models import User
from app import create_app

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
