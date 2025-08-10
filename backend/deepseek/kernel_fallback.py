# kernel.py - CPU Fallback Version (بە شوێنی triton)
"""
CPU Fallback implementation for DeepSeek when Triton is not available
This provides basic functionality without GPU optimizations
"""
import torch
import torch.nn.functional as F
from typing import Tuple

def act_quant(x: torch.Tensor, block_size: int = 128) -> Tuple[torch.Tensor, torch.Tensor]:
    """
    CPU fallback for activation quantization
    """
    # Simple quantization for CPU
    original_shape = x.shape
    x_flat = x.view(-1, block_size)
    
    # Compute scale factors
    max_vals = torch.max(torch.abs(x_flat), dim=1, keepdim=True)[0]
    scale = max_vals / 127.0  # Scale to int8 range
    scale = torch.clamp(scale, min=1e-8)  # Avoid division by zero
    
    # Quantize
    x_quant = torch.round(x_flat / scale)
    x_quant = torch.clamp(x_quant, -127, 127)
    
    # Return quantized values and scale
    x_quant = x_quant.view(original_shape).to(torch.int8)
    scale = scale.squeeze(-1)
    
    return x_quant, scale

def weight_dequant(weight: torch.Tensor, scale: torch.Tensor, block_size: int = 128) -> torch.Tensor:
    """
    CPU fallback for weight dequantization
    """
    if weight.dtype != torch.int8:
        return weight
    
    # Convert back to float
    weight_float = weight.float()
    
    # Apply scale
    if scale.numel() == 1:
        return weight_float * scale
    else:
        # Broadcast scale to match weight dimensions
        scale_expanded = scale.view(-1, 1).expand(weight.shape[0], weight.shape[1])
        return weight_float * scale_expanded

def fp8_gemm(
    a: torch.Tensor, 
    a_scale: torch.Tensor, 
    b: torch.Tensor, 
    b_scale: torch.Tensor
) -> torch.Tensor:
    """
    CPU fallback for FP8 GEMM operation
    """
    # Dequantize inputs
    a_float = a.float() * a_scale.unsqueeze(-1)
    b_float = weight_dequant(b, b_scale)
    
    # Perform standard matrix multiplication
    result = torch.matmul(a_float, b_float.t())
    
    return result

# Additional utility functions for compatibility
def setup_cpu_mode():
    """Setup optimal CPU configuration"""
    torch.set_num_threads(4)  # Optimize for CPU
    torch.set_default_dtype(torch.float32)  # Use float32 for CPU
    print("✅ Kernel fallback mode activated (CPU optimized)")

def check_triton_availability() -> bool:
    """Check if Triton is available"""
    try:
        import triton
        return True
    except ImportError:
        return False

# Auto-setup on import
if not check_triton_availability():
    setup_cpu_mode()
    print("⚠️ Triton not available - using CPU fallback mode")