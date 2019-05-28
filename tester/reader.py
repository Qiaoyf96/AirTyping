import cv2
import time

cap = cv2.VideoCapture("VID.MOV")

#cap = cv2.VideoCapture(0)
 
# Define the codec and create VideoWriter object
#fourcc = cv2.cv.FOURCC(*'XVID')
# fourcc = cv2.VideoWriter_fourcc(*'XVID') 
# out = cv2.VideoWriter('output1.avi', fourcc, 20, (1920, 1080))
 
num=0
 
while cap.isOpened():
    # get a frame
    rval, frame = cap.read()
    depth = frame[381:972, 443:, :]
    depth = cv2.cvtColor(depth, cv2.COLOR_BGR2GRAY)

    rgb = frame[972:1563, 443:, :]

    print(depth)
    # print(frame.shape)
    
    

    # cv2.imwrite("sample.png", frame)
    break
    # save a frame
    # if rval==True:
    #     fps = cap.get(cv2.CAP_PROP_FPS)
    #     print("Frames per second using video.get(cv2.CAP_PROP_FPS) : {0}".format(fps)) 
    # else:
    #     break
    # show a frame
    # cv2.imshow("capture", frame)
    # if cv2.waitKey(1) & 0xFF == ord('q'):
    #     break
cap.release()
cv2.destroyAllWindows()
