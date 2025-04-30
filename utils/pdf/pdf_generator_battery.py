from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
import os
from datetime import datetime
import gc
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="battery_pdf")

class BatteryPdfGenerator:
    """Handles PDF generation for battery calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for battery calculations
        
        Args:
            data: Dictionary containing battery calculation data
            filepath: Output PDF path
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create the PDF document
            doc = SimpleDocTemplate(
                filepath,
                pagesize=A4,
                rightMargin=72,
                leftMargin=72,
                topMargin=72,
                bottomMargin=72
            )
            
            # Create styles
            styles = getSampleStyleSheet()
            title_style = styles["Title"]
            heading_style = styles["Heading1"]
            subheading_style = styles["Heading2"]
            normal_style = styles["Normal"]
            
            # Create custom caption style
            caption_style = ParagraphStyle(
                'Caption',
                parent=styles['Normal'],
                fontSize=9,
                alignment=1,  # Center alignment
                italics=True
            )
            
            # Create content
            story = []
            
            # Add title
            story.append(Paragraph("Battery System Analysis Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Input parameters section
            story.append(Paragraph("Input Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create parameters table
            params_data = [
                ["Parameter", "Value"],
                ["Load", f"{data.get('load', 0):.2f} Watts"],
                ["System Voltage", f"{data.get('system_voltage', 0):.1f} Volts"],
                ["Backup Time", f"{data.get('backup_time', 0):.1f} Hours"],
                ["Depth of Discharge", f"{data.get('depth_of_discharge', 0):.0f}%"],
                ["Battery Type", f"{data.get('battery_type', 'N/A')}"]
            ]
            
            # Create and style the table
            params_table = Table(params_data)
            params_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (1, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (1, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (1, 0), 12),
                ('BOTTOMPADDING', (0, 0), (1, 0), 6),
                ('BACKGROUND', (0, 1), (1, -1), colors.white),
                ('GRID', (0, 0), (1, -1), 1, colors.black),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                ('ALIGN', (1, 0), (1, -1), 'RIGHT')
            ]))
            
            story.append(params_table)
            story.append(Spacer(1, 24))
            
            # Results section
            story.append(Paragraph("Calculation Results", heading_style))
            story.append(Spacer(1, 12))
            
            # Create results table
            results_data = [
                ["Parameter", "Value"],
                ["Current Draw", f"{data.get('current_draw', 0):.2f} A"],
                ["Required Capacity", f"{data.get('required_capacity', 0):.1f} Ah"],
                ["Recommended Capacity", f"{data.get('recommended_capacity', 0):.1f} Ah"],
                ["Energy Storage", f"{data.get('energy_storage', 0):.2f} kWh"],
                ["Safety Factor", f"{data.get('safety_factor', 0):.2f}"]
            ]
            
            # Create and style the results table
            results_table = Table(results_data)
            results_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (1, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (1, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (1, 0), 12),
                ('BOTTOMPADDING', (0, 0), (1, 0), 6),
                ('BACKGROUND', (0, 1), (1, -1), colors.white),
                ('GRID', (0, 0), (1, -1), 1, colors.black),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                ('ALIGN', (1, 0), (1, -1), 'RIGHT')
            ]))
            
            story.append(results_table)
            story.append(Spacer(1, 24))
            
            # Add battery visualization if image path is provided
            if 'battery_image_path' in data and data['battery_image_path'] and os.path.exists(data['battery_image_path']):
                story.append(Paragraph("Battery State of Charge Visualization", heading_style))
                story.append(Spacer(1, 12))
                
                # Get the image dimensions to maintain aspect ratio
                from PIL import Image as PILImage
                with PILImage.open(data['battery_image_path']) as img:
                    orig_width, orig_height = img.size
                
                # Calculate the aspect ratio
                aspect_ratio = orig_height / orig_width
                
                # Calculate appropriate image width based on available page width
                available_width = doc.width * 0.95  # Use 95% of available width
                
                # Set the image width and calculate height to maintain aspect ratio
                img = Image(data['battery_image_path'])
                img.drawWidth = available_width
                img.drawHeight = available_width * aspect_ratio
                
                # Add the image
                story.append(img)
                story.append(Spacer(1, 12))
                
                # Add image caption with custom caption style
                story.append(Paragraph(
                    "Figure 1: Battery Capacity and Depth of Discharge Visualization",
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Battery information section
            story.append(Paragraph("Battery System Information", heading_style))
            story.append(Spacer(1, 12))
            
            # Add information about the battery type
            battery_type = data.get('battery_type', 'Lead Acid')
            
            if battery_type == "Lead Acid":
                story.append(Paragraph("Lead Acid Battery Characteristics:", subheading_style))
                story.append(Paragraph(
                    "• Typical depth of discharge: 50%\n"
                    "• Cycle life: 500-1000 cycles\n"
                    "• Energy density: 30-50 Wh/kg\n"
                    "• Self-discharge rate: 5-15% per month\n"
                    "• Operating temperature: -20°C to 50°C\n"
                    "• Requires regular maintenance\n"
                    "• Relatively low cost per kWh",
                    normal_style
                ))
            elif battery_type == "Lithium Ion":
                story.append(Paragraph("Lithium Ion Battery Characteristics:", subheading_style))
                story.append(Paragraph(
                    "• Typical depth of discharge: 80%\n"
                    "• Cycle life: 2000-5000 cycles\n"
                    "• Energy density: 100-265 Wh/kg\n"
                    "• Self-discharge rate: 2-3% per month\n"
                    "• Operating temperature: -20°C to 60°C\n"
                    "• Maintenance free\n"
                    "• Higher initial cost but better long-term value",
                    normal_style
                ))
            elif battery_type == "AGM":
                story.append(Paragraph("AGM (Absorbent Glass Mat) Battery Characteristics:", subheading_style))
                story.append(Paragraph(
                    "• Typical depth of discharge: 50-70%\n"
                    "• Cycle life: 500-1200 cycles\n"
                    "• Energy density: 30-50 Wh/kg\n"
                    "• Self-discharge rate: 1-3% per month\n"
                    "• Operating temperature: -40°C to 50°C\n"
                    "• Maintenance free\n"
                    "• More expensive than flooded lead acid but more robust",
                    normal_style
                ))
            
            story.append(Spacer(1, 12))
            
            # Add battery sizing information
            story.append(Paragraph("Battery Sizing Considerations:", subheading_style))
            story.append(Paragraph(
                "• For critical loads, sizing should include additional safety factors.\n"
                "• Temperature affects battery performance - capacity decreases at lower temperatures.\n"
                "• Expected battery life decreases with deeper discharge cycles.\n"
                "• Consider future expansion when sizing a battery bank.\n"
                f"• The {data.get('recommended_capacity', 0):.1f} Ah capacity recommendation includes a safety factor of {data.get('safety_factor', 0):.2f}.",
                normal_style
            ))
            
            # Build the PDF
            doc.build(story)
            
            # Force garbage collection
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating PDF: {e}")
            import traceback
            logger.error(traceback.format_exc())
            
            # Force garbage collection even on error
            gc.collect()
            
            return False
    
    def generate_battery_chart(self, data, filepath):
        """Generate a battery visualization chart
        
        Args:
            data: Dictionary containing battery data
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Extract data
            recommended_capacity = data.get('recommended_capacity', 100)
            depth_of_discharge = data.get('depth_of_discharge', 50)
            battery_type = data.get('battery_type', 'Lead Acid')
            
            # Create figure with appropriate size and padding
            fig, ax = plt.subplots(figsize=(10, 6))
            fig.subplots_adjust(left=0.15, right=0.85, top=0.9, bottom=0.15)
            
            # Create battery visualization
            self._draw_battery(ax, recommended_capacity, depth_of_discharge, battery_type)
            
            # Save figure
            plt.savefig(filepath, dpi=150, bbox_inches='tight')
            plt.close(fig)
            return True
        
        except Exception as e:
            logger.error(f"Error generating battery chart: {e}")
            plt.close()  # Close any open figures
            return False

    def _draw_battery(self, ax, capacity, dod, battery_type):
        """Draw a battery visualization
        
        Args:
            ax: Matplotlib axis to draw on
            capacity: Recommended capacity in Ah
            dod: Depth of discharge percentage
            battery_type: Type of battery
        """
        # Battery dimensions
        width = 0.6
        height = 0.8
        terminal_width = 0.1
        terminal_height = 0.05
        
        # Battery outline
        battery = plt.Rectangle((0.2, 0.1), width, height, 
                               fill=False, linewidth=2, color='black')
        ax.add_patch(battery)
        
        # Battery terminal
        terminal = plt.Rectangle((0.2 + width/2 - terminal_width/2, 0.1 + height), 
                                terminal_width, terminal_height, 
                                fill=True, color='black')
        ax.add_patch(terminal)
        
        # Determine fill level - this is the usable portion (DoD)
        fill_height = height * (dod / 100)
        
        # Battery fill (usable capacity)
        fill = plt.Rectangle((0.2, 0.1), width, fill_height, 
                             fill=True, alpha=0.5, color='green')
        ax.add_patch(fill)
        
        # Add text for capacity and DoD
        battery_type_colors = {
            "Lead Acid": "blue",
            "Lithium Ion": "purple",
            "AGM": "darkgreen"
        }
        color = battery_type_colors.get(battery_type, "black")
        
        # Capacity text
        ax.text(0.2 + width/2, 0.1 + height + terminal_height + 0.03, 
               f"Capacity: {capacity:.1f} Ah", 
               horizontalalignment='center', color=color, fontsize=12, fontweight='bold')
        
        # DoD text
        ax.text(0.2 + width/2, 0.1 + fill_height/2, 
               f"Usable\n{dod}%", 
               horizontalalignment='center', color='black', fontsize=10)
        
        # Unusable text - if there's enough room
        if (height - fill_height) > 0.1:
            ax.text(0.2 + width/2, 0.1 + fill_height + (height - fill_height)/2, 
                   f"Unusable\n{100-dod}%", 
                   horizontalalignment='center', color='gray', fontsize=10)
        
        # Battery type
        ax.text(0.2 + width/2, 0.05, 
               f"Battery Type: {battery_type}", 
               horizontalalignment='center', color=color, fontsize=10)
        
        # Set axis properties
        ax.set_xlim(0, 1)
        ax.set_ylim(0, 1)
        ax.set_aspect('equal')
        ax.axis('off')
        
        # Add title
        ax.set_title('Battery Capacity Visualization', fontsize=14, pad=20)

    def generate_battery_usage_chart(self, data, filepath):
        """Generate a chart showing battery usage over time
        
        Args:
            data: Dictionary containing battery data
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Extract data
            backup_time = data.get('backup_time', 4)
            depth_of_discharge = data.get('depth_of_discharge', 50)
            battery_type = data.get('battery_type', 'Lead Acid')
            
            # Create figure with comfortable margins
            plt.figure(figsize=(10, 6))
            plt.subplots_adjust(left=0.12, right=0.88, top=0.9, bottom=0.15)
            
            # Time points
            hours = np.linspace(0, backup_time, 100)
            
            # Model the discharge curve based on battery type
            if battery_type == "Lead Acid":
                # Lead Acid batteries have more voltage drop
                capacity_percent = 100 - (hours / backup_time) * depth_of_discharge - 5 * np.sin(hours * np.pi / backup_time)
            elif battery_type == "Lithium Ion":
                # Lithium Ion batteries maintain voltage better
                capacity_percent = 100 - (hours / backup_time) * depth_of_discharge - 2 * np.sin(0.5 * hours * np.pi / backup_time)
            else:  # AGM or other
                # AGM is between Lead Acid and Lithium
                capacity_percent = 100 - (hours / backup_time) * depth_of_discharge - 3 * np.sin(0.7 * hours * np.pi / backup_time)
            
            # Plot the discharge curve
            plt.plot(hours, capacity_percent, 'b-', linewidth=2)
            
            # Add the DoD threshold line
            plt.axhline(y=100-depth_of_discharge, color='r', linestyle='--', label=f'DoD Threshold ({depth_of_discharge}%)')
            
            # Add labels and title
            plt.xlabel('Time (hours)')
            plt.ylabel('State of Charge (%)')
            plt.title(f'Battery Discharge Curve: {battery_type}')
            plt.grid(True)
            plt.legend()
            
            # Set y-axis limits
            plt.ylim(0, 110)
            
            # Save the figure
            plt.savefig(filepath, dpi=150, bbox_inches='tight')
            plt.close()
            return True
            
        except Exception as e:
            logger.error(f"Error generating battery usage chart: {e}")
            plt.close()  # Close any open figures
            return False
