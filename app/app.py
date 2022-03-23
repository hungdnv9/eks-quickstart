import os
import boto3
from flask import Flask, render_template, request, redirect, send_file, jsonify
from werkzeug.utils import secure_filename

app = Flask(__name__)

BUCKET = os.environ.get('BUCKET')

def get_s3_client():
    session = boto3.session.Session()
    client = session.client('s3')
    return client

@app.route('/')
def home():
    return render_template('index.html')

@app.route("/upload", methods=['POST'])
def upload():
    if request.method == "POST":
        image_file = request.files['file']
        content_type = request.mimetype
        filename = secure_filename(image_file.filename)

        client = get_s3_client()
        print(BUCKET)
        response = client.put_object(Body=image_file, Bucket=BUCKET, Key=filename, ContentType=content_type)        

        if response['ResponseMetadata']['HTTPStatusCode'] != 200:
            return jsonify({'error': 'upload image failed'}), 400 

        return jsonify({'pass': 'upload image successfull'}), 200

@app.route("/images", methods=['GET'])
def list_images():
    contents = []
    client = get_s3_client()
    for item in client.list_objects(Bucket=BUCKET)['Contents']:
        contents.append(item)
    return jsonify({'items': contents})

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)
