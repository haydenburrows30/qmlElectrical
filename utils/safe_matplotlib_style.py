import matplotlib as mpl
import matplotlib.pyplot as plt

def apply_safe_styles():
    """
    Apply a set of safe matplotlib styles that avoid dashed line issues
    """
    # Create safe line styles dictionary
    safe_line_styles = {
        'solid': '-',
        'dotted': ':',
        'dashed': (4.0, 2.0),  # Explicit positive values
        'dashdot': (4.0, 2.0, 1.0, 2.0),  # Explicit positive values
        'loosely-dashed': (6.0, 2.0),  # Explicit positive values
        'loosely-dotted': (1.0, 4.0),  # Explicit positive values
        'densely-dashed': (3.0, 1.0),  # Explicit positive values
        'densely-dotted': (1.0, 1.0)   # Explicit positive values
    }
    
    # Default cycler with safe line styles
    from cycler import cycler
    color_cycle = plt.rcParams['axes.prop_cycle']
    
    # Create a new line style cycler that uses only safe styles
    line_cycler = cycler(linestyle=['-', (4,2), ':', (4,2,1,2)])
    
    # Combine with color cycle
    plt.rcParams['axes.prop_cycle'] = color_cycle + line_cycler
    
    return safe_line_styles

def get_safe_line_style(style_name):
    """
    Get a safe line style that won't cause matplotlib errors
    
    Args:
        style_name: Name of the style ('dashed', 'dotted', etc.)
        
    Returns:
        A safe line style specification
    """
    safe_styles = {
        'solid': '-',
        'dotted': ':',
        'dashed': (4.0, 2.0),  # Explicit positive values
        'dashdot': (4.0, 2.0, 1.0, 2.0),  # Explicit positive values
    }
    
    return safe_styles.get(style_name, '-')  # Default to solid if not found
