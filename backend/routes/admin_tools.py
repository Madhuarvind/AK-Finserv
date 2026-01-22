from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import (
    db,
    User,
    UserRole,
    Customer,
    Loan,
    Line,
    Collection,
    DailySettlement,
    CustomerVersion,
    CustomerNote,
    CustomerDocument,
    SystemSetting,
    EMISchedule,
    DailyAccountingReport,
    LoginLog,
)
from utils.auth_helpers import get_user_by_identity
from datetime import datetime, timedelta

admin_tools_bp = Blueprint("admin_tools", __name__)

MODEL_MAP = {
    "Users": User,
    "Customers": Customer,
    "Loans": Loan,
    "Lines": Line,
    "Collections": Collection,
    "DailySettlement": DailySettlement,
    "CustomerVersion": CustomerVersion,
    "CustomerNote": CustomerNote,
    "CustomerDocument": CustomerDocument,
    "SystemSetting": SystemSetting,
}


@admin_tools_bp.route("/raw-table/<table_name>", methods=["GET"])
@jwt_required()
def get_raw_table_data(table_name):
    identity = get_jwt_identity()
    user = get_user_by_identity(identity)

    if not user or user.role != UserRole.ADMIN:
        return jsonify({"msg": "Access Denied"}), 403

    model = MODEL_MAP.get(table_name)
    if not model:
        return jsonify({"msg": "Table not found"}), 404

    try:
        data = model.query.all()
        # Convert all model instances to dictionaries
        # We assume each model has a to_dict() method or we use a generic approach
        result = []
        for item in data:
            item_dict = {}
            for column in item.__table__.columns:
                val = getattr(item, column.name)
                # Handle datetime serialization
                if hasattr(val, "isoformat"):
                    val = val.isoformat()
                item_dict[column.name] = val
            result.append(item_dict)

        return jsonify(result), 200
    except Exception as e:
        return jsonify({"msg": "Error fetching data", "error": str(e)}), 500


@admin_tools_bp.route("/ai-analyst", methods=["POST"])
@jwt_required()
def ai_analyst():
    """
    Simulated AI Financial Analyst
    Translates natural language queries into financial insights
    """
    identity = get_jwt_identity()
    user = get_user_by_identity(identity)
    if not user or user.role != UserRole.ADMIN:
        return jsonify({"msg": "Access Denied"}), 403

    data = request.get_json()
    query = data.get("query", "").lower()

    response = {
        "text": "I'm sorry, I couldn't find specific data for that request. Try asking about 'total collections', 'today's cash', or 'top agents'.",
        "data": None,
        "type": "text",
    }

    # 0. Greetings
    if any(greet in query for greet in ["hi", "hello", "hey", "vanakkam"]):
        response["text"] = (
            "Hello! I am your AI Financial Analyst. You can ask me about collections, agent performance, or risk. For example: 'What is today's total cash?'"
        )
        return jsonify(response), 200

    # 1. Total Collections Query (All time or general)
    if "total" in query and (
        "collection" in query or "collect" in query or "all" in query
    ):
        total_sum = (
            db.session.query(db.func.sum(Collection.amount))
            .filter_by(status="approved")
            .scalar()
            or 0
        )
        total_count = Collection.query.filter_by(status="approved").count()
        response["text"] = (
            f"Our lifetime approved collections reached ₹{total_sum:,.2f} across {total_count} entries. This reflects a healthy recovery rate across all lines."
        )
        response["data"] = {
            "value": total_sum,
            "metric": "LifeTime Collections",
            "count": total_count,
        }
        response["type"] = "metric"

    # 2. Today's Cash or just "Total cash"
    elif "today" in query or "day" in query or "cash" in query:
        from datetime import datetime

        today = datetime.utcnow().date()

        today_cash = (
            db.session.query(db.func.sum(Collection.amount))
            .filter(
                db.func.date(Collection.created_at) == today,
                Collection.status == "approved",
                Collection.payment_mode == "cash",
            )
            .scalar()
            or 0
        )

        today_upi = (
            db.session.query(db.func.sum(Collection.amount))
            .filter(
                db.func.date(Collection.created_at) == today,
                Collection.status == "approved",
                Collection.payment_mode == "upi",
            )
            .scalar()
            or 0
        )

        today_count = Collection.query.filter(
            db.func.date(Collection.created_at) == today,
            Collection.status == "approved",
        ).count()

        top_agent_today = (
            db.session.query(User.name, db.func.sum(Collection.amount))
            .join(Collection, User.id == Collection.agent_id)
            .filter(
                db.func.date(Collection.created_at) == today,
                Collection.status == "approved",
            )
            .group_by(User.id)
            .order_by(db.func.sum(Collection.amount).desc())
            .first()
        )

        if "upi" in query:
            response["text"] = (
                f"Today's total approved UPI collection is ₹{today_upi:,.2f}."
            )
            response["data"] = {"value": today_upi, "metric": "Today's UPI"}
        else:
            summary_text = f"Today's Tally: Total ₹{today_cash + today_upi:,.2f} recovered across {today_count} collections.\n\n"
            summary_text += f"• Cash: ₹{today_cash:,.2f}\n"
            summary_text += f"• UPI: ₹{today_upi:,.2f}\n"
            if top_agent_today:
                summary_text += f"\nLeaderboard: {top_agent_today[0]} is leading today with ₹{top_agent_today[1]:,.2f} collected."

            response["text"] = summary_text
            response["data"] = {
                "cash": today_cash,
                "upi": today_upi,
                "total": today_cash + today_upi,
            }

        response["type"] = "metric"

    # 3. P&L / Business Health
    elif "profit" in query or "pnl" in query or "health" in query or "performance" in query:
        # Heuristic: Interest earned (from EMISchedules marked paid) - estimated operating costs
        # In this simplistic model, let's look at total interest collected
        from models import EMISchedule
        total_interest_earned = (
            db.session.query(db.func.sum(EMISchedule.interest_part))
            .filter_by(status="paid")
            .scalar()
            or 0
        )
        
        # Heuristic expenses from DailySettlement
        total_expenses = (
            db.session.query(db.func.sum(DailySettlement.expenses))
            .filter_by(status="verified")
            .scalar()
            or 0
        )
        
        net_profit = total_interest_earned - total_expenses
        
        response["text"] = (
            f"Financial Health: Our estimated Net Profit (Interest Earned - Operating Expenses) is ₹{net_profit:,.2f}.\n\n"
            f"• Gross Interest: ₹{total_interest_earned:,.2f}\n"
            f"• Verified Expenses: ₹{total_expenses:,.2f}"
        )
        response["data"] = {
            "interest": total_interest_earned,
            "expenses": total_expenses,
            "net": net_profit
        }
        response["type"] = "financial_summary"

    # 4. Forecasting (Next 7 days)
    elif "forecast" in query or "expected" in query or "future" in query:
        from datetime import datetime, timedelta
        from models import EMISchedule
        
        today = datetime.utcnow().date()
        next_week = today + timedelta(days=7)
        
        expected_7d = (
            db.session.query(db.func.sum(EMISchedule.amount))
            .filter(
                db.func.date(EMISchedule.due_date) > today,
                db.func.date(EMISchedule.due_date) <= next_week,
                EMISchedule.status == "pending"
            )
            .scalar()
            or 0
        )
        
        response["text"] = (
            f"Cashflow Forecast: We expect to recover approximately ₹{expected_7d:,.2f} over the next 7 days based on the current EMI schedule."
        )
        response["data"] = {"value": expected_7d, "period": "7 days"}
        response["type"] = "forecast"

    # 5. Agent Efficiency
    elif "efficiency" in query or "top" in query or "best" in query or "ranking" in query:
        from models import EMISchedule, Collection, User
        
        # Rank agents by (Collected Today / Assigned Today) if possible, 
        # but the schema doesn't strictly have 'assigned' per day.
        # Fallback to total collection ranking as currently implemented, 
        # or list active agents by volume.
        
        top_performers = (
            db.session.query(User.name, db.func.sum(Collection.amount))
            .join(Collection, User.id == Collection.agent_id)
            .filter(Collection.status == "approved")
            .group_by(User.id)
            .order_by(db.func.sum(Collection.amount).desc())
            .limit(3)
            .all()
        )
        
        summary = "Operational Efficiency (Top 3 Agents):\n"
        for i, (name, total) in enumerate(top_performers):
            summary += f"{i+1}. {name}: ₹{total:,.2f}\n"
            
        response["text"] = summary
        response["data"] = [{"name": n, "value": v} for n, v in top_performers]
        response["type"] = "ranking"

    # 6. Defaults / High Risk
    elif "risk" in query or "default" in query:
        high_risk_count = Loan.query.filter(
            Loan.pending_amount > (Loan.principal_amount * 0.8)
        ).count()
        response["text"] = (
            f"I've identified {high_risk_count} loans with a potential high risk of default (over 80% balance remaining)."
        )
        response["data"] = {"count": high_risk_count}
        response["type"] = "risk_summary"

    return jsonify(response), 200


@admin_tools_bp.route("/seed-users", methods=["POST"])
def seed_users():
    """
    seeds the database with default users if they don't exist.
    """
    import bcrypt
    from models import User, UserRole
    
    def hash_pass(password):
        return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

    try:
        # Check if users already exist
        existing_admin = User.query.filter_by(username="Arun").first()
        if not existing_admin:
            admin_arun = User(
                name="Arun",
                username="Arun",
                password_hash=hash_pass("Arun@123"),
                mobile_number="9000000001",
                role=UserRole.ADMIN,
                is_first_login=False
            )
            db.session.add(admin_arun)
            print("Created Admin: Arun")

        existing_worker = User.query.filter_by(name="Madhu").first()
        if not existing_worker:
            worker_madhu = User(
                name="Madhu",
                pin_hash=hash_pass("1111"),
                mobile_number="9000000002",
                role=UserRole.FIELD_AGENT,
                is_first_login=False
            )
            db.session.add(worker_madhu)
            print("Created Worker: Madhu")

        db.session.commit()
        return jsonify({"msg": "Database seeded successfully. Login with Arun/Arun@123 or Madhu/1111"}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({"msg": "Seeding failed", "error": str(e)}), 500


@admin_tools_bp.route("/recalculate-accounting", methods=["POST"])
@jwt_required()
def recalculate_accounting():
    """
    Regenerates DailyAccountingReport records based on raw Collection data.
    Useful for fixing historical drift.
    """
    from models import Collection, DailyAccountingReport, UserRole
    from datetime import datetime, timedelta
    
    identity = get_jwt_identity()
    user = get_user_by_identity(identity)
    if not user or user.role != UserRole.ADMIN:
        return jsonify({"msg": "Access Denied"}), 403

    data = request.get_json()
    days = data.get("days", 30)
    
    start_date = (datetime.utcnow() - timedelta(days=days)).date()
    
    try:
        # Process day by day
        for i in range(days + 1):
            target_date = start_date + timedelta(days=i)
            
            # Aggregate collections for this date
            collections = Collection.query.filter(
                db.func.date(Collection.created_at) == target_date,
                Collection.status == "approved"
            ).all()
            
            total = sum(c.amount for c in collections)
            cash = sum(c.amount for c in collections if c.payment_mode == "cash")
            upi = sum(c.amount for c in collections if c.payment_mode == "upi")
            
            # Update or create report
            report = DailyAccountingReport.query.filter_by(report_date=target_date).first()
            if not report:
                report = DailyAccountingReport(report_date=target_date)
                db.session.add(report)
            
            report.total_amount = total
            report.cash_amount = cash
            report.upi_amount = upi
            
        db.session.commit()
        return jsonify({"msg": f"Recalculated accounting for the last {days} days."}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({"msg": "Recalculation failed", "error": str(e)}), 500


@admin_tools_bp.route("/verify-balances", methods=["GET"])
@jwt_required()
def verify_balances():
    """
    Detects if Loan.pending_amount drifts from the sum of pending EMISchedule.amount.
    """
    from models import Loan, EMISchedule, UserRole
    
    identity = get_jwt_identity()
    user = get_user_by_identity(identity)
    if not user or user.role != UserRole.ADMIN:
        return jsonify({"msg": "Access Denied"}), 403

    drift_detected = []
    
    loans = Loan.query.filter(Loan.status.in_(["active", "overdue"])).all()
    for loan in loans:
        emi_sum = (
            db.session.query(db.func.sum(EMISchedule.amount))
            .filter_by(loan_id=loan.id, status="pending")
            .scalar()
            or 0
        )
        
        # We allow a very small epsilon for float precision
        if abs(loan.pending_amount - emi_sum) > 0.01:
            drift_detected.append({
                "loan_id": loan.loan_id,
                "customer": loan.customer.name,
                "system_pending": loan.pending_amount,
                "schedule_sum": emi_sum,
                "drift": loan.pending_amount - emi_sum
            })
            
    return jsonify({
        "status": "warning" if drift_detected else "synced",
        "drifts": drift_detected,
        "checked_count": len(loans)
    }), 200
