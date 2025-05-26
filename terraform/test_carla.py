import carla

try:
    # Connect to CARLA server
    client = carla.Client('localhost', 2000)
    client.set_timeout(10.0)
    
    # Get world and print info
    world = client.get_world()
    print(f"Connected to CARLA version: {client.get_server_version()}")
    print(f"Client version: {client.get_client_version()}")
    print(f"Map name: {world.get_map().name}")
except Exception as e:
    print(f"Error: {e}")
