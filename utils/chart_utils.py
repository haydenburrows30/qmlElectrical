import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
import numpy as np

def safe_dash_pattern(dash_pattern):
    """
    Ensure that all dash pattern values are positive to avoid matplotlib errors
    
    Args:
        dash_pattern: A dash pattern (on, off) tuple or list
        
    Returns:
        A safe dash pattern with only positive values
    """
    if dash_pattern is None:
        return None
        
    # Ensure it's a list
    dash_list = list(dash_pattern)
    
    # Replace any non-positive values with 1
    for i in range(len(dash_list)):
        if dash_list[i] <= 0:
            dash_list[i] = 1
            
    return dash_list

def plot_with_safe_line_style(ax, x, y, linestyle='--', **kwargs):
    """
    Plot a line with a safe linestyle that won't trigger matplotlib errors
    
    Args:
        ax: Matplotlib axes object to plot on
        x: X-coordinates
        y: Y-coordinates
        linestyle: Line style string or dash pattern
        **kwargs: Additional kwargs for plot function
        
    Returns:
        The line artist
    """
    # Handle built-in line styles like '--', '-', ':', etc.
    if isinstance(linestyle, str):
        # These are safe to use directly if they're built-in styles
        return ax.plot(x, y, linestyle=linestyle, **kwargs)
    
    # For explicit dash patterns, ensure they're safe
    safe_style = safe_dash_pattern(linestyle)
    return ax.plot(x, y, dashes=safe_style, **kwargs)

def draw_phasor(ax, magnitude, angle_deg, origin=(0, 0), color='blue', label=None, 
                linestyle='-', head_width=0.05, head_length=0.1):
    """
    Draw a phasor (vector) on the given matplotlib axes
    
    Args:
        ax: Matplotlib axes object
        magnitude: Phasor magnitude
        angle_deg: Phasor angle in degrees
        origin: Origin point for the phasor
        color: Phasor color
        label: Optional label for the phasor
        linestyle: Line style (must be safe)
        head_width: Arrow head width
        head_length: Arrow head length
        
    Returns:
        The arrow artist
    """
    # Convert angle to radians
    angle_rad = np.radians(angle_deg)
    
    # Calculate end point
    dx = magnitude * np.cos(angle_rad)
    dy = magnitude * np.sin(angle_rad)
    end_x = origin[0] + dx
    end_y = origin[1] + dy
    
    # Ensure we're using a safe line style
    if linestyle == '--':
        linestyle = (4, 2)  # Use explicit values for dashed line
    
    if isinstance(linestyle, tuple) or isinstance(linestyle, list):
        linestyle = safe_dash_pattern(linestyle)
    
    # Draw the arrow
    arrow = ax.arrow(origin[0], origin[1], dx, dy, 
                     head_width=head_width, 
                     head_length=head_length,
                     fc=color, ec=color, 
                     length_includes_head=True,
                     linestyle=linestyle,
                     label=label)
    
    return arrow
