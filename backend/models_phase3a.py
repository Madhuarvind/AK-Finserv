# Add to models.py after Customer model

class CustomerVersion(db.Model):
    __tablename__ = 'customer_versions'
    id = db.Column(db.Integer, primary_key=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('customers.id'), nullable=False)
    version_number = db.Column(db.Integer, nullable=False)
    changed_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    changed_at = db.Column(db.DateTime, default=datetime.utcnow)
    changes = db.Column(db.JSON) # Stores what changed
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
    document_type = db.Column(db.String(50), nullable=False) # 'face_photo', 'house_photo', 'id_proof'
    file_path = db.Column(db.String(255), nullable=False)
    uploaded_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    customer = db.relationship('Customer', backref='documents')
    uploader = db.relationship('User')

class CustomerSyncLog(db.Model):
    __tablename__ = 'customer_sync_logs'
    id = db.Column(db.Integer, primary_key=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('customers.id'), nullable=True)
    sync_action = db.Column(db.String(50), nullable=False) # 'create', 'update', 'sync'
    sync_status = db.Column(db.String(50), nullable=False) # 'success', 'failed', 'conflict'
    device_id = db.Column(db.String(100))
    synced_at = db.Column(db.DateTime, default=datetime.utcnow)
    conflict_data = db.Column(db.JSON)
    
    customer = db.relationship('Customer', backref='sync_logs')
