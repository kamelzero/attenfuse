from stable_baselines3 import PPO
from stable_baselines3.common.env_checker import check_env
from carla_fusion_env import CarlaFusionEnv

import time
time.sleep(5)

env = CarlaFusionEnv()  # your custom wrapper
check_env(env)

model = PPO("MultiInputPolicy", env, verbose=1, device="cuda")
model.learn(total_timesteps=100_000)
model.save("ppo_attention_agent")
