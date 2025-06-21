# File: test_carla_env_random.py

import numpy as np
import torch
import argparse
import time
import cv2
import os
from carla_fusion_env import CarlaFusionEnv
from fusion_attention_module import AttentionFusion

def main(log=False, log_dir='debug_logs', rear_chase_camera=False, random_spawn=False, map_name='Town01'):
    env = CarlaFusionEnv(rear_chase_camera=rear_chase_camera, random_spawn=random_spawn, map_name=map_name)
    fusion = AttentionFusion()

    obs, info = env.reset()
    print("Initial obs shapes:")
    for k, v in obs.items():
        print(f"  {k}: {v.shape}")

    total_start = time.time()
    for step in range(10):
        step_start = time.time()
        action = env.action_space.sample()
        obs, reward, terminated, truncated, info = env.step(action)

        # Fusion output
        rgb = torch.tensor(obs['rgb']).unsqueeze(0)
        depth = torch.tensor(obs['depth']).unsqueeze(0)
        lidar = torch.tensor(obs['lidar']).unsqueeze(0)
        fused = fusion(rgb, depth, lidar)

        step_time = time.time() - step_start
        print(f"\nStep {step}, action: {action}")
        print(f"  Fused output: {fused.shape}, reward: {reward}, done: {terminated}, time: {step_time:.3f}s")

        if log:
            os.makedirs(log_dir, exist_ok=True)
            cv2.imwrite(f"{log_dir}/rgb_{step}.png", (obs['rgb'].transpose(1, 2, 0) * 255).astype(np.uint8))
            np.save(f"{log_dir}/depth_{step}.npy", obs['depth'])
            np.save(f"{log_dir}/lidar_{step}.npy", obs['lidar'])

    total_time = time.time() - total_start
    print(f"\n✅ Test completed in {total_time:.2f} seconds.")

    env.close()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--log', action='store_true', help="Save sensor data per step")
    parser.add_argument('--log_dir', type=str, default='debug_logs', help="Directory to save debug logs")
    parser.add_argument('--rear_chase_camera', action='store_true', help="Use rear chase camera")
    parser.add_argument('--random_spawn', action='store_true', help="Use random spawn point")
    parser.add_argument('--map_name', type=str, default='Town01', help="Map name")
    args = parser.parse_args()

    main(log=args.log, log_dir=args.log_dir, rear_chase_camera=args.rear_chase_camera, random_spawn=args.random_spawn, map_name=args.map_name)
