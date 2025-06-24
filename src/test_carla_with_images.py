# File: test_carla_with_images.py
# Test to verify CARLA camera sensor and image capture

import carla
import time
import cv2
import numpy as np

def process_image(image):
    # Convert raw image to numpy array
    array = np.frombuffer(image.raw_data, dtype=np.dtype("uint8"))
    array = np.reshape(array, (image.height, image.width, 4))
    array = array[:, :, :3]  # Remove alpha channel
    return array

def main():
    try:
        # Connect to CARLA server
        client = carla.Client('localhost', 2000)
        client.set_timeout(10.0)
        world = client.get_world()
        
        # Spawn a vehicle
        blueprint_library = world.get_blueprint_library()
        vehicle_bp = blueprint_library.find('vehicle.tesla.model3')
        spawn_point = carla.Transform(carla.Location(x=0, y=0, z=1))
        vehicle = world.spawn_actor(vehicle_bp, spawn_point)
        
        # Add a camera sensor
        camera_bp = blueprint_library.find('sensor.camera.rgb')
        camera_transform = carla.Transform(carla.Location(x=2.0, z=1.0))
        camera = world.spawn_actor(camera_bp, camera_transform, attach_to=vehicle)
        
        # Set up image callback
        image_data = []
        def image_callback(image):
            image_data.append(process_image(image))
        
        camera.listen(image_callback)
        
        # Wait for some images
        time.sleep(2)
        
        # Save an image if we got any
        if image_data:
            cv2.imwrite('test_image.jpg', image_data[-1])
            print("Image saved successfully")
        
        # Clean up
        camera.destroy()
        vehicle.destroy()
        print("Test completed successfully")
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == '__main__':
    main() 