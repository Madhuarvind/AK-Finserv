from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User, Customer, Loan, Collection, UserRole
from datetime import datetime

collection_bp = Blueprint('collection', __name__)

@collection_bp.route('/submit', methods=['POST'])
@jwt_required()
def submit_collection():
    identity = get_jwt_identity()
    user = User.query.filter((User.mobile_number == identity) | (User.username == identity) | (User.id == identity)).first()
    
    if not user:
        return jsonify({"msg": "User not found"}), 404
        
    data = request.get_json()
    loan_id = data.get('loan_id')
    amount = data.get('amount')
    payment_mode = data.get('payment_mode', 'cash')
    latitude = data.get('latitude')
    longitude = data.get('longitude')
    
    if not loan_id or amount is None:
        return jsonify({"msg": "Missing required fields"}), 400
        
    loan = Loan.query.get(loan_id)
    if not loan:
        return jsonify({"msg": "Loan not found"}), 404
        
    new_collection = Collection(
        loan_id=loan_id,
        agent_id=user.id,
        amount=float(amount),
        payment_mode=payment_mode,
        latitude=latitude,
        longitude=longitude,
        status='pending'
    )
    
    db.session.add(new_collection)
    db.session.commit()
    
    return jsonify({
        "msg": "collection_submitted_successfully", 
        "id": new_collection.id,
        "status": new_collection.status
    }), 201

@collection_bp.route('/pending', methods=['GET'])
@jwt_required()
def get_pending_collections():
    identity = get_jwt_identity()
    user = User.query.filter((User.mobile_number == identity) | (User.username == identity) | (User.id == identity)).first()
    
    if not user or user.role == UserRole.FIELD_AGENT:
        return jsonify({"msg": "Access Denied"}), 403
        
    # Managers see collections from their team
    if user.role == UserRole.MANAGER:
        team_ids = [u.id for u in user.assigned_agents]
        pending = Collection.query.filter(Collection.agent_id.in_(team_ids), Collection.status == 'pending').all()
    else: # Admins see all
        pending = Collection.query.filter_by(status='pending').all()
        
    return jsonify([{
        "id": c.id,
        "loan_id": c.loan_id,
        "agent": c.agent_id,
        "amount": c.amount,
        "mode": c.payment_mode,
        "time": c.created_at.isoformat()
    } for c in pending]), 200

@collection_bp.route('/customers', methods=['GET'])
@jwt_required()
def get_customers():
    customers = Customer.query.all()
    return jsonify([{
        "id": c.id,
        "name": c.name,
        "mobile": c.mobile_number,
        "area": c.area
    } for c in customers]), 200

@collection_bp.route('/loans/<int:customer_id>', methods=['GET'])
@jwt_required()
def get_customer_loans(customer_id):
    loans = Loan.query.filter_by(customer_id=customer_id, status='active').all()
    return jsonify([{
        "id": l.id,
        "amount": l.amount,
        "pending": l.pending_amount,
        "installments": l.total_installments
    } for l in loans]), 200

@collection_bp.route('/<int:collection_id>/status', methods=['PATCH'])
@jwt_required()
def update_collection_status(collection_id):
    identity = get_jwt_identity()
    user = User.query.filter((User.mobile_number == identity) | (User.username == identity) | (User.id == identity)).first()
    
    if not user or user.role == UserRole.FIELD_AGENT:
        return jsonify({"msg": "Access Denied"}), 403
        
    data = request.get_json()
    status = data.get('status')
    
    if status not in ['approved', 'rejected']:
        return jsonify({"msg": "Invalid status"}), 400
        
    collection = Collection.query.get(collection_id)
    if not collection:
        return jsonify({"msg": "Collection not found"}), 404
        
    collection.status = status
    
    if status == 'approved':
        loan = Loan.query.get(collection.loan_id)
        if loan:
            loan.pending_amount -= collection.amount
            if loan.pending_amount <= 0:
                loan.pending_amount = 0
                loan.status = 'closed'
                
    db.session.commit()
    return jsonify({"msg": "collection_updated_successfully", "status": status}), 200
