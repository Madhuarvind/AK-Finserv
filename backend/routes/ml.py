from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import User, UserRole
from ml_risk_predictor import train_risk_model, predict_risk, get_high_risk_customers

ml_bp = Blueprint('ml', __name__)

def get_admin_user():
    identity = get_jwt_identity()
    user = User.query.filter((User.username == identity) | (User.id == identity)).first()
    if user and user.role == UserRole.ADMIN:
        return user
    return None

@ml_bp.route('/train-risk-model', methods=['POST'])
@jwt_required()
def train_model():
    """Train the ML risk prediction model"""
    if not get_admin_user():
        return jsonify({"msg": "Admin access required"}), 403
    
    try:
        result = train_risk_model()
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"msg": str(e)}), 500

@ml_bp.route('/predict-risk/<int:customer_id>', methods=['GET'])
@jwt_required()
def get_risk_prediction(customer_id):
    """Get risk prediction for a specific customer"""
    try:
        prediction = predict_risk(customer_id)
        if prediction.get('error'):
            return jsonify(prediction), 404
        return jsonify(prediction), 200
    except Exception as e:
        return jsonify({"msg": str(e)}), 500

@ml_bp.route('/risk-dashboard', methods=['GET'])
@jwt_required()
def risk_dashboard():
    """Get dashboard of high-risk customers"""
    if not get_admin_user():
        return jsonify({"msg": "Admin access required"}), 403
    
    try:
        high_risk = get_high_risk_customers(limit=100)
        
        # Calculate summary stats
        total_high_risk = len([c for c in high_risk if c['risk_level'] == 'high'])
        total_medium_risk = len([c for c in high_risk if c['risk_level'] == 'medium'])
        
        return jsonify({
            "summary": {
                "total_at_risk": len(high_risk),
                "high_risk_count": total_high_risk,
                "medium_risk_count": total_medium_risk
            },
            "customers": high_risk
        }), 200
    except Exception as e:
        return jsonify({"msg": str(e)}), 500
