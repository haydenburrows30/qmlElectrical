from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
import os
from datetime import datetime
import gc
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="three_phase_pdf")

class ThreePhasePdfGenerator:
    """PDF generator for three-phase calculations"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for three-phase calculations
        
        Args:
            data: Dictionary containing three-phase calculation data
            filepath: Path to save the PDF
            
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
            story.append(Paragraph("Three-Phase System Analysis", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # System parameters section
            story.append(Paragraph("System Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create system parameters table
            params_data = [
                ["Parameter", "Value"],
                ["Line Voltage", f"{data.get('line_voltage', 0):.1f} V"],
                ["Phase Voltage", f"{data.get('phase_voltage', 0):.1f} V"],
                ["Line Current", f"{data.get('line_current', 0):.1f} A"],
                ["Phase Current", f"{data.get('phase_current', 0):.1f} A"],
                ["Connection Type", data.get('connection_type', 'Star')],
                ["Power Factor", f"{data.get('power_factor', 0):.2f}"],
                ["Frequency", f"{data.get('frequency', 0):.1f} Hz"]
            ]
            
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
            
            # Power calculations section
            story.append(Paragraph("Power Calculations", heading_style))
            story.append(Spacer(1, 12))
            
            power_data = [
                ["Parameter", "Value"],
                ["Real Power (P)", f"{data.get('real_power', 0):.1f} W"],
                ["Reactive Power (Q)", f"{data.get('reactive_power', 0):.1f} VAR"],
                ["Apparent Power (S)", f"{data.get('apparent_power', 0):.1f} VA"],
                ["Three-Phase Power", f"{data.get('three_phase_power', 0):.1f} W"]
            ]
            
            power_table = Table(power_data)
            power_table.setStyle(TableStyle([
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
            
            story.append(power_table)
            story.append(Spacer(1, 24))
            
            # Impedance and efficiency section
            story.append(Paragraph("Impedance and Efficiency", heading_style))
            story.append(Spacer(1, 12))
            
            impedance_data = [
                ["Parameter", "Value"],
                ["Phase Impedance", f"{data.get('phase_impedance', 0):.2f} Ω"],
                ["Line Impedance", f"{data.get('line_impedance', 0):.2f} Ω"],
                ["Efficiency", f"{data.get('efficiency', 0) * 100:.1f}%"],
                ["Power Loss", f"{data.get('power_loss', 0):.1f} W"]
            ]
            
            impedance_table = Table(impedance_data)
            impedance_table.setStyle(TableStyle([
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
            
            story.append(impedance_table)
            story.append(Spacer(1, 24))
            
            # Add phasor diagram if provided
            if 'phasor_diagram_path' in data and data['phasor_diagram_path'] and os.path.exists(data['phasor_diagram_path']):
                story.append(Paragraph("Phasor Diagram", heading_style))
                story.append(Spacer(1, 12))
                
                # Get the image dimensions to maintain aspect ratio
                from PIL import Image as PILImage
                with PILImage.open(data['phasor_diagram_path']) as img:
                    orig_width, orig_height = img.size
                
                # Calculate the aspect ratio
                aspect_ratio = orig_height / orig_width
                
                # Calculate appropriate image width based on available page width
                available_width = doc.width * 0.95  # Use 95% of available width
                
                # Set the image width and calculate height to maintain aspect ratio
                img = Image(data['phasor_diagram_path'])
                img.drawWidth = available_width
                img.drawHeight = available_width * aspect_ratio
                
                # Add the image
                story.append(img)
                story.append(Spacer(1, 12))
                
                # Add image caption
                story.append(Paragraph(
                    "Figure 1: Three-Phase Phasor Diagram", 
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Reference formulas section
            story.append(Paragraph("Three-Phase Formulas", heading_style))
            story.append(Spacer(1, 12))
            
            # Star connection formulas
            story.append(Paragraph("Star (Wye) Connection:", subheading_style))
            story.append(Paragraph("• Line Voltage = Phase Voltage × √3", normal_style))
            story.append(Paragraph("• Line Current = Phase Current", normal_style))
            story.append(Paragraph("• Three-Phase Power = 3 × Phase Voltage × Phase Current × Power Factor", normal_style))
            story.append(Paragraph("• Three-Phase Power = √3 × Line Voltage × Line Current × Power Factor", normal_style))
            story.append(Spacer(1, 12))
            
            # Delta connection formulas
            story.append(Paragraph("Delta Connection:", subheading_style))
            story.append(Paragraph("• Line Voltage = Phase Voltage", normal_style))
            story.append(Paragraph("• Line Current = Phase Current × √3", normal_style))
            story.append(Paragraph("• Three-Phase Power = 3 × Phase Voltage × Phase Current × Power Factor", normal_style))
            story.append(Paragraph("• Three-Phase Power = √3 × Line Voltage × Line Current × Power Factor", normal_style))
            story.append(Spacer(1, 12))
            
            # Power triangle formulas
            story.append(Paragraph("Power Triangle:", subheading_style))
            story.append(Paragraph("• Real Power (P) = Apparent Power (S) × Power Factor", normal_style))
            story.append(Paragraph("• Reactive Power (Q) = Apparent Power (S) × sin(cos⁻¹(Power Factor))", normal_style))
            story.append(Paragraph("• Apparent Power (S) = √(P² + Q²)", normal_style))
            story.append(Spacer(1, 12))
            
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
