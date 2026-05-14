import os
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torch.distributions import Categorical

# ==============================
# 設定
# ==============================

OBS_DIM = 11     # 観測次元（要調整）
ACT_DIM = 5        # 行動数（要調整）

GAMMA = 0.99
LAMBDA = 0.95
CLIP_EPS = 0.2
LR = 3e-4

BATCH_SIZE = 1024
EPOCHS = 10

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, "models", "model.pt")

ACTIONS = [-2, -1, 0, 1, 2]

# ==============================
# ネットワーク
# ==============================

class PolicyNet(nn.Module):
    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(OBS_DIM, 128),
            nn.Tanh(),
            nn.Linear(128, 128),
            nn.Tanh(),
            nn.Linear(128, ACT_DIM),
            nn.Softmax(dim=-1)
        )

    def forward(self, x):
        return self.net(x)


class ValueNet(nn.Module):
    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(OBS_DIM, 128),
            nn.Tanh(),
            nn.Linear(128, 128),
            nn.Tanh(),
            nn.Linear(128, 1)
        )

    def forward(self, x):
        return self.net(x)


policy = PolicyNet()
value_net = ValueNet()

optimizer = optim.Adam(
    list(policy.parameters()) + list(value_net.parameters()),
    lr=LR
)

# ==============================
# バッファ
# ==============================

buffer = []

# ==============================
# 初期化（NetLogoから呼ぶ）
# ==============================

def init_agent(model_path=MODEL_PATH, seed=None):
    print("init start")
    global buffer

    buffer = []

    if seed is not None:
        np.random.seed(seed)
        torch.manual_seed(seed)
        print("torch imported")

    if os.path.exists(model_path):
        try:
            load_model(model_path)
            print(f"[PPO] loaded from {model_path}")
        except Exception as e:
            print(f"[PPO] load failed: {e}")
    else:
        print(f"[PPO] no model found at {model_path}, starting fresh")

# ==============================
# 行動選択（NetLogoから呼ぶ）
# ==============================

def policy_step(obs):

    obs = np.asarray(obs, dtype=np.float32)
    obs_t = torch.tensor(obs).unsqueeze(0)

    with torch.no_grad():
        probs = policy(obs_t)
        dist = Categorical(probs)
        action = dist.sample()

    return ACTIONS[action.item()]


# ==============================
# 経験保存（NetLogoから呼ぶ）
# ==============================

def store_transition(obs, action, reward, next_obs, done):
    #print(f"[py]Store_transition: obs={obs}, action={action}, reward={reward}, next_obs={next_obs}, done={done}")

    global buffer

    obs = np.asarray(obs, dtype=np.float32)
    next_obs = np.asarray(next_obs, dtype=np.float32)

    obs_t = torch.tensor(obs).unsqueeze(0)

    with torch.no_grad():
        probs = policy(obs_t)
        dist = Categorical(probs)
        log_prob = dist.log_prob(torch.tensor(action))

        value = value_net(obs_t)

    buffer.append((
        obs,
        action,
        reward,
        next_obs,
        done,
        value.item(),
        log_prob.item()
    ))

    #print(len(buffer))

    if len(buffer) >= BATCH_SIZE:
        pass
    #    train()
    #    buffer.clear()


# ==============================
# PPO学習
# ==============================
def train():
    print("TRAIN START", flush=True)

    try:

        print(f"buffer size={len(buffer)}", flush=True)

        # PPO training code

        print("TRAIN END", flush=True)

    except Exception as e:
        print("TRAIN ERROR", flush=True)
        print(e, flush=True)

        import traceback
        traceback.print_exc()

        raise e
    
    if len(buffer) >= BATCH_SIZE:
        pass





def train2():
    print("TRAINING PPO SKIPPED")
    return


def train1():
    #print("TRAINING PPO")
    if len(buffer) >= BATCH_SIZE:
        pass

    obs, actions, rewards, next_obs, dones, values, log_probs = zip(*buffer)

    obs = torch.tensor(obs, dtype=torch.float32)
    actions = torch.tensor(actions)
    rewards = torch.tensor(rewards, dtype=torch.float32)
    dones = torch.tensor(dones, dtype=torch.float32)
    values = torch.tensor(values, dtype=torch.float32)
    old_log_probs = torch.tensor(log_probs, dtype=torch.float32)

    # --- GAE ---
    advantages = []
    gae = 0
    next_value = 0

    for t in reversed(range(len(rewards))):
        delta = rewards[t] + GAMMA * next_value * (1 - dones[t]) - values[t]
        gae = delta + GAMMA * LAMBDA * (1 - dones[t]) * gae
        advantages.insert(0, gae)
        next_value = values[t]

    advantages = torch.tensor(advantages, dtype=torch.float32)
    returns = advantages + values

    # 正規化
    advantages = (advantages - advantages.mean()) / (advantages.std() + 1e-8)

    # --- PPO更新 ---
    for _ in range(EPOCHS):

        probs = policy(obs)
        dist = Categorical(probs)
        new_log_probs = dist.log_prob(actions)

        ratio = torch.exp(new_log_probs - old_log_probs)

        surr1 = ratio * advantages
        surr2 = torch.clamp(ratio, 1 - CLIP_EPS, 1 + CLIP_EPS) * advantages

        policy_loss = -torch.min(surr1, surr2).mean()

        values_pred = value_net(obs).squeeze()
        value_loss = nn.MSELoss()(values_pred, returns)

        loss = policy_loss + 0.5 * value_loss

        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

    print("[PPO] training step complete")


# ==============================
# 保存・読み込み
# ==============================

def save_model(path=MODEL_PATH):
    print("SAVE MODEL START")
    #print(path)

    torch.save({
        "policy": policy.state_dict(),
        "value": value_net.state_dict()
    }, path)

    print(f"[PPO] saved to {path}")
    #print("SAVE MODEL DONE")


def load_model(path=MODEL_PATH):
    try:
        data = torch.load(path, weights_only=True)
    except TypeError:
        # Older PyTorch without weights_only support
        data = torch.load(path)

    policy.load_state_dict(data["policy"])
    value_net.load_state_dict(data["value"])
