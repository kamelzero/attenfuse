# File: carla_fusion_env.py

import carla
import gymnasium as gym
import numpy as np
import time
import cv2
import random

class CarlaFusionEnv(gym.Env):
    def __init__(self, rear_chase_camera=True, random_spawn=True, map_name="Town01", reward_fn=None):
        super().__init__()

        # Store reward function
        self.reward_fn = reward_fn or self._default_reward_fn

        # Connect to CARLA
        self.client = carla.Client('localhost', 2000)
        self.client.set_timeout(10.0)

        self.world = self.client.get_world()
        if map_name != self.world.get_map().name:
            self.client.load_world(map_name)
            # Wait for map to fully load
            max_wait = 10  # seconds
            for i in range(max_wait * 10):
                self.world = self.client.get_world()
                if self.world.get_map().name.endswith(map_name):
                    break
                time.sleep(0.1)
            else:
                raise RuntimeError(f"Timeout waiting for {map_name} to load")

        settings = self.world.get_settings()
        settings.synchronous_mode = True
        settings.fixed_delta_seconds = 0.05  # 20 FPS
        self.world.apply_settings(settings)

        self.blueprint_library = self.world.get_blueprint_library()
        self.vehicle_bp = self.blueprint_library.filter('model3')[0]
        spawn_points = self.world.get_map().get_spawn_points()
        if random_spawn:
            self.spawn_point = random.choice(spawn_points)
        else:
            self.spawn_point = spawn_points[0]

        self.rear_chase_camera = rear_chase_camera

        self.rgb, self.depth, self.lidar = None, None, None
        self.rgb_data, self.depth_data, self.lidar_data = None, None, None

        # Observation and action space
        self.observation_space = gym.spaces.Dict({
            'rgb': gym.spaces.Box(0, 255, shape=(3, 128, 128), dtype=np.uint8),
            'depth': gym.spaces.Box(0, 255, shape=(1, 128, 128), dtype=np.uint8),
            'lidar': gym.spaces.Box(0, 255, shape=(1, 200, 200), dtype=np.uint8),
        })
        self.action_space = gym.spaces.Discrete(3)  # left, straight, right

        self.vehicle = None
        self._setup_vehicle_and_sensors()

    def _setup_vehicle_and_sensors(self):
        # Destroy lingering actors
        for actor in self.world.get_actors():
            if actor.type_id.startswith("vehicle.") or actor.type_id.startswith("sensor."):
                actor.destroy()

        self.vehicle = self.world.try_spawn_actor(self.vehicle_bp, self.spawn_point)
        if self.vehicle is None:
            raise RuntimeError("Spawn failed even after cleanup. Try restarting CARLA.")

        def spawn_sensor(bp_name, transform):
            bp = self.blueprint_library.find(bp_name)
            bp.set_attribute('image_size_x', '800')
            bp.set_attribute('image_size_y', '600')
            bp.set_attribute('fov', '90')
            return self.world.spawn_actor(bp, transform, attach_to=self.vehicle)

        self.rgb = spawn_sensor('sensor.camera.rgb', carla.Transform(carla.Location(x=1.5, z=2.4)))
        self.depth = spawn_sensor('sensor.camera.depth', carla.Transform(carla.Location(x=1.5, z=2.4)))

        lidar_bp = self.blueprint_library.find('sensor.lidar.ray_cast')
        lidar_bp.set_attribute('range', '50')
        lidar_bp.set_attribute('rotation_frequency', '10')
        lidar_bp.set_attribute('channels', '32')
        lidar_bp.set_attribute('points_per_second', '32000')
        self.lidar = self.world.spawn_actor(
            lidar_bp, carla.Transform(carla.Location(z=2.5)), attach_to=self.vehicle)

        self.rgb.listen(lambda img: setattr(self, 'rgb_data', img))
        self.depth.listen(lambda img: setattr(self, 'depth_data', img))
        self.lidar.listen(lambda pc: setattr(self, 'lidar_data', pc))

    def reset(self, *, seed=None, options=None):
        super().reset(seed=seed)
        if seed is not None:
            self.action_space.seed(seed)
            self.observation_space.seed(seed)
            
        self._cleanup()
        time.sleep(0.5)
        self._setup_vehicle_and_sensors()
        time.sleep(0.5)
        
        observation = self._get_obs()
        info = {}  # You can populate this with metadata if needed

        self.step_counter = 0
        return observation, info

    def step(self, action):
        v_loc = self.vehicle.get_location()
        v_vel = self.vehicle.get_velocity()
        speed = (v_vel.x**2 + v_vel.y**2 + v_vel.z**2)**0.5 * 3.6  # convert m/s to km/h
        print(f"[DEBUG] Location: ({v_loc.x:.1f}, {v_loc.y:.1f}), Speed: {speed:.1f} km/h")

        tl = self.vehicle.get_traffic_light()
        if tl is not None:
            state = tl.get_state()
            print(f"[DEBUG] Traffic light state: {state}")

        control = carla.VehicleControl()
        control.throttle = 0.8
        control.steer = {-1: -0.5, 0: 0.0, 1: 0.5}[action - 1]
        self.vehicle.apply_control(control)

        spectator = self.world.get_spectator()
        transform = self.vehicle.get_transform()
        if self.rear_chase_camera:
            spectator.set_transform(carla.Transform(
                transform.location + carla.Location(x=-6, z=3),
                transform.rotation
            ))
        else:
            spectator.set_transform(carla.Transform(
                transform.location + carla.Location(z=20),
                carla.Rotation(pitch=-90)
            ))

        self.world.tick()
        obs = self._get_obs()

        # Count low-speed frames
        self.stuck_counter = getattr(self, "stuck_counter", 0)
        if speed < 0.5:
            self.stuck_counter += 1
        else:
            self.stuck_counter = 0

        # Get reward and termination from reward function
        reward, terminated = self.reward_fn(
            speed=speed,
            stuck_counter=self.stuck_counter,
            step_counter=getattr(self, "step_counter", 0)
        )

        self.step_counter = getattr(self, "step_counter", 0)
        self.step_counter += 1
        truncated = self.step_counter >= 200  # ~10 seconds
        return obs, reward, terminated, truncated, {}

    def _get_obs(self):
        while self.rgb_data is None or self.depth_data is None or self.lidar_data is None:
            time.sleep(0.05)

        # RGB: [0, 255] and uint8
        rgb = np.frombuffer(self.rgb_data.raw_data, dtype=np.uint8).reshape((600, 800, 4))[:, :, :3]
        rgb = cv2.resize(rgb, (128, 128))
        rgb = rgb.transpose(2, 0, 1).astype(np.uint8)

        # Depth processing - fixed to avoid overflow
        raw_depth = np.frombuffer(self.depth_data.raw_data, dtype=np.uint8).reshape((600, 800, 4))
        # Use a simpler approach: just use the first channel as depth
        depth_raw = raw_depth[:, :, 0].astype(np.float32)
        depth_meters = depth_raw / 255.0 * 100  # Scale to reasonable range
        depth = cv2.resize(depth_meters, (128, 128))[np.newaxis, :, :].astype(np.float32)
        depth = np.clip(depth, 0, 100.0) / 100.0
        # Depth: normalize to [0, 255] and convert to uint8
        depth = (depth * 255).clip(0, 255).astype(np.uint8)

        # LiDAR processing - ensure float32
        lidar_array = np.frombuffer(self.lidar_data.raw_data, dtype=np.float32).reshape(-1, 4)[:, :3]
        bev = np.zeros((200, 200), dtype=np.float32)
        x = ((lidar_array[:, 0] + 10.0) / 0.1).astype(int)
        y = ((lidar_array[:, 1]) / 0.1).astype(int)
        mask = (x >= 0) & (x < 200) & (y >= 0) & (y < 200)
        bev[y[mask], x[mask]] = 1.0
        lidar = bev[np.newaxis, :, :].astype(np.float32)
        # LiDAR: BEV binary already in [0, 1], scale to [0, 255]
        lidar = (lidar * 255).astype(np.uint8)

        return {
            'rgb': rgb,
            'depth': depth,
            'lidar': lidar,
        }

    def close(self):
        self._cleanup()

    def _cleanup(self):
        if self.vehicle:
            self.vehicle.destroy()
            self.vehicle = None

        if self.world:
            settings = self.world.get_settings()
            settings.synchronous_mode = False
            self.world.apply_settings(settings)

        for sensor in [self.rgb, self.depth, self.lidar]:
            if sensor:
                sensor.stop()
                sensor.destroy()
        self.rgb, self.depth, self.lidar = None, None, None

    def _default_reward_fn(self, speed, stuck_counter, step_counter):
        """Default reward function that can be overridden."""
        reward = speed / 10.0
        terminated = stuck_counter > 30  # ~1.5 seconds stuck
        if terminated:
            reward -= 5.0
        if speed < 0.5:
            reward -= 0.1
        return reward, terminated
