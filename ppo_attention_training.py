# File: ppo_attention_training.py

import gymnasium as gym
import torch
import torch.nn as nn
import numpy as np
from stable_baselines3 import PPO
from stable_baselines3.common.torch_layers import BaseFeaturesExtractor
from fusion_attention_module import AttentionFusion
from carla_fusion_env import CarlaFusionEnv

# --- Custom Feature Extractor ---
class FusionFeatureExtractor(BaseFeaturesExtractor):
    def __init__(self, observation_space: gym.spaces.Dict):
        super().__init__(observation_space, features_dim=64)
        self.fusion = AttentionFusion()

    def forward(self, obs):
        return self.fusion(obs['rgb'], obs['depth'], obs['lidar'])  # [B, 64]

# --- Training Setup ---
def main():
    env = CarlaFusionEnv()

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
