# File: cleanup_carla_actors.py

import carla

def main():
    client = carla.Client('localhost', 2000)
    client.set_timeout(5.0)
    world = client.get_world()

    actors = world.get_actors()
    print(f"\nConnected. Total actors in world: {len(actors)}")

    # Filter and destroy only relevant actor types
    to_destroy = [a for a in actors if (
        a.type_id.startswith('vehicle.') or
        a.type_id.startswith('sensor.') or
        a.type_id.startswith('walker.')
    )]

    print(f"Destroying {len(to_destroy)} vehicle/sensor/walker actors...")
    for actor in to_destroy:
        print(f" - {actor.type_id} ({actor.id})")
        actor.destroy()

    print("✅ Cleanup complete.")

if __name__ == '__main__':
    main()
