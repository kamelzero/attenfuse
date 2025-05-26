import carla
import random
import time

def main():
    try:
        # Connect to CARLA
        print("Connecting to CARLA...")
        client = carla.Client('localhost', 2000)
        client.set_timeout(10.0)
        world = client.get_world()
        
        # Get the blueprint library and filter for vehicles
        print("Setting up vehicle...")
        blueprint_library = world.get_blueprint_library()
        vehicle_bp = blueprint_library.filter('vehicle.tesla.model3')[0]
        
        # Get a random spawn point
        spawn_points = world.get_map().get_spawn_points()
        spawn_point = random.choice(spawn_points)
        
        # Spawn the vehicle
        vehicle = world.spawn_actor(vehicle_bp, spawn_point)
        print(f"Spawned {vehicle_bp.id} at {spawn_point}")
        
        # Create a camera
        print("Setting up camera...")
        camera_bp = blueprint_library.find('sensor.camera.rgb')
        camera_bp.set_attribute('image_size_x', '800')
        camera_bp.set_attribute('image_size_y', '600')
        
        # Attach camera to vehicle
        camera_spawn_point = carla.Transform(carla.Location(x=1.5, z=2.4))
        camera = world.spawn_actor(camera_bp, camera_spawn_point, attach_to=vehicle)
        
        # Move vehicle forward
        print("Moving vehicle...")
        vehicle.set_autopilot(True)
        
        # Wait and observe
        print("Observing for 10 seconds...")
        time.sleep(10)
        
        # Cleanup
        print("Cleaning up...")
        camera.destroy()
        vehicle.destroy()
        print("Test completed successfully!")
        
    except Exception as e:
        print(f"Error occurred: {e}")
    
if __name__ == '__main__':
    main()
