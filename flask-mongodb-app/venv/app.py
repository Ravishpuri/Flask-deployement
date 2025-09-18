from flask import Flask, request, jsonify # Import necessary modules from Flask
from pymongo import MongoClient # Import MongoClient to interact with MongoDB
from datetime import datetime # Import datetime to get the current time
import os # Import os to access environment variables
app = Flask(__name__)
client = MongoClient(os.environ.get("MONGODB_URI","mongodb://localhost:27017/"))

db = client.flask_db
collection = db.data

@app.route('/')
def index():
    return f"Welcome to the Flask app! The current time is: {datetime.now()}"

@app.route('/data'
, methods=['GET'
,
'POST'])
def data():
    if request.method =='POST':
        data = request.get_json()
        collection.insert_one(data)
        return jsonify({"status": "Data inserted"}), 201
    elif request.method =='GET':
        data = list(collection.find({}, {"_id": 0}))
        return jsonify(data), 200
    
if __name__=='__main__':
    app.run(host='0.0.0.0', port=5000)