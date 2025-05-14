import carla
import numpy as np
import cv2
import os
import time

SAVE_DIR = 'sensor_output'
os.makedirs(SAVE_DIR, exist_ok=True)

def create_rgb_sensor(world, vehicle):
    blueprint = world.get_blueprint_library().find('sensor.camera.rgb')
    blueprint.set_attribute('image_size_x', '800')
    blueprint.set_attribute('image_size_y', '600')
    blueprint.set_attribute('fov', '90')
    cam_transform = carla.Transform(carla.Location(x=1.5, z=2.4))
    return world.spawn_actor(blueprint, cam_transform, attach_to=vehicle)

def create_depth_sensor(world, vehicle):
    blueprint = world.get_blueprint_library().find('sensor.camera.depth')
    blueprint.set_attribute('image_size_x', '800')
    blueprint.set_attribute('image_size_y', '600')
    blueprint.set_attribute('fov', '90')
    cam_transform = carla.Transform(carla.Location(x=1.5, z=2.4))
    return world.spawn_actor(blueprint, cam_transform, attach_to=vehicle)

def create_lidar_sensor(world, vehicle):
    blueprint = world.get_blueprint_library().find('sensor.lidar.ray_cast')
    blueprint.set_attribute('range', '50')
    blueprint.set_attribute('rotation_frequency', '10')
    blueprint.set_attribute('channels', '32')
    blueprint.set_attribute('points_per_second', '32000')
    lidar_transform = carla.Transform(carla.Location(z=2.5))
    return world.spawn_actor(blueprint, lidar_transform, attach_to=vehicle)

def to_bgra_array(image):
    return np.reshape(np.copy(image.raw_data), (image.height, image.width, 4))

def save_image(image, filename):
    array = to_bgra_array(image)[:, :, :3]  # Drop alpha
    cv2.imwrite(filename, cv2.cvtColor(array, cv2.COLOR_RGB2BGR))

def save_depth_image(image, filename):
    array = to_bgra_array(image)
    normalized = (array[:, :, 0] + array[:, :, 1]*256 + array[:, :, 2]*256*256) / (256**3 - 1)
    depth_meters = 1000 * normalized
    np.save(filename, depth_meters)

def save_lidar_data(point_cloud, filename):
    points = np.frombuffer(point_cloud.raw_data, dtype=np.float32).reshape(-1, 4)[:, :3]
    np.save(filename, points)

def main():
    client = carla.Client('localhost', 2000)
    client.set_timeout(5.0)
    world = client.get_world()

    blueprint_library = world.get_blueprint_library()
    vehicle_bp = blueprint_library.filter('model3')[0]
    spawn_point = world.get_map().get_spawn_points()[0]
    vehicle = world.spawn_actor(vehicle_bp, spawn_point)

    rgb = create_rgb_sensor(world, vehicle)
    depth = create_depth_sensor(world, vehicle)
    lidar = create_lidar_sensor(world, vehicle)

    sensors = [rgb, depth, lidar]

    frame_count = 0
    max_frames = 10

    def rgb_callback(image):
        nonlocal frame_count
        save_image(image, os.path.join(SAVE_DIR, f'rgb_{image.frame}.png'))
        frame_count += 1

    def depth_callback(image):
        save_depth_image(image, os.path.join(SAVE_DIR, f'depth_{image.frame}.npy'))

    def lidar_callback(point_cloud):
        save_lidar_data(point_cloud, os.path.join(SAVE_DIR, f'lidar_{point_cloud.frame}.npy'))

    rgb.listen(rgb_callback)
    depth.listen(depth_callback)
    lidar.listen(lidar_callback)

    try:
        while frame_count < max_frames:
            time.sleep(0.1)
    finally:
        for s in sensors:
            s.stop()
            s.destroy()
        vehicle.destroy()
        print(f'Done. Saved {frame_count} frames to {SAVE_DIR}/')

if __name__ == '__main__':
    main()
