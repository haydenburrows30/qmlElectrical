import os
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import numpy as np
from matplotlib import rcParams
import math

# Configure matplotlib for consistent font usage
rcParams['font.family'] = 'sans-serif'
rcParams['font.sans-serif'] = ['DejaVu Sans', 'Arial', 'Helvetica', 'sans-serif']
rcParams['mathtext.fontset'] = 'dejavusans'  # Use DejaVu Sans for math

def create_transformer_diagram(filename='transformer_diagram.png'):
    """Generate a transformer diagram with primary and secondary windings."""
    # Create directory if needed
    os.makedirs('assets/formulas', exist_ok=True)
    
    # Create figure and axis
    fig, ax = plt.subplots(figsize=(5, 4), dpi=100)
    
    # Draw the transformer core (E-I shape)
    # E part
    ax.add_patch(patches.Rectangle((0.2, 0.3), 0.1, 2.4, fc='gray', ec='black'))
    ax.add_patch(patches.Rectangle((0.3, 0.3), 0.4, 0.2, fc='gray', ec='black'))
    ax.add_patch(patches.Rectangle((0.3, 1.4), 0.4, 0.2, fc='gray', ec='black'))
    ax.add_patch(patches.Rectangle((0.3, 2.5), 0.4, 0.2, fc='gray', ec='black'))
    
    # I part
    ax.add_patch(patches.Rectangle((1.0, 0.3), 0.1, 2.4, fc='gray', ec='black'))
    
    # Primary winding (more turns)
    primary_x = 0.5
    for i in range(12):
        y = 0.6 + i * 0.15
        ax.add_patch(patches.Rectangle((primary_x, y), 0.2, 0.1, fc='red', ec='black'))
    
    # Secondary winding (fewer turns)
    secondary_x = 0.8
    for i in range(6):
        y = 0.8 + i * 0.3
        ax.add_patch(patches.Rectangle((secondary_x, y), 0.2, 0.15, fc='blue', ec='black'))
    
    # Add terminals
    # Primary
    ax.plot([0.1, 0.5], [0.6, 0.6], 'k-', linewidth=2)
    ax.plot([0.1, 0.5], [2.35, 2.35], 'k-', linewidth=2)
    # Secondary
    ax.plot([1.1, 1.5], [0.8, 0.8], 'k-', linewidth=2)
    ax.plot([1.1, 1.5], [2.3, 2.3], 'k-', linewidth=2)
    
    # Add labels
    ax.text(0.1, 2.5, r'$V_p$', fontsize=14)
    ax.text(1.3, 2.5, r'$V_s$', fontsize=14)
    ax.text(0.1, 0.4, r'$I_p$', fontsize=14)
    ax.text(1.3, 0.4, r'$I_s$', fontsize=14)
    ax.text(0.5, 0.1, 'Primary', fontsize=12)
    ax.text(0.8, 0.1, 'Secondary', fontsize=12)
    
    # Set limits and remove axes
    ax.set_xlim(0, 1.6)
    ax.set_ylim(0, 3.0)
    ax.axis('off')
    
    # Save the figure
    plt.tight_layout()
    output_path = os.path.join('assets/formulas', filename)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"Created transformer diagram: {output_path}")

def create_voltage_drop_diagram(filename='voltage_drop_diagram.png'):
    """Generate a voltage drop diagram showing a cable with voltage levels."""
    # Create directory if needed
    os.makedirs('assets/formulas', exist_ok=True)
    
    # Create figure and axis
    fig, ax = plt.subplots(figsize=(6, 3), dpi=100)
    
    # Draw cable
    cable_length = 8
    ax.plot([1, 1+cable_length], [1, 1], 'k-', linewidth=6)
    
    # Draw source
    circle = plt.Circle((0.7, 1), 0.3, fc='lightgray', ec='black')
    ax.add_patch(circle)
    ax.text(0.7, 1, '~', fontsize=20, ha='center', va='center')
    
    # Draw load
    ax.add_patch(patches.Rectangle((1+cable_length+0.2, 0.7), 0.6, 0.6, 
                                  fc='white', ec='black', hatch='///'))
    
    # Draw voltage levels
    x = np.linspace(1, 1+cable_length, 100)
    # Create a slight voltage drop curve
    voltage = 1.0 - 0.2 * (x - 1) / cable_length
    ax.plot(x, voltage + 1.5, 'b-', linewidth=2)
    
    # Add voltage markers
    ax.plot([1, 1], [1.5, 2.5], 'b--', alpha=0.5)
    ax.plot([1+cable_length, 1+cable_length], [1.5, 2.3], 'b--', alpha=0.5)
    
    # Add labels
    ax.text(1, 2.6, r'$V_1$', fontsize=14, ha='center')
    ax.text(1+cable_length, 2.4, r'$V_2$', fontsize=14, ha='center')
    ax.text(0.7, 0.3, 'Source', fontsize=12, ha='center')
    ax.text(1+cable_length+0.5, 0.3, 'Load', fontsize=12, ha='center')
    ax.text(1+cable_length/2, 0.7, 'Cable', fontsize=12, ha='center')
    ax.text(1+cable_length/2, 2.0, 'Voltage Drop', fontsize=12, ha='center')
    
    # Save the figure
    plt.tight_layout()
    output_path = os.path.join('assets/formulas', filename)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"Created voltage drop diagram: {output_path}")

def create_power_triangle_diagram(filename='power_triangle_diagram.png'):
    """Generate power triangle diagram showing before and after PF correction."""
    # Create directory if needed
    os.makedirs('assets/formulas', exist_ok=True)
    
    # Create figure and axis
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(8, 4))
    
    # Draw power triangle before correction
    # Assuming PF = 0.8, P = 100kW
    power = 100
    pf1 = 0.8
    phi1 = math.acos(pf1)
    q1 = power * math.tan(phi1)
    s1 = power / pf1
    
    # Triangle 1 - Before Correction
    ax1.arrow(0, 0, power, 0, head_width=5, head_length=5, fc='blue', ec='blue')
    ax1.arrow(0, 0, 0, q1, head_width=5, head_length=5, fc='red', ec='red')
    ax1.arrow(0, 0, power, q1, head_width=0, head_length=0, fc='purple', ec='purple', linestyle='--')
    ax1.set_xlim(0, power*1.2)
    ax1.set_ylim(0, q1*1.2)
    
    # Add labels
    ax1.text(power/2, -10, 'P = 100kW', ha='center')
    ax1.text(-10, q1/2, 'Q = 75kVAR', va='center', rotation=90)
    ax1.text(power/2, q1/2, 'S = 125kVA', ha='center', rotation=math.degrees(phi1))
    ax1.text(20, 5, 'PF = 0.80', fontweight='bold')
    ax1.set_title('Before PF Correction')
    
    # Triangle 2 - After Correction
    pf2 = 0.95
    phi2 = math.acos(pf2)
    q2 = power * math.tan(phi2)
    s2 = power / pf2
    qc = q1 - q2  # Capacitor kVAR
    
    ax2.arrow(0, 0, power, 0, head_width=5, head_length=5, fc='blue', ec='blue')
    ax2.arrow(0, 0, 0, q2, head_width=5, head_length=5, fc='red', ec='red')
    ax2.arrow(0, 0, power, q2, head_width=0, head_length=0, fc='purple', ec='purple', linestyle='--')
    ax2.plot([0, 0], [q2, q1], 'g--', linewidth=2)
    ax2.text(power/2, q1/2, 'Qc', color='green', fontweight='bold')
    
    # Add labels
    ax2.text(power/2, -10, 'P = 100kW', ha='center')
    ax2.text(-10, q2/2, f'Q = {q2:.1f}kVAR', va='center', rotation=90)
    ax2.text(power/2, q2/3, f'S = {s2:.1f}kVA', ha='center', rotation=math.degrees(phi2))
    ax2.text(20, 5, 'PF = 0.95', fontweight='bold')
    ax2.set_title('After PF Correction')
    
    ax2.set_xlim(0, power*1.2)
    ax2.set_ylim(0, q1*1.2)
    
    # Set common labels
    fig.text(0.5, 0.01, 'Active Power (kW)', ha='center')
    fig.text(0.01, 0.5, 'Reactive Power (kVAR)', va='center', rotation=90)
    
    # Save the figure
    plt.tight_layout()
    output_path = os.path.join('assets/formulas', filename)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"Created power triangle diagram: {output_path}")

def create_cable_ampacity_chart(filename='cable_ampacity_chart.png'):
    """Generate chart showing cable ampacity for different sizes."""
    # Create directory if needed
    os.makedirs('assets/formulas', exist_ok=True)
    
    # Create figure and axis
    fig, ax = plt.subplots(figsize=(8, 5))
    
    # Cable sizes
    sizes = [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120]
    
    # Ampacity for different installation methods (simplified)
    conduit_pvc = [18, 24, 32, 41, 57, 76, 101, 125, 151, 192, 232, 269]
    conduit_xlpe = [23, 31, 42, 54, 75, 100, 133, 164, 198, 253, 306, 354]
    
    # Plot
    ax.plot(sizes, conduit_pvc, 'b-o', label='PVC Insulation')
    ax.plot(sizes, conduit_xlpe, 'r-s', label='XLPE Insulation')
    
    # Labels and title
    ax.set_xlabel('Cable Size (mm²)')
    ax.set_ylabel('Current Carrying Capacity (A)')
    ax.set_title('Cable Ampacity by Size and Insulation Type')
    ax.legend()
    ax.grid(True)
    
    # Use logarithmic scale for better visualization of smaller sizes
    ax.set_xscale('log')
    ax.set_xticks(sizes)
    ax.set_xticklabels([str(s) for s in sizes])
    
    # Save the figure
    plt.tight_layout()
    output_path = os.path.join('assets/formulas', filename)
    plt.savefig(output_path, dpi=150)
    plt.close()
    print(f"Created cable ampacity chart: {output_path}")

def create_relay_coordination_diagram(filename='relay_coordination.png'):
    """Generate a relay coordination diagram showing multiple relays in series."""
    os.makedirs('assets/formulas', exist_ok=True)
    
    fig, ax = plt.subplots(figsize=(8, 6))
    
    # Draw power source
    circle = plt.Circle((0.1, 0.5), 0.1, fc='lightgray', ec='black')
    ax.add_patch(circle)
    ax.text(0.1, 0.5, '~', ha='center', va='center', fontsize=20)
    
    # Draw busses and relays
    x_positions = [0.3, 0.5, 0.7]
    for i, x in enumerate(x_positions):
        # Draw bus
        ax.plot([x-0.05, x+0.05], [0.5, 0.5], 'k-', linewidth=3)
        
        # Draw relay
        rect = plt.Rectangle((x-0.03, 0.6), 0.06, 0.1, fc='lightblue', ec='black')
        ax.add_patch(rect)
        ax.text(x, 0.75, f'Relay {i+1}', ha='center')
        
        # Draw connection line
        if x < x_positions[-1]:
            ax.plot([x+0.05, x+0.15], [0.5, 0.5], 'k-', linewidth=2)
    
    # Draw load
    rect = plt.Rectangle((0.85, 0.4), 0.1, 0.2, fc='white', ec='black', hatch='///')
    ax.add_patch(rect)
    ax.text(0.9, 0.3, 'Load', ha='center')
    
    # Add arrows for fault current direction
    ax.arrow(0.2, 0.4, 0.6, 0, head_width=0.02, head_length=0.03, fc='red', ec='red')
    ax.text(0.5, 0.35, 'Fault Current', color='red', ha='center')
    
    ax.set_xlim(0, 1)
    ax.set_ylim(0.2, 0.9)
    ax.axis('off')
    
    plt.savefig(f'assets/formulas/{filename}', dpi=150, bbox_inches='tight')
    plt.close()
    print(f"Created relay coordination diagram: assets/formulas/{filename}")

def create_discrimination_diagram(filename='discrimination.png'):
    """Generate a discrimination diagram showing time-current curves."""
    os.makedirs('assets/formulas', exist_ok=True)
    
    fig, ax = plt.subplots(figsize=(8, 6))
    
    # Create log-scale axes
    ax.set_xscale('log')
    ax.set_yscale('log')
    
    # Draw multiple relay curves
    # Start currents from 1.1x pickup to avoid denominator near zero
    currents = np.logspace(np.log10(110), 4, 100)  # From 110A to 10000A
    
    # Calculate times with safety check for denominator
    def calc_relay_times(currents, pickup, tds):
        times = []
        for i in currents:
            multiple = i/pickup
            if multiple <= 1.0:
                times.append(100)  # Use large value for visualization
            else:
                times.append((0.14 * tds) / ((multiple ** 0.02) - 1))
        return np.array(times)
    
    # Primary relay
    times1 = calc_relay_times(currents, 100, 0.5)
    ax.plot(currents, times1, 'b-', label='Primary Relay')
    
    # Backup relay
    times2 = calc_relay_times(currents, 200, 1.0)
    ax.plot(currents, times2, 'r--', label='Backup Relay')
    
    # Add coordination margin indicator
    ax.annotate('Coordination\nMargin', 
                xy=(500, 0.5), 
                xytext=(500, 1.0),
                arrowprops=dict(arrowstyle='<->'),
                ha='right')
    
    ax.grid(True)
    ax.set_xlabel('Current (A)')
    ax.set_ylabel('Time (s)')
    ax.legend()
    ax.set_title('Relay Discrimination Curves')
    
    output_path = os.path.join('assets/formulas', filename)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"Created discrimination diagram: {output_path}")

def main():
    """Generate all diagram images."""
    create_transformer_diagram()
    create_voltage_drop_diagram()
    create_power_triangle_diagram()
    create_cable_ampacity_chart()
    create_relay_coordination_diagram()
    create_discrimination_diagram()

if __name__ == "__main__":
    main()
