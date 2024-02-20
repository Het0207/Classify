import matplotlib.pyplot as plt
import cv2
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import os
from flask import Flask, request, Response
from yolo5face import get_model
from deepface import DeepFace
from yolo5face.get_model import get_model
from yolo5face.get_model import get_model
import matplotlib.pyplot as plt
from PIL import Image
import io
import numpy as np



app = Flask(__name__)
# image_dir = './divide_photos'

@app.route('/upload', methods=['POST'])
def upload_file():
  images = request.files.getlist('images')
  print(type(images))
  image_data = []
  # count = 0
  for image in images:
  #   count +=1
      image_data.append(Image.open(io.BytesIO(image.read())))
  
      
  result =[]
  
  
  for image  in image_data:
    if image is None :
      print("come")
      continue

    image = np.array(image)
    
    # image = cv2.imread(os.path.join(image_dir +'/team_photos',filename))

   
    # image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)


    cropped_faces = []

    
    model = get_model("yolov5n", device=0, min_face=24)
    enhanced_boxes, enhanced_key_points, enhanced_scores = model(image, target_size=[320, 640, 1280])
   
    fig, ax = plt.subplots(1)

    for bbox in enhanced_boxes:
        x_min, y_min, x_max, y_max = map(int, bbox)
        rect = patches.Rectangle((x_min, y_min), x_max - x_min, y_max - y_min, linewidth=2, edgecolor='g', facecolor='none')
        ax.add_patch(rect)
        face = image[y_min:y_max, x_min:x_max]
        cropped_faces.append(face)

   
    ax.imshow(image)
    plt.show()


    for i, face in enumerate(cropped_faces):
        plt.subplot(1, len(cropped_faces), i + 1)
        plt.imshow(face)
        plt.axis('off')


    plt.show()

    
    if len(result) == 0:
      for face in cropped_faces:

        curList = []

        curList.append(face)
        curList.append(image)

        result.append(curList)


    else :
    

      for face in cropped_faces:

        isUnique = False

        for dividedFaces in result:

          plt.imshow(dividedFaces[0])
          plt.show()

          
          
          temp = dividedFaces[0]
          if(checkFace(face , temp) == True):
            isUnique = True
            dividedFaces.append(image)


        
        if isUnique is False:
          curList = []
          curList.append(face)
          curList.append(image)
          result.append(curList)
          
  # return {'coubnt' : len(image_data)}
  return {"List_of_list_image": len(result)}

          
        
        
def checkFace(image_1,image_2):  
  result = DeepFace.verify(image_1, image_2 , enforce_detection =False)
  # print(result)
  return result['verified']
