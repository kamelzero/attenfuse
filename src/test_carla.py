# File: test_carla.py
# Basic test to verify CARLA server connection

import carla

def main():
    try:
        client = carla.Client('localhost', 2000)
        client.set_timeout(10.0)
        world = client.get_world()
        print(f"Connected to CARLA version: {client.get_server_version()}")
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == '__main__':
    main() 