from extensions import db
from datetime import datetime
import enum

class UserRole(enum.Enum):
    ADMIN = 'admin'
    FIELD_AGENT = 'field_agent'

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
    customer_id = db.Column(db.String(20), unique=True, nullable=True) # CUST-YYYY-XXXXXX
    name = db.Column(db.String(100), nullable=False)
    mobile_number = db.Column(db.String(15), unique=True, nullable=False)
    address = db.Column(db.Text, nullable=True)
    area = db.Column(db.String(100), nullable=True)
    assigned_worker_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    
    # Lifecycle & Status
    status = db.Column(db.String(20), default='active') # 'created', 'verified', 'active', 'inactive', 'closed'
    
    # Extended Profile
    profile_image = db.Column(db.String(255), nullable=True)
    id_proof_type = db.Column(db.String(50), nullable=True) # 'aadhaar', 'pan', 'voter_id'
    id_proof_number = db.Column(db.String(50), nullable=True)
    alternate_contact = db.Column(db.String(15), nullable=True)
    family_head_name = db.Column(db.String(100), nullable=True)
    occupation = db.Column(db.String(100), nullable=True)
    
    # Location
    latitude = db.Column(db.Float, nullable=True)
    longitude = db.Column(db.Float, nullable=True)
    
    # Locking & Version Control
    is_locked = db.Column(db.Boolean, default=False)
    locked_by = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    locked_at = db.Column(db.DateTime, nullable=True)
    version = db.Column(db.Integer, default=1)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    worker = db.relationship('User', foreign_keys=[assigned_worker_id], backref='assigned_customers')
    locker = db.relationship('User', foreign_keys=[locked_by])

class Loan(db.Model):
    __tablename__ = 'loans'
    id = db.Column(db.Integer, primary_key=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('customers.id'), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    interest_rate = db.Column(db.Float, default=10.0)
    total_installments = db.Column(db.Integer, default=100)
    pending_amount = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(20), default='active')
    
    # Guarantor Details
    guarantor_name = db.Column(db.String(100), nullable=True)
    guarantor_mobile = db.Column(db.String(15), nullable=True)
    guarantor_relation = db.Column(db.String(50), nullable=True)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Collection(db.Model):
    __tablename__ = 'collections'
    id = db.Column(db.Integer, primary_key=True)
    loan_id = db.Column(db.Integer, db.ForeignKey('loans.id'), nullable=False)
    agent_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    line_id = db.Column(db.Integer, db.ForeignKey('lines.id'), nullable=True) # Linked to a specific route
    amount = db.Column(db.Float, nullable=False)
    payment_mode = db.Column(db.String(20), default='cash')
    status = db.Column(db.String(20), default='pending')
    latitude = db.Column(db.Float, nullable=True)
    longitude = db.Column(db.Float, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Line(db.Model):
    __tablename__ = 'lines'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False)
    area = db.Column(db.String(100), nullable=False)
    agent_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    is_locked = db.Column(db.Boolean, default=False)
    working_days = db.Column(db.String(50), default='Mon-Sat')
    start_time = db.Column(db.String(10), nullable=True)
    end_time = db.Column(db.String(10), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    customers = db.relationship('LineCustomer', backref='line', cascade="all, delete-orphan")
    collections = db.relationship('Collection', backref='line')

class LineCustomer(db.Model):
    __tablename__ = 'line_customers'
    id = db.Column(db.Integer, primary_key=True)
    line_id = db.Column(db.Integer, db.ForeignKey('lines.id'), nullable=False)
    customer_id = db.Column(db.Integer, db.ForeignKey('customers.id'), nullable=False)
    sequence_order = db.Column(db.Integer, default=0)
    assigned_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationship to get customer info directly    
    customer = db.relationship('Customer', backref='loans')

# Phase 3A: Production-Grade Customer Management Models

class CustomerVersion(db.Model):
    __tablename__ = 'customer_versions'
    id = db.Column(db.Integer, primary_key=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('customers.id'), nullable=False)
    version_number = db.Column(db.Integer, nullable=False)
    changed_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    changed_at = db.Column(db.DateTime, default=datetime.utcnow)
    changes = db.Column(db.JSON)
    reason = db.Column(db.Text)
    
    customer = db.relationship('Customer', backref='versions')
    changer = db.relationship('User')

class CustomerNote(db.Model):
    __tablename__ = 'customer_notes'
    id = db.Column(db.Integer, primary_key=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('customers.id'), nullable=False)
    worker_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    note_text = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_important = db.Column(db.Boolean, default=False)
    
    customer = db.relationship('Customer', backref='notes')
    worker = db.relationship('User')

class CustomerDocument(db.Model):
    __tablename__ = 'customer_documents'
    id = db.Column(db.Integer, primary_key=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('customers.id'), nullable=False)
    document_type = db.Column(db.String(50), nullable=False)
    file_path = db.Column(db.String(255), nullable=False)
    uploaded_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    customer = db.relationship('Customer', backref='documents')
    uploader = db.relationship('User')

class CustomerSyncLog(db.Model):
    __tablename__ = 'customer_sync_logs'
    id = db.Column(db.Integer, primary_key=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('customers.id'), nullable=True)
    sync_action = db.Column(db.String(50), nullable=False)
    sync_status = db.Column(db.String(50), nullable=False)
    device_id = db.Column(db.String(100))
    synced_at = db.Column(db.DateTime, default=datetime.utcnow)
    conflict_data = db.Column(db.JSON)
    
    customer = db.relationship('Customer', backref='sync_logs')
