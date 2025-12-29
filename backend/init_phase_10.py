from app import create_app
from extensions import db
from models import Customer, Loan, User, UserRole

def initialize_phase_10():
    app = create_app()
    with app.app_context():
        print("Creating tables...")
        db.create_all()
        
        # Check if we already have data
        if Customer.query.first():
            print("Data already exists. Skipping seed.")
            return

        print("Seeding sample data...")
        
        # 1. Create a sample customer
        customer = Customer(
            name="Arun Kumar",
            mobile_number="9876543210",
            address="123, Main Street, Chennai",
            area="T. Nagar"
        )
        db.session.add(customer)
        db.session.flush() # Get ID
        
        # 2. Create a sample loan for this customer
        loan = Loan(
            customer_id=customer.id,
            amount=50000.0,
            interest_rate=12.0,
            total_installments=50,
            pending_amount=50000.0,
            status='active'
        )
        db.session.add(loan)
        
        # 3. Ensure we have at least one manager and one agent
        # (Assuming they might already exist from Phase 9, but let's check)
        agent = User.query.filter_by(role=UserRole.FIELD_AGENT).first()
        if not agent:
            print("Warning: No field agent found. You might need to create one via the UI.")
        
        db.session.commit()
        print("Phase 10 initialization complete.")

if __name__ == "__main__":
    initialize_phase_10()
