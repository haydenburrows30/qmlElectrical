from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
import os
from datetime import datetime
import gc
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="earthing_pdf")

class EarthingPdfGenerator:
    """Handles PDF generation for earthing calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for earthing system calculations
        
        Args:
            data: Dictionary containing earthing system data
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
            story.append(Paragraph("Earthing System Analysis Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Grid Parameters section
            story.append(Paragraph("Grid Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create parameters table
            grid_data = [
                ["Parameter", "Value"],
                ["Soil Resistivity", f"{data.get('soil_resistivity', 0):.1f} Ω⋅m"],
                ["Grid Depth", f"{data.get('grid_depth', 0):.2f} m"],
                ["Grid Length", f"{data.get('grid_length', 0):.1f} m"],
                ["Grid Width", f"{data.get('grid_width', 0):.1f} m"],
                ["Ground Area", f"{data.get('grid_area', 0):.1f} m²"]
            ]
            
            # Create and style the table
            grid_table = Table(grid_data)
            grid_table.setStyle(TableStyle([
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
            
            story.append(grid_table)
            story.append(Spacer(1, 24))
            
            # Ground Rod Parameters
            story.append(Paragraph("Ground Rod Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create rod parameters table
            rod_data = [
                ["Parameter", "Value"],
                ["Rod Length", f"{data.get('rod_length', 0):.1f} m"],
                ["Number of Rods", f"{data.get('rod_count', 0)}"],
                ["Total Rod Length", f"{data.get('rod_length', 0) * data.get('rod_count', 0):.1f} m"]
            ]
            
            # Create and style the table
            rod_table = Table(rod_data)
            rod_table.setStyle(TableStyle([
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
            
            story.append(rod_table)
            story.append(Spacer(1, 24))
            
            # Fault Parameters
            story.append(Paragraph("Fault Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create fault parameters table
            fault_data = [
                ["Parameter", "Value"],
                ["Fault Current", f"{data.get('fault_current', 0):.1f} A"],
                ["Fault Duration", f"{data.get('fault_duration', 0):.2f} s"]
            ]
            
            # Create and style the table
            fault_table = Table(fault_data)
            fault_table.setStyle(TableStyle([
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
            
            story.append(fault_table)
            story.append(Spacer(1, 24))
            
            # Calculation Results
            story.append(Paragraph("Calculation Results", heading_style))
            story.append(Spacer(1, 12))
            
            # Calculate safety thresholds
            soil_resistivity = data.get('soil_resistivity', 100)
            touch_threshold = 50 * (1 + 0.116 * soil_resistivity/1000)
            step_threshold = 50 * (1 + 0.53 * soil_resistivity/1000)
            touch_voltage = data.get('touch_voltage', 0)
            step_voltage = data.get('step_voltage', 0)
            
            # Create results table with safety status
            results_data = [
                ["Parameter", "Value", "Status"],
                ["Grid Resistance", f"{data.get('grid_resistance', 0):.3f} Ω", ""],
                ["Ground Potential Rise", f"{data.get('voltage_rise', 0):.1f} V", ""],
                ["Touch Voltage", f"{touch_voltage:.1f} V", 
                 "✓ Safe" if touch_voltage <= touch_threshold else "✗ Unsafe"],
                ["Step Voltage", f"{step_voltage:.1f} V", 
                 "✓ Safe" if step_voltage <= step_threshold else "✗ Unsafe"],
                ["Min. Conductor Size", f"{data.get('conductor_size', 0):.1f} mm²", ""]
            ]
            
            # Create and style the table with colored status column
            results_table = Table(results_data)
            results_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (2, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (2, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (2, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (2, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (2, 0), 12),
                ('BOTTOMPADDING', (0, 0), (2, 0), 6),
                ('BACKGROUND', (0, 1), (2, -1), colors.white),
                ('GRID', (0, 0), (2, -1), 1, colors.black),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
                ('ALIGN', (2, 0), (2, -1), 'CENTER'),
                ('TEXTCOLOR', (2, 3), (2, 3), 
                 colors.green if touch_voltage <= touch_threshold else colors.red),
                ('TEXTCOLOR', (2, 4), (2, 4), 
                 colors.green if step_voltage <= step_threshold else colors.red),
            ]))
            
            story.append(results_table)
            story.append(Spacer(1, 24))
            
            # Add safety threshold information
            story.append(Paragraph("Safety Thresholds", subheading_style))
            story.append(Spacer(1, 6))
            story.append(Paragraph(f"Touch Voltage Threshold: {touch_threshold:.1f} V", normal_style))
            story.append(Paragraph(f"Step Voltage Threshold: {step_threshold:.1f} V", normal_style))
            story.append(Spacer(1, 12))
            
            # Add visualization if provided
            if 'diagram_image_path' in data and data['diagram_image_path'] and os.path.exists(data['diagram_image_path']):
                story.append(Paragraph("Earthing System Visualization", heading_style))
                story.append(Spacer(1, 12))
                
                # Get the image dimensions to maintain aspect ratio
                from PIL import Image as PILImage
                with PILImage.open(data['diagram_image_path']) as img:
                    orig_width, orig_height = img.size
                
                # Calculate the aspect ratio
                aspect_ratio = orig_height / orig_width
                
                # Calculate appropriate image width based on available page width
                available_width = doc.width * 0.95  # Use 95% of available width
                
                # Set the image width and calculate height to maintain aspect ratio
                img = Image(data['diagram_image_path'])
                img.drawWidth = available_width
                img.drawHeight = available_width * aspect_ratio
                
                # Add the image
                story.append(img)
                story.append(Spacer(1, 12))
                
                # Add image caption
                story.append(Paragraph(
                    "Figure 1: Earthing System Grid and Ground Rod Layout", 
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # IEEE 80 Standard Information section
            story.append(Paragraph("IEEE 80 Standard Information", heading_style))
            story.append(Spacer(1, 12))
            
            story.append(Paragraph("Grid Resistance Calculation", subheading_style))
            story.append(Paragraph(
                "The grid resistance is calculated using the IEEE 80 approach which accounts for "
                "both the grid conductors and the ground rods. For combined grid and rod systems, "
                "the mutual coupling between the grid and rods is considered.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            story.append(Paragraph("Touch and Step Voltage", subheading_style))
            story.append(Paragraph(
                "The touch voltage is the potential difference between a point where a person is standing "
                "and a grounded metallic structure. The step voltage is the potential difference between two "
                "points on the earth's surface separated by a distance equal to a human step. "
                "IEEE 80 provides safety thresholds based on soil resistivity.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            story.append(Paragraph("Conductor Sizing", subheading_style))
            story.append(Paragraph(
                "Conductor sizing is based on IEEE 80 thermal equations which consider the fault current "
                "magnitude and duration. The calculated size ensures the conductor will not melt "
                "or otherwise be damaged during a fault.",
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
            
    def generate_diagram(self, data, filepath):
        """Generate a diagram of the earthing system
        
        Args:
            data: Dictionary with earthing system data
            filepath: Path to save the diagram image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create figure
            plt.figure(figsize=(10, 8))
            
            # Get grid dimensions
            grid_length = data.get('grid_length', 20)
            grid_width = data.get('grid_width', 20)
            rod_count = data.get('rod_count', 4)
            rod_length = data.get('rod_length', 3)
            
            # Create axis
            ax = plt.subplot(111, aspect='equal')
            
            # Draw grid outline
            grid = plt.Rectangle((0, 0), grid_length, grid_width, fill=False, color='blue', linewidth=2)
            ax.add_patch(grid)
            
            # Draw internal grid lines (simplified)
            # Add horizontal lines
            num_h_lines = min(5, int(grid_width / 4))
            for i in range(1, num_h_lines):
                y = i * grid_width / num_h_lines
                plt.plot([0, grid_length], [y, y], 'b--', alpha=0.7)
            
            # Add vertical lines
            num_v_lines = min(5, int(grid_length / 4))
            for i in range(1, num_v_lines):
                x = i * grid_length / num_v_lines
                plt.plot([x, x], [0, grid_width], 'b--', alpha=0.7)
            
            # Place ground rods
            if rod_count > 0:
                # Place rods at corners and evenly around perimeter
                rod_positions = []
                
                # Add corner rods first
                corners = [(0, 0), (grid_length, 0), (grid_length, grid_width), (0, grid_width)]
                for i in range(min(rod_count, 4)):
                    rod_positions.append(corners[i])
                
                # If more rods, distribute them evenly around perimeter
                if rod_count > 4:
                    perimeter_points = []
                    
                    # Bottom edge
                    for i in range(1, int((rod_count - 4) / 4) + 1):
                        x = i * grid_length / (int((rod_count - 4) / 4) + 1)
                        perimeter_points.append((x, 0))
                    
                    # Right edge
                    for i in range(1, int((rod_count - 4) / 4) + 1):
                        y = i * grid_width / (int((rod_count - 4) / 4) + 1)
                        perimeter_points.append((grid_length, y))
                    
                    # Top edge
                    for i in range(1, int((rod_count - 4) / 4) + 1):
                        x = grid_length - i * grid_length / (int((rod_count - 4) / 4) + 1)
                        perimeter_points.append((x, grid_width))
                    
                    # Left edge
                    for i in range(1, int((rod_count - 4) / 4) + 1):
                        y = grid_width - i * grid_width / (int((rod_count - 4) / 4) + 1)
                        perimeter_points.append((0, y))
                    
                    # Add points to rod positions
                    rod_positions.extend(perimeter_points[:rod_count-4])
                
                # Draw the rods
                for x, y in rod_positions:
                    # Rod circle
                    rod_circle = plt.Circle((x, y), 0.3, color='red')
                    ax.add_patch(rod_circle)
                    
                    # Rod depth line
                    if y == 0:
                        plt.plot([x, x], [y, -rod_length], 'r-', linewidth=2)
                    elif y == grid_width:
                        plt.plot([x, x], [y, y+rod_length], 'r-', linewidth=2)
                    elif x == 0:
                        plt.plot([x, -rod_length], [y, y], 'r-', linewidth=2)
                    elif x == grid_length:
                        plt.plot([x, x+rod_length], [y, y], 'r-', linewidth=2)
                    else:
                        plt.plot([x, x], [y, y-rod_length], 'r-', linewidth=2)
            
            # Set plot limits with padding
            padding = max(grid_length, grid_width) * 0.2
            plt.xlim(-padding, grid_length + padding)
            plt.ylim(-padding, grid_width + padding)
            
            # Add labels
            plt.title('Earthing System Layout')
            plt.xlabel('Length (m)')
            plt.ylabel('Width (m)')
            
            # Add legend
            from matplotlib.lines import Line2D
            legend_elements = [
                Line2D([0], [0], color='blue', linewidth=2, label='Grid Conductor'),
                Line2D([0], [0], marker='o', color='w', markerfacecolor='red', markersize=10, label='Ground Rod')
            ]
            ax.legend(handles=legend_elements, loc='upper right')
            
            # Add system data
            system_info = (
                f"Grid: {grid_length}m × {grid_width}m | "
                f"Rods: {rod_count} × {rod_length}m | "
                f"Grid Resistance: {data.get('grid_resistance', 0):.3f} Ω"
            )
            plt.figtext(0.5, 0.01, system_info, ha="center", fontsize=9, 
                      bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
            
            # Save the figure
            plt.tight_layout(rect=[0, 0.03, 1, 0.97])
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating earthing diagram: {e}")
            plt.close('all')  # Make sure to close figures on error
            return False
