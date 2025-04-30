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
logger = configure_logger("qmltest", component="motor_pdf")

class MotorPdfGenerator:
    """Handles PDF generation for motor starting calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for motor starting calculations
        
        Args:
            data: Dictionary containing calculator data
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
            story.append(Paragraph("Motor Starting Analysis Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Motor Parameters section
            story.append(Paragraph("Motor Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create motor parameters table
            motor_data = [
                ["Parameter", "Value"],
                ["Motor Type", data.get('motor_type', 'N/A')],
                ["Motor Power", f"{data.get('motor_power', 0):.1f} kW"],
                ["Voltage", f"{data.get('voltage', 0):.1f} V"],
                ["Efficiency", f"{data.get('efficiency', 0) * 100:.1f}%"],
                ["Power Factor", f"{data.get('power_factor', 0):.2f}"],
                ["Motor Speed", f"{data.get('motor_speed', 0)} RPM"]
            ]
            
            # Create and style the table
            motor_table = Table(motor_data)
            motor_table.setStyle(TableStyle([
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
            
            story.append(motor_table)
            story.append(Spacer(1, 24))
            
            # Starting Method section
            story.append(Paragraph("Starting Method and Results", heading_style))
            story.append(Spacer(1, 12))
            
            # Create starting method table
            starting_data = [
                ["Parameter", "Value"],
                ["Starting Method", data.get('starting_method', 'N/A')],
                ["Full Load Current", f"{data.get('full_load_current', 0):.1f} A"],
                ["Starting Current", f"{data.get('starting_current', 0):.1f} A"],
                ["Current Multiplier", f"{data.get('current_multiplier', 0):.1f}x"],
                ["Nominal Torque", f"{data.get('nominal_torque', 0):.1f} Nm"],
                ["Starting Torque", f"{data.get('starting_torque', 0) * 100:.0f}% FLT"],
                ["Temperature Rise", f"{data.get('temperature_rise', 0):.1f}°C"],
                ["Start Duration", f"{data.get('start_duration', 0):.1f} s"],
                ["Energy Usage", f"{data.get('energy_usage', 0):.3f} kWh"]
            ]
            
            # Create and style the table
            starting_table = Table(starting_data)
            starting_table.setStyle(TableStyle([
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
            
            story.append(starting_table)
            story.append(Spacer(1, 24))
            
            # Recommendations section
            story.append(Paragraph("Recommendations", heading_style))
            story.append(Spacer(1, 12))
            
            recommendations = data.get('recommendations', '').split('\n')
            for recommendation in recommendations:
                if recommendation.strip():
                    story.append(Paragraph("• " + recommendation.strip(), normal_style))
                    story.append(Spacer(1, 6))
            
            story.append(Spacer(1, 12))
            
            # Add starting chart if image path is provided
            if 'chart_image_path' in data and data['chart_image_path'] and os.path.exists(data['chart_image_path']):
                story.append(Paragraph("Motor Starting Visualization", heading_style))
                story.append(Spacer(1, 12))
                
                # Get the image dimensions to maintain aspect ratio
                from PIL import Image as PILImage
                with PILImage.open(data['chart_image_path']) as img:
                    orig_width, orig_height = img.size
                
                # Calculate the aspect ratio
                aspect_ratio = orig_height / orig_width
                
                # Calculate appropriate image width based on available page width
                available_width = doc.width * 0.95  # Use 95% of available width
                
                # Set the image width and calculate height to maintain aspect ratio
                img = Image(data['chart_image_path'])
                img.drawWidth = available_width
                img.drawHeight = available_width * aspect_ratio
                
                # Add the image
                story.append(img)
                story.append(Spacer(1, 12))
                
                # Add image caption with custom caption style
                story.append(Paragraph(
                    "Figure 1: Motor Starting Current and Torque Profiles",
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Additional Information section
            story.append(Paragraph("Additional Information", heading_style))
            story.append(Spacer(1, 12))
            
            # Create additional info table
            additional_data = [
                ["Parameter", "Value"],
                ["Recommended Cable Size", data.get('cable_size', 'N/A')],
                ["Duty Cycle", data.get('duty_cycle', 'N/A')],
                ["Ambient Temperature", f"{data.get('ambient_temperature', 0):.1f}°C"],
                ["Starting Duration", f"{data.get('starting_duration', 0):.1f} s"]
            ]
            
            # Create and style the table
            additional_table = Table(additional_data)
            additional_table.setStyle(TableStyle([
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
            
            story.append(additional_table)
            story.append(Spacer(1, 24))
            
            # Starting Method Comparison section if comparison data is provided
            if 'comparison_data' in data and data['comparison_data']:
                story.append(Paragraph("Starting Method Comparison", heading_style))
                story.append(Spacer(1, 12))
                
                # Create header row for comparison table
                comparison_header = ["Parameter"]
                for method in data['comparison_data']:
                    comparison_header.append(method['method'])
                
                # Create comparison table data
                comparison_data = [comparison_header]
                
                # Add starting current row
                current_row = ["Starting Current (A)"]
                for method in data['comparison_data']:
                    current_row.append(f"{method.get('starting_current', 0):.1f}")
                comparison_data.append(current_row)
                
                # Add current multiplier row
                multiplier_row = ["Current Multiplier"]
                for method in data['comparison_data']:
                    multiplier_row.append(f"{method.get('current_multiplier', 0):.1f}x")
                comparison_data.append(multiplier_row)
                
                # Add starting torque row
                torque_row = ["Starting Torque (%)"]
                for method in data['comparison_data']:
                    torque_row.append(f"{method.get('starting_torque', 0) * 100:.0f}%")
                comparison_data.append(torque_row)
                
                # Add energy usage row
                energy_row = ["Energy Usage (kWh)"]
                for method in data['comparison_data']:
                    energy_row.append(f"{method.get('energy_usage', 0):.3f}")
                comparison_data.append(energy_row)
                
                # Create and style the comparison table
                comparison_table = Table(comparison_data)
                
                # Calculate column count for styling
                col_count = len(comparison_header)
                
                comparison_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (col_count-1, 0), colors.lightblue),
                    ('TEXTCOLOR', (0, 0), (col_count-1, 0), colors.whitesmoke),
                    ('ALIGN', (0, 0), (col_count-1, 0), 'CENTER'),
                    ('FONTNAME', (0, 0), (col_count-1, 0), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (col_count-1, 0), 12),
                    ('BOTTOMPADDING', (0, 0), (col_count-1, 0), 6),
                    ('BACKGROUND', (0, 1), (0, -1), colors.lightgrey),
                    ('BACKGROUND', (1, 1), (col_count-1, -1), colors.white),
                    ('GRID', (0, 0), (col_count-1, -1), 1, colors.black),
                    ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                    ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                    ('ALIGN', (1, 0), (col_count-1, -1), 'CENTER')
                ]))
                
                story.append(comparison_table)
                story.append(Spacer(1, 24))
            
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
    
    def generate_starting_chart(self, data, filepath):
        """Generate a motor starting chart and save to file
        
        Args:
            data: Dictionary with motor data
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create figure with two subplots (current and torque)
            fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8))
            
            # Prepare data for the chart
            t = np.linspace(0, data.get('start_duration', 5), 100)  # Time points
            
            # Current profile parameters
            I_fl = data.get('full_load_current', 1)
            I_start = data.get('starting_current', 6 * I_fl)
            
            # Calculate current profile based on starting method
            method = data.get('starting_method', 'DOL')
            
            if method == 'DOL':
                # Direct online - immediate high current that slowly decreases
                current = I_start * np.exp(-0.5 * t) + I_fl * (1 - np.exp(-0.5 * t))
            elif method == 'Star-Delta':
                # Star-Delta - lower initial current, then a jump when switching to delta
                switch_time = min(2.0, data.get('start_duration', 5) / 2)
                current = np.zeros_like(t)
                for i, time in enumerate(t):
                    if time < switch_time:
                        # During star connection (1/3 of DOL current)
                        current[i] = (I_start / 3) * np.exp(-0.7 * time) + I_fl * (1 - np.exp(-0.7 * time))
                    else:
                        # Spike when switching to delta, then decrease
                        delta_time = time - switch_time
                        current[i] = I_start * 0.8 * np.exp(-1.5 * delta_time) + I_fl * (1 - np.exp(-1.5 * delta_time))
            elif method == 'Soft Starter':
                # Soft starter - gradual ramp up
                ramp_time = min(3.0, data.get('start_duration', 5) * 0.8)
                current = np.zeros_like(t)
                for i, time in enumerate(t):
                    if time < ramp_time:
                        # Ramp up period
                        ramp_factor = time / ramp_time
                        current[i] = I_fl + ramp_factor * (I_start/2 - I_fl)
                    else:
                        # Final stabilization
                        delta_time = time - ramp_time
                        current[i] = (I_start/2) * np.exp(-2 * delta_time) + I_fl * (1 - np.exp(-2 * delta_time))
            else:  # VFD
                # VFD - very controlled ramp
                current = np.zeros_like(t)
                for i, time in enumerate(t):
                    if time < data.get('start_duration', 5) * 0.9:
                        # Controlled ramp up
                        ramp_factor = min(1.0, time / (data.get('start_duration', 5) * 0.5))
                        current[i] = I_fl * (1 + ramp_factor * 0.2)
                    else:
                        # Final stabilization
                        current[i] = I_fl * 1.2
            
            # Plot current profile
            ax1.plot(t, current, 'r-', linewidth=2)
            ax1.axhline(y=I_fl, color='blue', linestyle='--', label='Full Load Current')
            ax1.set_title(f'Starting Current Profile - {method}')
            ax1.set_xlabel('Time (s)')
            ax1.set_ylabel('Current (A)')
            ax1.grid(True)
            ax1.legend()
            
            # Calculate torque profile based on method
            torque_factor = data.get('starting_torque', 1.0)
            nominal_torque = data.get('nominal_torque', 100)
            
            if method == 'DOL':
                # Direct torque application
                torque = nominal_torque * (torque_factor + (1 - torque_factor) * (1 - np.exp(-0.7 * t)))
            elif method == 'Star-Delta':
                # Reduced initial torque, then jump
                switch_time = min(2.0, data.get('start_duration', 5) / 2)
                torque = np.zeros_like(t)
                for i, time in enumerate(t):
                    if time < switch_time:
                        # During star connection
                        torque[i] = nominal_torque * torque_factor * (1 - np.exp(-0.5 * time))
                    else:
                        # After switching to delta
                        delta_time = time - switch_time
                        torque[i] = nominal_torque * (0.8 + 0.2 * (1 - np.exp(-1.0 * delta_time)))
            elif method == 'Soft Starter':
                # Gradual torque increase
                ramp_time = min(3.0, data.get('start_duration', 5) * 0.8)
                torque = np.zeros_like(t)
                for i, time in enumerate(t):
                    if time < ramp_time:
                        # Ramp up period
                        ramp_factor = time / ramp_time
                        torque[i] = nominal_torque * (torque_factor * ramp_factor + 0.1)
                    else:
                        # Final stabilization
                        delta_time = time - ramp_time
                        torque[i] = nominal_torque * (torque_factor + (1 - torque_factor) * (1 - np.exp(-1.5 * delta_time)))
            else:  # VFD
                # Very controlled torque ramp
                torque = np.zeros_like(t)
                for i, time in enumerate(t):
                    ramp_factor = min(1.0, time / (data.get('start_duration', 5) * 0.6))
                    torque[i] = nominal_torque * ramp_factor
            
            # Plot torque profile
            ax2.plot(t, torque, 'g-', linewidth=2)
            ax2.axhline(y=nominal_torque, color='blue', linestyle='--', label='Nominal Torque')
            ax2.set_title('Torque Profile')
            ax2.set_xlabel('Time (s)')
            ax2.set_ylabel('Torque (Nm)')
            ax2.grid(True)
            ax2.legend()
            
            # Add summary info
            plt.figtext(0.5, 0.01, 
                       f"Motor: {data.get('motor_type', 'Induction')}, {data.get('motor_power', 0):.1f} kW | " +
                       f"Method: {method} | Current: {I_start:.1f}A ({data.get('current_multiplier', 0):.1f}x FLC)", 
                       ha='center', fontsize=10, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.3))
            
            # Adjust layout and save
            plt.tight_layout(rect=[0, 0.03, 1, 0.97])
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating motor chart: {e}")
            # Make sure to close figures on error
            plt.close('all')
            return False
