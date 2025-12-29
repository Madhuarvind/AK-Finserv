from extensions import db
from datetime import datetime
import enum

class UserRole(enum.Enum):
    ADMIN = 'admin'
    FIELD_AGENT = 'field_agent'
    MANAGER = 'manager'

class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False) # Full Name
    mobile_number = db.Column(db.String(15), unique=True, nullable=False)
    pin_hash = db.Column(db.String(255), nullable=True) # For Field Agents
    password_hash = db.Column(db.String(255), nullable=True) # For Admin
    role = db.Column(db.Enum(UserRole), default=UserRole.FIELD_AGENT)
    
    # Username Auth for Admin
    username = db.Column(db.String(50), unique=True, nullable=True)
    business_name = db.Column(db.String(100), nullable=True)
    
    # Professional Business Fields
    area = db.Column(db.String(100), nullable=True)
    address = db.Column(db.Text, nullable=True)
    id_proof = db.Column(db.String(50), nullable=True)
    
    is_active = db.Column(db.Boolean, default=True)
    is_locked = db.Column(db.Boolean, default=False)
    device_binding_enabled = db.Column(db.Boolean, default=True)
    is_first_login = db.Column(db.Boolean, default=True)
    last_login = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Manager Hierarchy
    manager_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    assigned_agents = db.relationship('User', backref=db.backref('manager', remote_side=[id]))

    # Relationships for automated cleanup
    face_embeddings = db.relationship('FaceEmbedding', backref='user', cascade="all, delete-orphan")
    qr_codes = db.relationship('QRCode', backref='user', cascade="all, delete-orphan")
    login_logs = db.relationship('LoginLog', backref='user', cascade="all, delete-orphan")
    devices = db.relationship('Device', backref='user', cascade="all, delete-orphan")

class FaceEmbedding(db.Model):
    __tablename__ = 'face_embeddings'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    embedding_data = db.Column(db.JSON, nullable=False) # Stores face features
    device_id = db.Column(db.String(100), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class QRCode(db.Model):
    __tablename__ = 'qr_codes'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    qr_token = db.Column(db.String(255), unique=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class LoginLog(db.Model):
    __tablename__ = 'login_logs'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    login_time = db.Column(db.DateTime, default=datetime.utcnow)
    ip_address = db.Column(db.String(45))
    device_info = db.Column(db.String(255))
    status = db.Column(db.String(20)) # 'success', 'failed'

class Device(db.Model):
    __tablename__ = 'devices'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    device_id = db.Column(db.String(100), unique=True)
    device_name = db.Column(db.String(100))
    is_trusted = db.Column(db.Boolean, default=True)
    last_active = db.Column(db.DateTime, default=datetime.utcnow)

class OTPLog(db.Model):
    __tablename__ = 'otp_logs'
    id = db.Column(db.Integer, primary_key=True)
    mobile_number = db.Column(db.String(15), nullable=False)
    otp_code = db.Column(db.String(6), nullable=False)
    expires_at = db.Column(db.DateTime, nullable=False)
    is_used = db.Column(db.Boolean, default=False)

class Customer(db.Model):
    __tablename__ = 'customers'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    mobile_number = db.Column(db.String(15), unique=True, nullable=False)
    address = db.Column(db.Text, nullable=True)
    area = db.Column(db.String(100), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Loan(db.Model):
    __tablename__ = 'loans'
    id = db.Column(db.Integer, primary_key=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('customers.id'), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    interest_rate = db.Column(db.Float, default=10.0)
    total_installments = db.Column(db.Integer, default=100)
    pending_amount = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(20), default='active')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Collection(db.Model):
    __tablename__ = 'collections'
    id = db.Column(db.Integer, primary_key=True)
    loan_id = db.Column(db.Integer, db.ForeignKey('loans.id'), nullable=False)
    agent_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    payment_mode = db.Column(db.String(20), default='cash')
    status = db.Column(db.String(20), default='pending')
    latitude = db.Column(db.Float, nullable=True)
    longitude = db.Column(db.Float, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
