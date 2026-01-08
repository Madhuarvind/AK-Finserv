import sys
import os
sys.path.append(r'e:\Arun_Finance\backend')
from app import create_app
from extensions import db
from models import User, FaceEmbedding

app = create_app()
with app.app_context():
    embeddings = FaceEmbedding.query.all()
    print(f"Total embeddings: {len(embeddings)}")
    for emb in embeddings:
        user = User.query.get(emb.user_id)
        if hasattr(emb.embedding_data, '__len__'):
            length = len(emb.embedding_data)
        else:
            length = "Unknown"
        print(f"User: {user.name if user else 'Unknown'}, Length: {length}")
