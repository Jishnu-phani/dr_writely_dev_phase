from flask import Flask, request
import os

app = Flask(__name__)

# Directory to save uploaded files
UPLOAD_FOLDER = 'D:\\Inferentia2024\\flask_server\\audio_input'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

@app.route('/upload', methods=['POST'])
def upload_audio():
    # Check if the request has the 'audio' part
    if 'audio' not in request.files:
        return "No file part", 400

    file = request.files['audio']

    # If no file is selected
    if file.filename == '':
        return "No selected file", 400

    # Save the file
    file_path = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(file_path)

    return f"File uploaded and saved at {file_path}", 200

if __name__ == '__main__':
    # Run the Flask app on your local machine, allowing access from other devices
    app.run(host='0.0.0.0', port=5000)
