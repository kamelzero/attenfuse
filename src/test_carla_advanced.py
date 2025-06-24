# File: test_carla_advanced.py
# Advanced test to verify multiple CARLA sensors and features

import carla
import time
import numpy as np

def main():
    try:
        # Connect to CARLA server
        client = carla.Client('localhost', 2000)
        client.set_timeout(10.0)
        world = client.get_world()
        
        # Set synchronous mode
        settings = world.get_settings()
        settings.synchronous_mode = True
        settings.fixed_delta_seconds = 0.05
        world.apply_settings(settings)
        
        # Spawn a vehicle
        blueprint_library = world.get_blueprint_library()
        vehicle_bp = blueprint_library.find('vehicle.tesla.model3')
        spawn_point = carla.Transform(carla.Location(x=0, y=0, z=1))
        vehicle = world.spawn_actor(vehicle_bp, spawn_point)
        
        # Add multiple sensors
        sensors = []
        
        # RGB Camera
        camera_bp = blueprint_library.find('sensor.camera.rgb')
        camera_transform = carla.Transform(carla.Location(x=2.0, z=1.0))
        camera = world.spawn_actor(camera_bp, camera_transform, attach_to=vehicle)
        sensors.append(camera)
        
        # Lidar
        lidar_bp = blueprint_library.find('sensor.lidar.ray_cast')
        lidar_transform = carla.Transform(carla.Location(x=0, z=2.0))
        lidar = world.spawn_actor(lidar_bp, lidar_transform, attach_to=vehicle)
        sensors.append(lidar)
        
        # Collision sensor
        collision_bp = blueprint_library.find('sensor.other.collision')
        collision = world.spawn_actor(collision_bp, carla.Transform(), attach_to=vehicle)
        sensors.append(collision)
        
        print("All sensors spawned successfully")
        
        # Basic vehicle control
        control = carla.VehicleControl()
        control.throttle = 0.5
        vehicle.apply_control(control)
        
        # Simulate for a few frames
        for _ in range(10):
            world.tick()
            time.sleep(0.05)
        
        # Clean up
        for sensor in sensors:
            sensor.destroy()
        vehicle.destroy()
        
        # Reset synchronous mode
        settings.synchronous_mode = False
        world.apply_settings(settings)
        
        print("Test completed successfully")
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == '__main__':
    main() 