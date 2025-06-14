from stable_baselines3 import PPO
from stable_baselines3.common.env_checker import check_env
from carla_fusion_env import CarlaFusionEnv

import time
time.sleep(5)

def custom_reward_fn(speed, stuck_counter, step_counter):
    # Custom reward logic here
    reward = speed / 20.0  # Different speed scaling
    terminated = stuck_counter > 20  # Different stuck threshold
    if terminated:
        reward -= 10.0  # Different termination penalty
    if speed < 1.0:  # Different stuck speed threshold
        reward -= 0.2
    return reward, terminated

env = CarlaFusionEnv(reward_fn=custom_reward_fn)
check_env(env)

model = PPO("MultiInputPolicy", env, verbose=1, device="cuda")
model.learn(total_timesteps=100_000)
model.save("ppo_attention_agent")
