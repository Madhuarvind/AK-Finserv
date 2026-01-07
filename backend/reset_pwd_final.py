from extensions import db, bcrypt
from models import User
from app import create_app

app = create_app()

with app.app_context():
    # Find admin
    admin = User.query.filter((User.username == 'admin') | (User.role == 'admin')).first()
    if admin:
        password = 'admin'
        hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        admin.password_hash = hashed
        db.session.commit()
        print(f"SUCCESS: Admin (id={admin.id}) password reset to: {password}")
    else:
        print("ERROR: Admin user not found")
