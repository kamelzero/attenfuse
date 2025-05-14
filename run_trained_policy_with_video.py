# File: run_trained_policy_with_video.py

import torch
import cv2
import numpy as np
from stable_baselines3 import PPO
from carla_fusion_env import CarlaFusionEnv

def main():
    env = CarlaFusionEnv(rear_chase_camera=True, random_spawn=True)
    model = PPO.load("ppo_carla_attention")

    obs = env.reset()
    video_out = cv2.VideoWriter(
        'ppo_agent_run.avi',
        cv2.VideoWriter_fourcc(*'XVID'),
        10,  # FPS
        (128, 128)  # Output resolution (matches RGB resize)
    )

    print("🎬 Recording agent policy run...")

    for step in range(100):
        action, _ = model.predict(obs, deterministic=True)
        obs, reward, done, _ = env.step(action)

        # Save current RGB frame
        rgb_np = (obs['rgb'].transpose(1, 2, 0) * 255).astype(np.uint8)
        video_out.write(cv2.cvtColor(rgb_np, cv2.COLOR_RGB2BGR))

        print(f"Step {step} | Action: {action} | Reward: {reward:.2f}")
        if done:
            print("🚧 Episode ended early.")
            break

    video_out.release()
    env.close()
    print("✅ Video saved as 'ppo_agent_run.avi'")

if __name__ == "__main__":
    main()
