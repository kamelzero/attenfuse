import torch.nn as nn

class AttentionFusion(nn.Module):
    def __init__(self, embed_dim=128):
        super().__init__()
        self.rgb_conv = nn.Sequential(
            nn.Conv2d(3, 16, kernel_size=5, stride=2),
            nn.ReLU(),
            nn.Conv2d(16, embed_dim, kernel_size=3),
            nn.ReLU()
        )
        self.depth_conv = nn.Sequential(
            nn.Conv2d(1, 16, kernel_size=5, stride=2),
            nn.ReLU(),
            nn.Conv2d(16, embed_dim, kernel_size=3),
            nn.ReLU()
        )
        self.attn = nn.MultiheadAttention(embed_dim, num_heads=4, batch_first=True)
        self.flatten = nn.Flatten()

    def forward(self, rgb, depth):
        rgb_feat = self.rgb_conv(rgb)  # [B, C, H, W]
        depth_feat = self.depth_conv(depth)

        B, C, H, W = rgb_feat.shape
        rgb_flat = rgb_feat.view(B, C, -1).permute(0, 2, 1)     # [B, HW, C]
        depth_flat = depth_feat.view(B, C, -1).permute(0, 2, 1) # [B, HW, C]

        fused, _ = self.attn(rgb_flat, depth_flat, depth_flat)
        return fused.mean(dim=1)  # Global pooled embedding
