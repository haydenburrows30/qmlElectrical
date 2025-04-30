import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from datetime import datetime
import gc

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="delta_pdf")

class DeltaTransformerPdfGenerator:
    """Handles PDF generation for Delta Transformer calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for delta transformer calculations
        
        Args:
            data: Dictionary with delta transformer data
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
            story.append(Paragraph("Open Delta Transformer Calculation Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # System Parameters section
            story.append(Paragraph("System Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create parameters table
            params_data = [
                ["Parameter", "Value"],
                ["Primary Voltage", f"{data.get('primary_voltage', 0):.1f} V"],
                ["Secondary Voltage (L-L)", f"{data.get('secondary_voltage', 0):.1f} V"],
                ["Secondary Phase Voltage", f"{data.get('phase_voltage', 0):.1f} V"],
                ["Transformer Power Rating", f"{data.get('power_rating', 0):.1f} VA"],
                ["Open Delta Capacity Factor", f"{data.get('open_delta_factor', 0.866) * 100:.1f}%"]
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
                ["Required Resistor Value", f"{data.get('resistor_value', 0):.2f} Ω"],
                ["Resistor Power Rating", f"{data.get('resistor_wattage', 0):.2f} W"],
                ["Safety Factor Applied", f"{data.get('safety_factor', 3.0)}x"],
                ["Recommended Resistor Power", f"{data.get('resistor_wattage', 0) * data.get('safety_factor', 3.0):.2f} W"]
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
            
            # Add diagram if available
            if 'diagram_path' in data and data['diagram_path'] and os.path.exists(data['diagram_path']):
                story.append(Paragraph("Open Delta Configuration", heading_style))
                story.append(Spacer(1, 12))
                
                # Get the image dimensions to maintain aspect ratio
                from PIL import Image as PILImage
                with PILImage.open(data['diagram_path']) as img:
                    orig_width, orig_height = img.size
                
                # Calculate the aspect ratio
                aspect_ratio = orig_height / orig_width
                
                # Calculate appropriate image width based on available page width
                available_width = doc.width * 0.95  # Use 95% of available width
                
                # Set the image width and calculate height to maintain aspect ratio
                img = Image(data['diagram_path'])
                img.drawWidth = available_width
                img.drawHeight = available_width * aspect_ratio
                
                # Add the image
                story.append(img)
                story.append(Spacer(1, 12))
                
                # Add image caption
                story.append(Paragraph(
                    "Figure 1: Open Delta Transformer Configuration with Resistor", 
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Add notes on the delta transformer
            story.append(Paragraph("Notes on Open Delta Configuration", heading_style))
            story.append(Spacer(1, 12))
            
            # Add explanation for open delta configuration
            story.append(Paragraph("Open Delta Configuration", subheading_style))
            story.append(Paragraph(
                "An open delta (or V-V) connection uses two single-phase transformers to create a three-phase system. "
                "The power capacity of an open delta configuration is 86.6% (√3/2) of an equivalent delta configuration "
                "with three transformers of the same size.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            # Add explanation for resistor calculation
            story.append(Paragraph("Resistor Calculation", subheading_style))
            story.append(Paragraph(
                "The resistor value is calculated using the formula: R = (3√3 × U²) / P, where:<br/>"
                "• U is the secondary phase voltage (V/√3 for Y-connected secondary, V/3 for delta)<br/>"
                "• P is the transformer power rating in VA<br/><br/>"
                "For safety, the resistor power rating should include a margin for transient conditions. "
                "A recommended practice is to use at least a 3x safety factor for the wattage rating.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            # Add safety considerations
            story.append(Paragraph("Safety Considerations", subheading_style))
            story.append(Paragraph(
                "• The resistor must be properly rated for the voltage and power dissipation.<br/>"
                "• Use a resistor with adequate heat dissipation capabilities.<br/>"
                "• Consider ambient temperature and ventilation in the installation location.<br/>"
                "• Ensure proper electrical clearances and mechanical protection.<br/>"
                "• Regular inspection and maintenance are recommended.",
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
