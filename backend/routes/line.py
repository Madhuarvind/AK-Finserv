from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User, Customer, Line, LineCustomer, UserRole
from datetime import datetime

line_bp = Blueprint('line', __name__)

@line_bp.route('/create', methods=['POST'])
@jwt_required()
def create_line():
    identity = get_jwt_identity()
    admin = User.query.filter((User.username == identity) | (User.id == identity) | (User.mobile_number == identity)).first()
    
    if not admin or admin.role != UserRole.ADMIN:
        return jsonify({"msg": "Access Denied"}), 403
        
    data = request.get_json()
    name = data.get('name')
    area = data.get('area')
    agent_id = data.get('agent_id')
    
    if not name or not area:
        return jsonify({"msg": "Line Name and Area are required"}), 400
        
    if Line.query.filter_by(name=name).first():
        return jsonify({"msg": "Line name already exists"}), 400
        
    new_line = Line(
        name=name,
        area=area,
        agent_id=agent_id,
        working_days=data.get('working_days', 'Mon-Sat'),
        start_time=data.get('start_time'),
        end_time=data.get('end_time')
    )
    
    db.session.add(new_line)
    db.session.commit()
    
    return jsonify({"msg": "line_created_successfully", "id": new_line.id}), 201

@line_bp.route('/all', methods=['GET'])
@jwt_required()
def get_all_lines():
    identity = get_jwt_identity()
    user = User.query.filter((User.username == identity) | (User.id == identity) | (User.mobile_number == identity)).first()
    
    if not user:
        return jsonify({"msg": "User not found"}), 404
        
    # Admins see all lines, Agents see only their assigned lines
    if user.role == UserRole.ADMIN:
        lines = Line.query.all()
    else:
        lines = Line.query.filter_by(agent_id=user.id).all()
        
    return jsonify([{
        "id": l.id,
        "name": l.name,
        "area": l.area,
        "agent_id": l.agent_id,
        "is_locked": l.is_locked,
        "customer_count": len(l.customers)
    } for l in lines]), 200

@line_bp.route('/<int:line_id>/assign-agent', methods=['POST'])
@jwt_required()
def assign_agent(line_id):
    identity = get_jwt_identity()
    admin = User.query.filter((User.username == identity) | (User.id == identity) | (User.mobile_number == identity)).first()
    
    if not admin or admin.role != UserRole.ADMIN:
        return jsonify({"msg": "Access Denied"}), 403
        
    data = request.get_json()
    agent_id = data.get('agent_id')
    
    line = Line.query.get(line_id)
    if not line:
        return jsonify({"msg": "Line not found"}), 404
        
    line.agent_id = agent_id
    db.session.commit()
    
    return jsonify({"msg": "agent_assigned_successfully"}), 200

@line_bp.route('/<int:line_id>/add-customer', methods=['POST'])
@jwt_required()
def add_customer_to_line(line_id):
    identity = get_jwt_identity()
    admin = User.query.filter((User.username == identity) | (User.id == identity) | (User.mobile_number == identity)).first()
    
    if not admin or admin.role != UserRole.ADMIN:
        return jsonify({"msg": "Access Denied"}), 403
        
    data = request.get_json()
    customer_id = data.get('customer_id')
    
    line = Line.query.get(line_id)
    if not line:
        return jsonify({"msg": "Line not found"}), 404
        
    # Check if customer already in another active line? (User rule 3.3)
    # For now, just allow mapping
    
    # Calculate next sequence order
    max_seq = db.session.query(db.func.max(LineCustomer.sequence_order)).filter_by(line_id=line_id).scalar() or 0
    
    new_mapping = LineCustomer(
        line_id=line_id,
        customer_id=customer_id,
        sequence_order=max_seq + 1
    )
    
    db.session.add(new_mapping)
    db.session.commit()
    
    return jsonify({"msg": "customer_added_to_line"}), 201

@line_bp.route('/<int:line_id>/customers', methods=['GET'])
@jwt_required()
def get_line_customers(line_id):
    line = Line.query.get(line_id)
    if not line:
        return jsonify({"msg": "Line not found"}), 404
        
    customers_mapping = LineCustomer.query.filter_by(line_id=line_id).order_by(LineCustomer.sequence_order).all()
    
    return jsonify([{
        "id": m.customer.id,
        "name": m.customer.name,
        "mobile": m.customer.mobile_number,
        "area": m.customer.area,
        "sequence": m.sequence_order
    } for m in customers_mapping]), 200

@line_bp.route('/<int:line_id>/reorder', methods=['POST'])
@jwt_required()
def reorder_line_customers(line_id):
    identity = get_jwt_identity()
    admin = User.query.filter((User.username == identity) | (User.id == identity) | (User.mobile_number == identity)).first()
    
    if not admin or admin.role != UserRole.ADMIN:
        return jsonify({"msg": "Access Denied"}), 403
        
    data = request.get_json()
    customer_order = data.get('order') # List of customer IDs in new order
    
    if not customer_order:
        return jsonify({"msg": "Order required"}), 400
        
    for index, customer_id in enumerate(customer_order):
        mapping = LineCustomer.query.filter_by(line_id=line_id, customer_id=customer_id).first()
        if mapping:
            mapping.sequence_order = index + 1
            
    db.session.commit()
    return jsonify({"msg": "Order updated successfully"}), 200

@line_bp.route('/<int:line_id>/lock', methods=['PATCH'])
@jwt_required()
def toggle_line_lock(line_id):
    identity = get_jwt_identity()
    admin = User.query.filter((User.username == identity) | (User.id == identity) | (User.mobile_number == identity)).first()
    
    if not admin or admin.role != UserRole.ADMIN:
        return jsonify({"msg": "Access Denied"}), 403
        
    line = Line.query.get(line_id)
    if not line:
        return jsonify({"msg": "Line not found"}), 404
        
    line.is_locked = not line.is_locked
    db.session.commit()
    
    return jsonify({"msg": "line_status_updated", "is_locked": line.is_locked}), 200
