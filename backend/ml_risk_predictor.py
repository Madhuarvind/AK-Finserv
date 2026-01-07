"""
ML-based Risk Prediction Module
Predicts customer default risk using Random Forest Classifier
"""

import pickle
import os
import numpy as np
from datetime import datetime, timedelta
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
from models import db, Customer, Loan, Collection, EMISchedule

MODEL_PATH = 'ml_models/risk_model.pkl'
SCALER_PATH = 'ml_models/risk_scaler.pkl'

# Ensure model directory exists
os.makedirs('ml_models', exist_ok=True)

def extract_customer_features(customer_id):
    """
    Extract ML features for a customer
    Returns: feature vector as numpy array
    """
    customer = Customer.query.get(customer_id)
    if not customer:
        return None
    
    # Get active loan
    active_loan = Loan.query.filter_by(customer_id=customer_id, status='active').first()
    
    features = {}
    
    # Feature 1: Has active loan (binary)
    features['has_active_loan'] = 1 if active_loan else 0
    
    if active_loan:
        # Feature 2: Loan amount (normalized)
        features['loan_amount'] = active_loan.principal_amount
        
        # Feature 3: Overdue EMI count
        today = datetime.utcnow()
        overdue_emis = EMISchedule.query.filter(
            EMISchedule.loan_id == active_loan.id,
            EMISchedule.status != 'paid',
            EMISchedule.due_date < today
        ).count()
        features['overdue_count'] = overdue_emis
        
        # Feature 4: Payment consistency (percentage of on-time payments)
        total_emis = EMISchedule.query.filter_by(loan_id=active_loan.id).count()
        paid_emis = EMISchedule.query.filter_by(loan_id=active_loan.id, status='paid').count()
        features['payment_rate'] = (paid_emis / total_emis * 100) if total_emis > 0 else 0
        
        # Feature 5: Days since loan start
        if active_loan.start_date:
            features['loan_age_days'] = (today - active_loan.start_date).days
        else:
            features['loan_age_days'] = 0
        
        # Feature 6: Pending amount ratio
        features['pending_ratio'] = (active_loan.pending_amount / active_loan.principal_amount * 100) if active_loan.principal_amount > 0 else 0
        
        # Feature 7: Collection frequency (collections in last 30 days)
        last_month = today - timedelta(days=30)
        recent_collections = Collection.query.filter(
            Collection.loan_id == active_loan.id,
            Collection.created_at >= last_month
        ).count()
        features['recent_collection_count'] = recent_collections
        
        # Feature 8: Average collection amount vs EMI
        collections = Collection.query.filter_by(loan_id=active_loan.id, status='approved').all()
        if collections and total_emis > 0:
            avg_collection = sum(c.amount for c in collections) / len(collections)
            expected_emi = active_loan.principal_amount / total_emis if total_emis > 0 else 1
            features['avg_collection_ratio'] = (avg_collection / expected_emi * 100) if expected_emi > 0 else 0
        else:
            features['avg_collection_ratio'] = 0
    else:
        # No active loan - set defaults
        features['loan_amount'] = 0
        features['overdue_count'] = 0
        features['payment_rate'] = 100  # Assume good if no active loan
        features['loan_age_days'] = 0
        features['pending_ratio'] = 0
        features['recent_collection_count'] = 0
        features['avg_collection_ratio'] = 100
    
    # Feature 9: Customer age (days since creation)
    features['customer_age_days'] = (datetime.utcnow() - customer.created_at).days if customer.created_at else 0
    
    # Feature 10: Status indicator (active=1, others=0)
    features['is_active'] = 1 if customer.status == 'active' else 0
    
    # Convert to ordered array
    feature_vector = np.array([
        features['has_active_loan'],
        features['loan_amount'],
        features['overdue_count'],
        features['payment_rate'],
        features['loan_age_days'],
        features['pending_ratio'],
        features['recent_collection_count'],
        features['avg_collection_ratio'],
        features['customer_age_days'],
        features['is_active']
    ]).reshape(1, -1)
    
    return feature_vector

def train_risk_model():
    """
    Train the risk prediction model on historical data
    This is a simplified version - in production, you'd use labeled historical data
    """
    all_customers = Customer.query.all()
    
    X_train = []
    y_train = []
    
    for customer in all_customers:
        features = extract_customer_features(customer.id)
        if features is not None:
            X_train.append(features[0])
            
            # Simple labeling logic (in production, use actual default history)
            # High risk if: overdue > 2 OR payment_rate < 50
            overdue = features[0][2]
            payment_rate = features[0][3]
            
            if overdue > 2 or payment_rate < 50:
                label = 2  # High risk
            elif overdue > 0 or payment_rate < 80:
                label = 1  # Medium risk
            else:
                label = 0  # Low risk
            
            y_train.append(label)
    
    if len(X_train) < 5:
        # Not enough data to train
        return {"msg": "Insufficient data for training. Need at least 5 customers with loans."}
    
    X_train = np.array(X_train)
    y_train = np.array(y_train)
    
    # Scale features
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    
    # Train Random Forest
    model = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42)
    model.fit(X_train_scaled, y_train)
    
    # Save model and scaler
    with open(MODEL_PATH, 'wb') as f:
        pickle.dump(model, f)
    
    with open(SCALER_PATH, 'wb') as f:
        pickle.dump(scaler, f)
    
    return {
        "msg": "Model trained successfully",
        "samples": len(X_train),
        "accuracy": model.score(X_train_scaled, y_train)
    }

def predict_risk(customer_id):
    """
    Predict risk for a specific customer
    Returns: dict with risk_score, risk_level, confidence
    """
    # Check if model exists
    if not os.path.exists(MODEL_PATH) or not os.path.exists(SCALER_PATH):
        return {"error": "Model not trained yet. Please train the model first."}
    
    # Load model and scaler
    with open(MODEL_PATH, 'rb') as f:
        model = pickle.load(f)
    
    with open(SCALER_PATH, 'rb') as f:
        scaler = pickle.load(f)
    
    # Extract features
    features = extract_customer_features(customer_id)
    if features is None:
        return {"error": "Customer not found"}
    
    # Scale and predict
    features_scaled = scaler.transform(features)
    prediction = model.predict(features_scaled)[0]
    probabilities = model.predict_proba(features_scaled)[0]
    
    # Map to risk levels
    risk_levels = ['low', 'medium', 'high']
    risk_level = risk_levels[prediction]
    confidence = float(max(probabilities) * 100)
    
    return {
        "customer_id": customer_id,
        "risk_score": int(prediction),
        "risk_level": risk_level,
        "confidence": round(confidence, 2),
        "probabilities": {
            "low": round(float(probabilities[0] * 100), 2),
            "medium": round(float(probabilities[1] * 100), 2),
            "high": round(float(probabilities[2] * 100), 2)
        }
    }

def get_high_risk_customers(limit=50):
    """
    Get list of high-risk customers
    """
    if not os.path.exists(MODEL_PATH):
        return []
    
    all_customers = Customer.query.filter_by(status='active').limit(limit).all()
    high_risk = []
    
    for customer in all_customers:
        prediction = predict_risk(customer.id)
        if not prediction.get('error') and prediction.get('risk_level') in ['medium', 'high']:
            high_risk.append({
                "customer_id": customer.id,
                "customer_name": customer.name,
                "customer_number": customer.customer_id,
                "mobile": customer.mobile_number,
                "risk_score": prediction['risk_score'],
                "risk_level": prediction['risk_level'],
                "confidence": prediction['confidence']
            })
    
    # Sort by risk score descending
    high_risk.sort(key=lambda x: x['risk_score'], reverse=True)
    
    return high_risk
