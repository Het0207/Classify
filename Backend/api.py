from flask import Flask, request, Response
import matplotlib.pyplot as plt
from PIL import Image
import io

app = Flask(__name__)

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'images' not in request.files:
        return 'No file part'

    images = request.files.getlist('images')
    image_data = []

    for image in images:
        image_data.append(Image.open(io.BytesIO(image.read())))

    # Display the images
    # for i, data in enumerate(image_data):


    #     plt.figure()
    #     plt.imshow(data)
    #     plt.title(f"Image {i+1}")
    #     plt.axis('off')  # Turn off axis
    #     plt.show()

    return {"uploaded_images_count": len(image_data)}

if __name__ == '_main_':
    app.run(debug=True)