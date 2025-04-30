import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from datetime import datetime
import gc

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="vr32cl7_pdf")

class VR32CL7PdfGenerator:
    """Handles PDF generation for VR32CL7 Voltage Regulator calculator"""
    
    def generate_report(self, data, filepath):
        """Generate PDF report for VR32CL7 calculations
        
        Args:
            data: Dictionary with calculation data
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
            story.append(Paragraph("VR32/CL7 Voltage Regulator Analysis", title_style))
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
                ["Generation Capacity", f"{data['generation_capacity']:.1f} kW"],
                ["Cable Length", f"{data['cable_length']:.1f} km"],
                ["Cable Resistance (R)", f"{data['cable_r']:.3f} Ω/km"],
                ["Cable Reactance (X)", f"{data['cable_x']:.3f} Ω/km"],
                ["Load Distance", f"{data['load_distance']:.1f} km"],
                ["Power Factor", f"{data['power_factor']:.2f}"]
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
                ["Total Resistance (R)", f"{data['resistance']:.3f} Ω"],
                ["Total Reactance (X)", f"{data['reactance']:.3f} Ω"],
                ["Impedance Magnitude (Z)", f"{data['impedance']:.3f} Ω"],
                ["Impedance Angle (θ)", f"{data['impedance_angle']:.2f}°"]
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
            
            # Add impedance triangle chart if available
            if 'chart_image_path' in data and data['chart_image_path'] and os.path.exists(data['chart_image_path']):
                story.append(Paragraph("Impedance Triangle", heading_style))
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
                    "Figure 1: Impedance Triangle showing Resistance, Reactance, and Impedance", 
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Add formulas and explanations
            story.append(Paragraph("Formulas Used", heading_style))
            story.append(Spacer(1, 12))
            
            # Total Length formula
            story.append(Paragraph("Total Length:", subheading_style))
            story.append(Paragraph("Total Length = Cable Length + Load Distance", normal_style))
            story.append(Spacer(1, 6))
            
            # Resistance formula
            story.append(Paragraph("Total Resistance:", subheading_style))
            story.append(Paragraph("R = Cable R (Ω/km) × Total Length (km)", normal_style))
            story.append(Spacer(1, 6))
            
            # Reactance formula
            story.append(Paragraph("Total Reactance:", subheading_style))
            story.append(Paragraph("X = Cable X (Ω/km) × Total Length (km)", normal_style))
            story.append(Spacer(1, 6))
            
            # Impedance formula
            story.append(Paragraph("Impedance Magnitude:", subheading_style))
            story.append(Paragraph("Z = √(R² + X²)", normal_style))
            story.append(Spacer(1, 6))
            
            # Impedance angle formula
            story.append(Paragraph("Impedance Angle:", subheading_style))
            story.append(Paragraph("θ = tan⁻¹(X/R)", normal_style))
            
            # Build the PDF
            doc.build(story)
            
            # Force garbage collection
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating PDF: {e}")
            
            # Force garbage collection even on error
            gc.collect()
            
            return False
