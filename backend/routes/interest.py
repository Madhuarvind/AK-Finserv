from flask import Blueprint, jsonify

interest_bp = Blueprint('interest', __name__)

@interest_bp.route('/', methods=['GET'])
def index():
    return jsonify({"msg": "Interest module active"}), 200
