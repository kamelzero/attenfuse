# File: fusion_attention_module.py

import torch
import torch.nn as nn

class ConvEncoder(nn.Module):
    def __init__(self, in_channels, out_channels=64):
        super().__init__()
        self.encoder = nn.Sequential(
            nn.Conv2d(in_channels, 32, kernel_size=5, stride=2, padding=2),  # [B, 32, H/2, W/2]
            nn.ReLU(),
            nn.Conv2d(32, out_channels, kernel_size=3, stride=2, padding=1), # [B, out, H/4, W/4]
            nn.ReLU(),
        )

    def forward(self, x):
        return self.encoder(x)

class AttentionFusion(nn.Module):
    def __init__(self, embed_dim=64, n_heads=4):
        super().__init__()
        self.rgb_encoder   = ConvEncoder(in_channels=3, out_channels=embed_dim)
        self.depth_encoder = ConvEncoder(in_channels=1, out_channels=embed_dim)
        self.lidar_encoder = ConvEncoder(in_channels=1, out_channels=embed_dim)

        self.attn = nn.MultiheadAttention(embed_dim, num_heads=n_heads, batch_first=True)
        self.output_head = nn.Sequential(
            nn.Linear(embed_dim, 128),
            nn.ReLU(),
            nn.Linear(128, 64),  # Final fused feature
        )

    def forward(self, rgb, depth, lidar):
        # Encode each input: [B, C, H, W] → [B, embed, H', W']
        rgb_feat   = self.rgb_encoder(rgb)
        depth_feat = self.depth_encoder(depth)
        lidar_feat = self.lidar_encoder(lidar)

        # Flatten spatial dims: [B, C, H, W] → [B, HW, C]
        def flatten_feat(feat):
            B, C, H, W = feat.shape
            return feat.view(B, C, H * W).transpose(1, 2)  # [B, HW, C]

        rgb_tokens   = flatten_feat(rgb_feat)
        depth_tokens = flatten_feat(depth_feat)
        lidar_tokens = flatten_feat(lidar_feat)

        # Concatenate tokens: [B, N, C] where N = H*W*3
        tokens = torch.cat([rgb_tokens, depth_tokens, lidar_tokens], dim=1)

        # Self-attention fusion
        fused_tokens, attn_weights = self.attn(tokens, tokens, tokens)  # [B, N, C]

        # Mean pool across token sequence
        fused = fused_tokens.mean(dim=1)  # [B, C]

        return self.output_head(fused)    # [B, 64]
