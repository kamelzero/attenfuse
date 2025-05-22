lidar_bp = blueprint_library.find('sensor.lidar.ray_cast')
lidar = world.spawn_actor(lidar_bp, carla.Transform(carla.Location(z=2.4)), attach_to=vehicle)

camera_rgb = world.spawn_actor(
    blueprint_library.find('sensor.camera.rgb'),
    carla.Transform(carla.Location(x=1.5, z=2.4)),
    attach_to=vehicle
)

camera_depth = world.spawn_actor(
    blueprint_library.find('sensor.camera.depth'),
    carla.Transform(carla.Location(x=1.5, z=2.4)),
    attach_to=vehicle
)

def preprocess_image(image):
    array = np.frombuffer(image.raw_data, dtype=np.uint8).reshape((image.height, image.width, 4))
    return torch.from_numpy(array[:, :, :3]).permute(2, 0, 1).float() / 255.0  # [3, H, W]

