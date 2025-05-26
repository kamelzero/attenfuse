import carla
import random
import time
import queue
import numpy as np
from PIL import Image

def process_image(image, image_queue):
    # Convert CARLA raw image to PIL Image
    array = np.frombuffer(image.raw_data, dtype=np.dtype("uint8"))
    array = np.reshape(array, (image.height, image.width, 4))
    array = array[:, :, :3]  # Remove alpha channel
    image_queue.put(array)

def main():
    try:
        client = carla.Client('localhost', 2000)
        client.set_timeout(10.0)
        world = client.get_world()
        
        # Setup vehicle
        blueprint_library = world.get_blueprint_library()
        vehicle_bp = blueprint_library.filter('vehicle.tesla.model3')[0]
        spawn_point = random.choice(world.get_map().get_spawn_points())
        vehicle = world.spawn_actor(vehicle_bp, spawn_point)
        
        # Setup camera
        camera_bp = blueprint_library.find('sensor.camera.rgb')
        camera_bp.set_attribute('image_size_x', '800')
        camera_bp.set_attribute('image_size_y', '600')
        camera_spawn_point = carla.Transform(carla.Location(x=1.5, z=2.4))
        camera = world.spawn_actor(camera_bp, camera_spawn_point, attach_to=vehicle)
        
        # Setup image queue and callback
        image_queue = queue.Queue()
        camera.listen(lambda image: process_image(image, image_queue))
        
        # Move and capture
        print("Starting capture...")
        vehicle.set_autopilot(True)
        
        # Save a few images
        for i in range(5):
            print(f"Capturing image {i+1}/5...")
            array = image_queue.get()
            img = Image.fromarray(array)
            img.save(f'carla_image_{i}.png')
            time.sleep(1)
        
        # Cleanup
        camera.destroy()
        vehicle.destroy()
        print("Test completed! Check for carla_image_*.png files")
        
    except Exception as e:
        print(f"Error occurred: {e}")

if __name__ == '__main__':
    main()
