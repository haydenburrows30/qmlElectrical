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
logger = configure_logger("qmltest", component="machine_pdf")

class MachinePdfGenerator:
    """Handles PDF generation for electric machine calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for electric machine calculations
        
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
            story.append(Paragraph("Electric Machine Analysis Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Machine parameters section
            story.append(Paragraph("Machine Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create machine parameters table
            machine_data = [
                ["Parameter", "Value"],
                ["Machine Type", data.get('machine_type', 'N/A')],
                ["Rated Voltage", f"{data.get('rated_voltage', 0):.1f} V"],
                ["Rated Current", f"{data.get('rated_current', 0):.2f} A"],
                ["Rated Power", f"{data.get('rated_power', 0):.2f} kW"],
                ["Power Factor", f"{data.get('power_factor', 0):.2f}"],
                ["Efficiency", f"{data.get('efficiency', 0) * 100:.1f}%"],
                ["Number of Poles", f"{data.get('poles', 0)}"],
                ["Frequency", f"{data.get('frequency', 0):.1f} Hz"]
            ]
            
            # Add motor-specific parameters
            if "Motor" in data.get('machine_type', ''):
                machine_data.append(["Rotational Speed", f"{data.get('rotational_speed', 0):.1f} RPM"])
                
                # Add slip for induction motors
                if "Induction" in data.get('machine_type', ''):
                    machine_data.append(["Slip", f"{data.get('slip', 0) * 100:.2f}%"])
            
            # Create and style the table
            machine_table = Table(machine_data)
            machine_table.setStyle(TableStyle([
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
            
            story.append(machine_table)
            story.append(Spacer(1, 24))
            
            # Thermal parameters section
            story.append(Paragraph("Thermal Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create thermal parameters table
            thermal_data = [
                ["Parameter", "Value"],
                ["Temperature Class", data.get('temperature_class', 'N/A')],
                ["Cooling Method", data.get('cooling_method', 'N/A')],
                ["Temperature Rise", f"{data.get('temperature_rise', 0):.1f} °C"],
                ["Ambient Temperature", f"{data.get('ambient_temp', 40):.1f} °C"],
                ["Maximum Allowed Temperature", f"{data.get('max_allowed_temp', 0):.1f} °C"]
            ]
            
            # Create and style the table
            thermal_table = Table(thermal_data)
            thermal_table.setStyle(TableStyle([
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
            
            story.append(thermal_table)
            story.append(Spacer(1, 24))
            
            # Mechanical parameters section
            story.append(Paragraph("Mechanical Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create mechanical parameters table
            mechanical_data = [
                ["Parameter", "Value"],
                ["Torque", f"{data.get('torque', 0):.2f} N·m"],
                ["Starting Torque", f"{data.get('starting_torque', 0):.2f} N·m"],
                ["Breakdown Torque", f"{data.get('breakdown_torque', 0):.2f} N·m"],
                ["Losses", f"{data.get('losses', 0):.2f} kW"]
            ]
            
            # Create and style the table
            mechanical_table = Table(mechanical_data)
            mechanical_table.setStyle(TableStyle([
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
            
            story.append(mechanical_table)
            story.append(Spacer(1, 24))
            
            # Add torque-speed curve if image path is provided
            chart_image_path = data.get('chart_image_path', '')
            if chart_image_path and os.path.exists(chart_image_path):
                try:
                    story.append(Paragraph("Torque-Speed Curve", heading_style))
                    story.append(Spacer(1, 12))
                    
                    # Get the image dimensions to maintain aspect ratio
                    from PIL import Image as PILImage
                    with PILImage.open(chart_image_path) as img:
                        orig_width, orig_height = img.size
                    
                    # Calculate the aspect ratio
                    aspect_ratio = orig_height / orig_width
                    
                    # Calculate appropriate image width based on available page width
                    available_width = doc.width * 0.95  # Use 95% of available width
                    
                    # Set the image width and calculate height to maintain aspect ratio
                    img = Image(chart_image_path)
                    img.drawWidth = available_width
                    img.drawHeight = available_width * aspect_ratio
                    
                    # Add the image
                    story.append(img)
                    story.append(Spacer(1, 12))
                    
                    # Add image caption with custom caption style
                    story.append(Paragraph(
                        f"Figure 1: Torque-Speed Characteristics for {data.get('machine_type', 'Electric Machine')}",
                        caption_style
                    ))
                    story.append(Spacer(1, 24))
                except Exception as e:
                    logger.error(f"Error adding chart image to PDF: {e}")
            
            # Add machine theory section based on machine type
            story.append(Paragraph("Machine Theory", heading_style))
            story.append(Spacer(1, 12))
            
            machine_type = data.get('machine_type', '')
            
            if "Induction Motor" in machine_type:
                story.append(Paragraph("Induction Motor Theory", subheading_style))
                story.append(Paragraph(
                    "Induction motors operate based on electromagnetic induction, where the stator's rotating magnetic field "
                    "induces current in the rotor, creating its own magnetic field that interacts with the stator field to produce torque. "
                    "The rotor always rotates at a slightly slower speed than the synchronous speed, with the difference determined by the slip. "
                    "The slip increases with load, causing torque to increase proportionally within the motor's stable operating region.",
                    normal_style
                ))
                story.append(Spacer(1, 12))
                
                story.append(Paragraph("Slip Calculation", subheading_style))
                story.append(Paragraph(
                    "Slip = (Synchronous Speed - Rotor Speed) / Synchronous Speed\n"
                    "where Synchronous Speed = 120 × Frequency / Number of Poles",
                    normal_style
                ))
                
            elif "Synchronous" in machine_type:
                story.append(Paragraph("Synchronous Machine Theory", subheading_style))
                story.append(Paragraph(
                    "Synchronous machines operate at a constant speed synchronized with the supply frequency. "
                    "The rotor field is produced by a DC excitation system, which locks with the rotating stator field. "
                    "Synchronous motors have precise speed control and can operate at leading or lagging power factors "
                    "by adjusting the excitation current, making them valuable for power factor correction.",
                    normal_style
                ))
                story.append(Spacer(1, 12))
                
                story.append(Paragraph("Synchronous Speed", subheading_style))
                story.append(Paragraph(
                    "Synchronous Speed (RPM) = 120 × Frequency / Number of Poles",
                    normal_style
                ))
                
            elif "DC" in machine_type:
                story.append(Paragraph("DC Machine Theory", subheading_style))
                story.append(Paragraph(
                    "DC machines use commutation to convert between AC and DC. In DC motors, current-carrying conductors in a magnetic field "
                    "experience a force that produces torque. The commutator ensures that the current direction "
                    "in the armature changes as the motor rotates, maintaining consistent torque direction. "
                    "DC machines offer excellent speed control and high starting torque.",
                    normal_style
                ))
                story.append(Spacer(1, 12))
                
                story.append(Paragraph("DC Motor Equation", subheading_style))
                story.append(Paragraph(
                    "V = E + Ia × Ra\n"
                    "where V is terminal voltage, E is back EMF, Ia is armature current, and Ra is armature resistance",
                    normal_style
                ))
            
            # Add general machine equations
            story.append(Spacer(1, 12))
            story.append(Paragraph("General Machine Equations", subheading_style))
            story.append(Paragraph(
                "Power (P) = Torque (T) × Angular Velocity (ω)\n"
                "Torque (N·m) = 9550 × Power (kW) / Speed (RPM)\n"
                "Efficiency = Output Power / Input Power",
                normal_style
            ))
            
            # Add thermal derating section
            story.append(Spacer(1, 12))
            story.append(Paragraph("Thermal Considerations", subheading_style))
            story.append(Paragraph(
                f"The {data.get('temperature_class', 'F')} insulation class has a maximum operating temperature of "
                f"{data.get('max_allowed_temp', 155)}°C. With an ambient temperature of {data.get('ambient_temp', 40)}°C, "
                f"the maximum allowable temperature rise is {data.get('max_allowed_temp', 155) - data.get('ambient_temp', 40)}°C. "
                f"The calculated temperature rise is {data.get('temperature_rise', 0):.1f}°C.",
                normal_style
            ))
            
            # Add derating warning if applicable
            if data.get('temperature_rise', 0) > (data.get('max_allowed_temp', 155) - data.get('ambient_temp', 40)):
                story.append(Spacer(1, 12))
                story.append(Paragraph(
                    "WARNING: The calculated temperature rise exceeds the maximum allowable rise for the selected insulation class. "
                    "A derating factor has been applied to the efficiency to compensate for the thermal limitations.",
                    ParagraphStyle(
                        'Warning',
                        parent=normal_style,
                        textColor=colors.red,
                        fontName='Helvetica-Bold'
                    )
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
            
    def generate_torque_speed_curve(self, data, filepath):
        """Generate a torque-speed curve chart and save to file
        
        Args:
            data: Dictionary with machine data
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Extract data
            machine_type = data.get('machine_type', '')
            rated_speed = data.get('rotational_speed', 1500)
            rated_torque = data.get('torque', 50)
            starting_torque = data.get('starting_torque', rated_torque * 1.5)
            breakdown_torque = data.get('breakdown_torque', rated_torque * 2.5)
            
            # Create figure
            plt.figure(figsize=(8, 6))
            
            # Generate points for torque-speed curve based on machine type
            if "Induction Motor" in machine_type:
                # For induction motors, create a more detailed curve
                # Speed range from 0 to 110% of synchronous speed
                sync_speed = rated_speed / (1 - data.get('slip', 0.033))
                speeds = np.linspace(0, 1.1 * sync_speed, 100)
                torques = []
                
                for s in speeds:
                    if s < 1:  # Just to prevent division by zero
                        # Skip zero to avoid division by zero
                        torques.append(0)
                        continue
                        
                    # Calculate slip at this speed
                    slip = (sync_speed - s) / sync_speed
                    
                    if slip <= 0:
                        # Generating mode (negative torque)
                        torques.append(-rated_torque * 0.5)
                    elif slip >= 1:
                        # Locked rotor (maximum starting torque)
                        torques.append(starting_torque)
                    else:
                        # Normal operation - approximate torque-slip curve
                        # Simplified model: T ≈ T_max / (slip/slip_max + slip_max/slip)
                        slip_max = 0.2  # Slip at maximum torque (approximate)
                        torque = breakdown_torque / ((slip/slip_max) + (slip_max/slip))
                        torques.append(min(torque, breakdown_torque))  # Cap at breakdown torque
                
                # Plot the curve
                plt.plot(speeds, torques, 'b-', linewidth=2)
                
                # Add key points
                plt.plot(0, starting_torque, 'ro', markersize=8)  # Starting point
                plt.plot(rated_speed, rated_torque, 'go', markersize=8)  # Rated operating point
                
                # Find max torque point
                max_idx = torques.index(max(torques))
                plt.plot(speeds[max_idx], torques[max_idx], 'mo', markersize=8)  # Breakdown torque point
                
                # Add annotations
                plt.annotate(f"Starting: {starting_torque:.1f} N·m", 
                          xy=(0, starting_torque),
                          xytext=(30, starting_torque + 10),
                          arrowprops=dict(facecolor='red', shrink=0.05))
                
                plt.annotate(f"Rated: {rated_torque:.1f} N·m", 
                          xy=(rated_speed, rated_torque),
                          xytext=(rated_speed - 150, rated_torque + 15),
                          arrowprops=dict(facecolor='green', shrink=0.05))
                
                plt.annotate(f"Breakdown: {breakdown_torque:.1f} N·m", 
                          xy=(speeds[max_idx], torques[max_idx]),
                          xytext=(speeds[max_idx] - 200, torques[max_idx] + 15),
                          arrowprops=dict(facecolor='magenta', shrink=0.05))
                
                # Add synchronous speed line
                plt.axvline(x=sync_speed, color='black', linestyle='--', alpha=0.5)
                plt.annotate(f"Sync: {sync_speed:.1f} RPM", 
                          xy=(sync_speed, 0),
                          xytext=(sync_speed, min(torques) * 0.8),
                          rotation=90,
                          ha='right')
                
            elif "Synchronous" in machine_type:
                # For synchronous machines, torque is more constant
                speeds = np.linspace(0, 1.5 * rated_speed, 100)
                torques = []
                
                sync_speed = rated_speed  # Synchronous machines run at sync speed
                
                for s in speeds:
                    if s < 1:  # Prevent division by zero
                        torques.append(0)
                        continue
                        
                    if abs(s - sync_speed) < 0.01 * sync_speed:
                        # Normal operation at sync speed
                        torques.append(rated_torque)
                    elif s < sync_speed:
                        # Accelerating to sync
                        factor = s / sync_speed
                        torques.append(starting_torque * (1 - factor) + rated_torque * factor)
                    else:
                        # Above sync speed (generating)
                        factor = min((s - sync_speed) / (0.5 * sync_speed), 1)
                        torques.append(rated_torque * (1 - factor * 2))
                
                # Plot the curve
                plt.plot(speeds, torques, 'b-', linewidth=2)
                
                # Add key points
                plt.plot(0, starting_torque, 'ro', markersize=8)  # Starting point
                plt.plot(sync_speed, rated_torque, 'go', markersize=8)  # Rated operating point
                
                # Add annotations
                plt.annotate(f"Starting Torque: {starting_torque:.1f} N·m", 
                          xy=(0, starting_torque),
                          xytext=(30, starting_torque + 10),
                          arrowprops=dict(facecolor='red', shrink=0.05))
                
                plt.annotate(f"Rated Torque: {rated_torque:.1f} N·m", 
                          xy=(sync_speed, rated_torque),
                          xytext=(sync_speed - 150, rated_torque + 15),
                          arrowprops=dict(facecolor='green', shrink=0.05))
                
                # Add synchronous speed line
                plt.axvline(x=sync_speed, color='black', linestyle='--', alpha=0.5)
                plt.annotate(f"Sync: {sync_speed:.1f} RPM", 
                          xy=(sync_speed, 0),
                          xytext=(sync_speed, min(0, min(torques)) * 0.8),
                          rotation=90,
                          ha='right')
                
            elif "DC" in machine_type:
                # DC machines have a more linear torque-speed characteristic
                max_speed = rated_speed * 1.5
                speeds = np.linspace(0, max_speed, 100)
                torques = []
                
                for s in speeds:
                    if s <= 0:
                        torques.append(starting_torque)
                    elif s <= rated_speed:
                        # Linear decrease from starting to rated torque at rated speed
                        ratio = s / rated_speed
                        torques.append(starting_torque * (1 - ratio) + rated_torque * ratio)
                    else:
                        # Above rated speed - torque drops due to field weakening
                        ratio = (s - rated_speed) / (max_speed - rated_speed)
                        torques.append(rated_torque * (1 - ratio * 0.8))
                
                # Plot the curve
                plt.plot(speeds, torques, 'b-', linewidth=2)
                
                # Add key points
                plt.plot(0, starting_torque, 'ro', markersize=8)  # Starting point
                plt.plot(rated_speed, rated_torque, 'go', markersize=8)  # Rated operating point
                
                # Add annotations
                plt.annotate(f"Starting: {starting_torque:.1f} N·m", 
                          xy=(0, starting_torque),
                          xytext=(30, starting_torque + 10),
                          arrowprops=dict(facecolor='red', shrink=0.05))
                
                plt.annotate(f"Rated: {rated_torque:.1f} N·m", 
                          xy=(rated_speed, rated_torque),
                          xytext=(rated_speed - 150, rated_torque + 15),
                          arrowprops=dict(facecolor='green', shrink=0.05))
                
                # Add rated speed line
                plt.axvline(x=rated_speed, color='black', linestyle='--', alpha=0.5)
                plt.annotate(f"Rated: {rated_speed:.1f} RPM", 
                          xy=(rated_speed, 0),
                          xytext=(rated_speed, min(torques) * 0.8),
                          rotation=90,
                          ha='right')
            
            # Set labels and title
            plt.title(f'Torque-Speed Curve for {machine_type}')
            plt.xlabel('Speed (RPM)')
            plt.ylabel('Torque (N·m)')
            plt.grid(True)
            
            # Add machine info
            plt.figtext(0.5, 0.01, 
                      f"Rated Power: {data.get('rated_power', 0):.2f} kW | Efficiency: {data.get('efficiency', 0)*100:.1f}% | " + 
                      f"Rated Speed: {rated_speed:.1f} RPM", 
                      ha="center", fontsize=9, bbox={"facecolor":"lightblue", "alpha":0.2, "pad":5})
            
            # Save the figure
            plt.tight_layout(rect=[0, 0.03, 1, 0.97])
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating torque-speed curve: {e}")
            # Make sure to close figures on error
            plt.close('all')
            return False
