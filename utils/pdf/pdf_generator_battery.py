from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
import os
from datetime import datetime
import gc
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
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
        """Generate a battery visualization chart and save to file
        
        Args:
            data: Dictionary with battery calculation data
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Extract data
            recommended_capacity = data.get('recommended_capacity', 100)
            depth_of_discharge = data.get('depth_of_discharge', 50)
            battery_type = data.get('battery_type', 'Lead Acid')
            
            # Create figure
            plt.figure(figsize=(8, 4))
            
            # Create a visual battery representation
            # Battery outer shape
            battery_height = 2
            battery_width = 6
            battery_x = 1
            battery_y = 1
            
            # Draw battery outline
            plt.gca().add_patch(plt.Rectangle((battery_x, battery_y), battery_width, battery_height, 
                                           fill=False, edgecolor='black', linewidth=2))
            # Draw battery terminal
            terminal_width = 0.3
            terminal_height = 0.5
            plt.gca().add_patch(plt.Rectangle((battery_x + (battery_width - terminal_width)/2, 
                                            battery_y + battery_height), 
                                           terminal_width, terminal_height, 
                                           fill=True, facecolor='black'))
            
            # Calculate usable capacity based on DoD
            usable_width = battery_width * (depth_of_discharge / 100)
            
            # Draw usable capacity
            plt.gca().add_patch(plt.Rectangle((battery_x, battery_y), usable_width, battery_height, 
                                          fill=True, facecolor='green', alpha=0.5))
            
            # Draw unusable capacity
            plt.gca().add_patch(plt.Rectangle((battery_x + usable_width, battery_y), 
                                          battery_width - usable_width, battery_height, 
                                          fill=True, facecolor='red', alpha=0.3))
            
            # Add text annotations
            plt.text(battery_x + battery_width/2, battery_y + battery_height/2, 
                  f"{recommended_capacity:.1f} Ah", 
                  horizontalalignment='center', verticalalignment='center', fontsize=12)
            
            plt.text(battery_x + usable_width/2, battery_y + battery_height/2, 
                  f"Usable\n{depth_of_discharge}%", 
                  horizontalalignment='center', verticalalignment='center', fontsize=10)
            
            plt.text(battery_x + usable_width + (battery_width - usable_width)/2, battery_y + battery_height/2, 
                  f"Reserve\n{100-depth_of_discharge}%", 
                  horizontalalignment='center', verticalalignment='center', fontsize=10)
            
            # Add title and remove axes
            plt.title(f"Battery Capacity: {recommended_capacity:.1f} Ah ({battery_type})")
            plt.axis('off')
            
            # Save the figure
            plt.tight_layout()
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating battery chart: {e}")
            # Make sure to close figures on error
            plt.close('all')
            return False
