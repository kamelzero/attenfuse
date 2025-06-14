# File: train_ppo_attention.py

import gymnasium as gym
import torch
import torch.nn as nn
import numpy as np
from stable_baselines3 import PPO
from stable_baselines3.common.torch_layers import BaseFeaturesExtractor
from fusion_attention_module import AttentionFusion
from carla_fusion_env import CarlaFusionEnv

def custom_reward_fn(speed, stuck_counter, step_counter):
    """Custom reward function for PPO training.
    
    Args:
        speed: Current speed in km/h
        stuck_counter: Number of consecutive frames with low speed
        step_counter: Total number of steps in episode
    
    Returns:
        reward: Calculated reward
        terminated: Whether episode should end
    """
    # Base reward for moving
    reward = speed / 15.0  # Slightly lower speed scaling than default
    
    # Penalize being stuck
    if speed < 1.0:  # Higher threshold than default
        reward -= 0.2  # Stronger penalty than default
    
    # Terminate if stuck for too long
    terminated = stuck_counter > 20  # Shorter timeout than default
    if terminated:
        reward -= 8.0  # Stronger termination penalty
    
    return reward, terminated

# --- Custom Feature Extractor ---
class FusionFeatureExtractor(BaseFeaturesExtractor):
    def __init__(self, observation_space: gym.spaces.Dict):
        super().__init__(observation_space, features_dim=64)
        self.fusion = AttentionFusion()

    def forward(self, obs):
        return self.fusion(obs['rgb'], obs['depth'], obs['lidar'])  # [B, 64]

# --- Training Setup ---
def main():
    env = CarlaFusionEnv(reward_fn=custom_reward_fn)

    policy_kwargs = dict(
        features_extractor_class=FusionFeatureExtractor,
        features_extractor_kwargs=dict(),
        net_arch=[dict(pi=[64, 32], vf=[64, 32])],
    )

    model = PPO("MultiInputPolicy", env, policy_kwargs=policy_kwargs, verbose=1)
    model.learn(total_timesteps=5000)
    model.save("ppo_carla_attention")

if __name__ == '__main__':
    main() 