import cv2
import numpy as np
import torch
import torchvision.models as models
import torchvision.transforms as transforms
from PIL import Image
import io
import os

# Initialize MobileNetV2 as a feature extractor
# We use a pre-trained model and remove the classifier to get embeddings
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
model = models.mobilenet_v2(pretrained=True)
model.classifier = torch.nn.Identity() # Remove the last layer
model.to(device)
model.eval()

# Face Detector (Haar Cascade is light and built-in with OpenCV)
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')

# Image Transforms for MobileNet
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])

def generate_face_embedding(image_bytes):
    """
    1. Detect face using OpenCV.
    2. Crop and preprocess face.
    3. Generate 1280-d embedding using MobileNetV2.
    """
    try:
        # Load image
        print("DEBUG: Face Utils - Starting face detection...")
        img_array = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
        if img is None:
            print("DEBUG: Face Utils - Invalid image data")
            return None, "Invalid image data"
            
        print(f"DEBUG: Face Utils - Image decoded. Size: {img.shape}")
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, 1.1, 4)
        print(f"DEBUG: Face Utils - Faces found: {len(faces)}")
        
        if len(faces) == 0:
            return None, "No face detected"
            
        # Take the largest face
        x, y, w, h = max(faces, key=lambda f: f[2] * f[3])
        face_img = img[y:y+h, x:x+w]
        
        # Convert to PIL for Torchvision
        face_rgb = cv2.cvtColor(face_img, cv2.COLOR_BGR2RGB)
        pil_img = Image.fromarray(face_rgb)
        
        # Preprocess and generate embedding
        print("DEBUG: Face Utils - Generating embedding with MobileNet...")
        input_tensor = transform(pil_img).unsqueeze(0).to(device)
        
        with torch.no_grad():
            embedding = model(input_tensor)
            
        # Convert to list for JSON storage
        embedding_list = embedding.cpu().numpy().flatten().tolist()
        print(f"DEBUG: Face Utils - Embedding generated! Len: {len(embedding_list)}")
        return embedding_list, None
        
    except Exception as e:
        print(f"DEBUG: Face Utils - ERROR: {str(e)}")
        return None, str(e)

def compare_embeddings(emb1, emb2):
    """Cosine Similarity comparison"""
    a = np.array(emb1)
    b = np.array(emb2)
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
