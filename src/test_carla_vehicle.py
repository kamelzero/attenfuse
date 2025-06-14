# File: test_carla_vehicle.py
# Basic test to verify CARLA vehicle spawning and control

import carla
import time

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
        
        print("Vehicle spawned successfully")
        
        # Basic vehicle control
        control = carla.VehicleControl()
        control.throttle = 0.5
        vehicle.apply_control(control)
        
        # Wait a bit
        time.sleep(2)
        
        # Clean up
        vehicle.destroy()
        print("Test completed successfully")
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == '__main__':
    main() 