from flask import Flask
from flask_cors import CORS
import os
from extensions import db, jwt

def create_app():
    app = Flask(__name__)
    CORS(app, resources={r"/*": {
        "origins": "*", 
        "methods": ["GET", "POST", "OPTIONS", "PUT", "DELETE", "PATCH"],
        "allow_headers": ["Content-Type", "Authorization"]
    }})

    # Configuration - Using MySQL
    app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://root:MYSQL@localhost:3306/vasool_drive'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['JWT_SECRET_KEY'] = 'vasool-drive-secret-keys' # Change in production

    db.init_app(app)
    jwt.init_app(app)

    from routes.auth import auth_bp
    from routes.collection import collection_bp
    from routes.line import line_bp
    from routes.customer import customer_bp
    from routes.loan import loan_bp
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(collection_bp, url_prefix='/api/collection')
    app.register_blueprint(line_bp, url_prefix='/api/line')
    app.register_blueprint(customer_bp, url_prefix='/api/customer')
    app.register_blueprint(loan_bp, url_prefix='/api/loan')

    return app

if __name__ == '__main__':
    app = create_app()
    with app.app_context():
        db.create_all()
    app.run(debug=True, host='0.0.0.0', port=5000)
