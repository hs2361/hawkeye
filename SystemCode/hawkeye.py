import cv2
import numpy as np
from keras.models import load_model
import tensorflow as tf
from multiprocessing import Process
from firebase_admin import messaging, credentials, storage
import firebase_admin
from datetime import datetime
import threading
import time

hit = False
hit_sensitivity = 0
# If zero written here captures from laptop camera otherwise we can also pass in a video file here
device_id = './input.mp4'
cap = cv2.VideoCapture(device_id)

camera_fps = 30  # camera fps set to 30 by default can be changed to any other value
# how much time it'll wait (Note it may wait longer or slower depending upon how much fps your camera has and how much you have written)
footage_seconds = 5
# the code will wait till it gets camera_fps * footage_seconds number of frames regardless of the time taken for the frames to accumulate
topic = 'org1'

frames = []
counter = 0
flag = False
start_splicing = False
model = load_model('model_hawkeye')

cred = credentials.Certificate(
    "hawkeye-abd94-firebase-adminsdk-vz5ev-e084e72618.json")
firebase_admin.initialize_app(cred, {
    'storageBucket': 'hawkeye-abd94.appspot.com'
})
bucket = storage.bucket()

def prediction(current_frames, original_footage):
    current_frames = current_frames.reshape(1, 64, 224, 224, 5)
    prediction = model.predict(current_frames)

    if prediction[0][0] > 0.75:  # Assuming model predicts as [Nonviolence,Violence]
        global hit
        hit = True
        print("Hit")

        now = datetime.now().strftime("%Y%m%d%H%M%s")
        fourcc = cv2.VideoWriter_fourcc('M', 'P', '4', 'V')
        video_filename = f'Videos/{topic}_{now}.mp4'
        out = cv2.VideoWriter(video_filename, fourcc, camera_fps,
                              (original_footage[0].shape[1], original_footage[0].shape[0]))
        for frame in original_footage:
            out.write(frame)
        out.release()
        blob = bucket.blob(f"{topic}_{now}.mp4")
        blob.upload_from_filename(filename=video_filename)
        data = {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "camID": "007",
            "latitude": "23.4",
            "longitude": "89.1",
            "file": f"{topic}_{now}"
        }
        message = messaging.Message(
            notification=messaging.Notification(
                body="Violence Detected", title="Test Message"),
            topic=topic,
            data=data
        )
        response = messaging.send(message)
        print('Successfully sent message:', response)
    print(prediction)


def getOpticalFlow(video):
    gray_video = []
    for i in range(0, video.shape[0]):
        img = cv2.cvtColor((video[i]).astype('uint8'), cv2.COLOR_RGB2GRAY)
        gray_video.append(np.reshape(img, (224, 224, 1)))

    flows = []
    for i in range(0, video.shape[0]-1):
        flow = cv2.calcOpticalFlowFarneback(
            gray_video[i], gray_video[i+1], None, 0.5, 3, 15, 3, 5, 1.2, cv2.OPTFLOW_FARNEBACK_GAUSSIAN)
        flow[..., 0] -= np.mean(flow[..., 0])
        flow[..., 1] -= np.mean(flow[..., 1])
        flow[..., 0] = cv2.normalize(
            flow[..., 0], None, 0, 255, cv2.NORM_MINMAX)
        flow[..., 1] = cv2.normalize(
            flow[..., 1], None, 0, 255, cv2.NORM_MINMAX)
        flows.append(flow)

    flows.append(np.zeros((224, 224, 2)))
    return np.array(flows, dtype=np.float32)


def normalize(data):
    mean = np.mean(data)
    std = np.std(data)
    return (data-mean) / std


def pre_process(frames):
    curr_frames = np.zeros(
        (len(frames), frames[0].shape[0], frames[0].shape[1], frames[0].shape[2]))
    curr_frames_resized = np.zeros((64, 224, 224, 3))

    for i in range(0, 64):
        curr_ind = int((len(frames)/64)*i)
        curr_frames[i] = frames[curr_ind]

    for i in range(0, 64):
        curr_frame = curr_frames[i]
        curr_frame = cv2.resize(curr_frame, (224, 224),
                                interpolation=cv2.INTER_AREA)
        curr_frame = cv2.cvtColor(
            curr_frame.astype('uint8'), cv2.COLOR_BGR2RGB)
        curr_frame = np.reshape(curr_frame, (224, 224, 3))
        curr_frames_resized[i] = curr_frame

    curr_flows = getOpticalFlow(curr_frames_resized)

    result = np.zeros((len(curr_flows), 224, 224, 5))
    result[..., :3] = curr_frames_resized
    result[..., 3:] = curr_flows

    result = normalize(result)

    prediction(result, frames)


def thread_function():
    while True:
        if not hit and start_splicing:
            pre_process(frames)


x = threading.Thread(target=thread_function, daemon=True)
x.start()

while True:
    img = cap.read()  # Read automatically reads next frames so no duplicate frames
    cv2.imshow('frame', img[1])

    frames.append(img[1])
    counter = counter + 1

    if start_splicing:
        frames = frames[1:]

    if not hit:
        # Original Code
        if len(frames) == footage_seconds * camera_fps and counter >= camera_fps:
            flag = True

        if flag:
            # TODO : Make this function call independent of the main process
            # pre_process(frames)
            flag = False
            counter = 0
            start_splicing = True

    else:
        if hit_sensitivity > (60 * camera_fps):
            hit_sensitivity = 0
            hit = False
        else:
            hit_sensitivity = hit_sensitivity + 1
    time.sleep(float(1/camera_fps))
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# After the loop release the cap object
cap.release()
# Destroy all the windows
cv2.destroyAllWindows()
