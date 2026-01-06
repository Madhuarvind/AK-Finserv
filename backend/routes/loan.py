from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User, Customer, Loan
from datetime import datetime

loan_bp = Blueprint('loan', __name__)

@loan_bp.route('/create', methods=['POST'])
@jwt_required()
def create_loan():
    identity = get_jwt_identity()
    user = User.query.filter((User.mobile_number == identity) | (User.username == identity) | (User.id == identity)).first()
    
    if not user:
        # Only admin or manager usually creates loans, but for now allow logged in users if they have permission
        return jsonify({"msg": "User not found"}), 404

    data = request.get_json()
    customer_id = data.get('customer_id')
    amount = data.get('amount')
    interest_rate = data.get('interest_rate', 10.0) # Default 10%
    total_installments = data.get('total_installments', 100) # Default 100 days
    
    # Guarantor
    guarantor_name = data.get('guarantor_name')
    guarantor_mobile = data.get('guarantor_mobile')
    guarantor_relation = data.get('guarantor_relation')
    
    if not customer_id or not amount:
        return jsonify({"msg": "Customer ID and Amount are required"}), 400
        
    try:
        new_loan = Loan(
            customer_id=customer_id,
            amount=amount,
            interest_rate=interest_rate,
            total_installments=total_installments,
            pending_amount=amount + (amount * (interest_rate/100)),
            status='active',
            guarantor_name=guarantor_name,
            guarantor_mobile=guarantor_mobile,
            guarantor_relation=guarantor_relation,
            created_at=datetime.utcnow()
        )
        
        db.session.add(new_loan)
        db.session.commit()
        
        return jsonify({
            "msg": "Loan created successfully",
            "loan_id": new_loan.id
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({"msg": str(e)}), 500
