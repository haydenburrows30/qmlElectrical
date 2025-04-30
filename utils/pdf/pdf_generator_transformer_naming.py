from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
import os
from datetime import datetime
import gc

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="transformer_naming_pdf")

class TransformerNamingPdfGenerator:
    """Handles PDF generation for transformer naming guide"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for transformer naming
        
        Args:
            data: Dictionary containing transformer naming data
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
            
            # Create custom list item style
            list_style = ParagraphStyle(
                'ListItem',
                parent=styles['Normal'],
                leftIndent=20,
                firstLineIndent=0,
                spaceBefore=2,
                bulletIndent=10
            )
            
            # Create content
            story = []
            
            # Add title
            story.append(Paragraph(f"{data['transformer_type']} - Transformer Naming Guide", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Transformer parameters section
            story.append(Paragraph("Transformer Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create parameters table
            params_data = [
                ["Parameter", "Value"],
                ["Transformer Type", data.get('transformer_type', 'N/A')],
                ["Primary Rating", f"{data.get('primary_rating', 'N/A')} A" if data.get('transformer_type', 'CT') == "CT" 
                                    else f"{data.get('primary_rating', 'N/A')} V"],
                ["Secondary Rating", f"{data.get('secondary_rating', 'N/A')} A" if data.get('transformer_type', 'CT') == "CT" 
                                    else f"{data.get('secondary_rating', 'N/A')} V"],
                ["Accuracy Class", data.get('accuracy_class', 'N/A')],
                ["Burden", f"{data.get('burden', 'N/A')} VA"],
                ["Insulation Level", f"{data.get('insulation_level', 'N/A')} kV"],
                ["Application", data.get('application', 'N/A').capitalize()],
                ["Installation", data.get('installation', 'N/A').capitalize()],
                ["Frequency", f"{data.get('frequency', 'N/A')} Hz"],
                ["Thermal Rating", f"{data.get('thermal_rating', 'N/A')}x"]
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
            
            # Naming conventions section
            story.append(Paragraph("Naming Conventions", heading_style))
            story.append(Spacer(1, 12))
            
            # Naming standards table
            naming_data = [
                ["Standard", "Naming Format"]
            ]
            
            # Add naming standards from data
            if 'naming_standards' in data:
                for std, name in data['naming_standards'].items():
                    naming_data.append([std, name])
            
            # Create naming standards table
            naming_table = Table(naming_data, colWidths=[doc.width * 0.2, doc.width * 0.6])
            naming_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (1, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (1, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (1, 0), 12),
                ('BOTTOMPADDING', (0, 0), (1, 0), 6),
                ('BACKGROUND', (0, 1), (1, -1), colors.white),
                ('GRID', (0, 0), (1, -1), 1, colors.black),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (0, -1), 'CENTER'),
                ('VALIGN', (0, 0), (1, -1), 'MIDDLE')
            ]))
            
            story.append(naming_table)
            story.append(Spacer(1, 24))
            
            # Add diagram if available
            if 'diagram_path' in data and data['diagram_path'] and os.path.exists(data['diagram_path']):
                story.append(Paragraph("Transformer Diagram", heading_style))
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
                    f"Figure 1: {data['transformer_type']} Diagram showing key components and parameters",
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Add description section
            story.append(Paragraph("Understanding the Naming Convention", heading_style))
            story.append(Spacer(1, 12))
            
            # Add the description content
            if 'description' in data and data['description']:
                # Split the description and format as paragraphs
                description_lines = data['description'].split('\n')
                for line in description_lines:
                    if line.strip():
                        story.append(Paragraph(line, normal_style))
                        story.append(Spacer(1, 6))
            
            # Add application information
            story.append(Paragraph("Application Notes", subheading_style))
            
            if data.get('transformer_type') == "CT":
                # CT application notes
                story.append(Paragraph("Current transformers are used to:", normal_style))
                story.append(Spacer(1, 6))
                
                story.append(Paragraph("• Convert high primary currents to lower secondary currents for measurement", list_style))
                story.append(Paragraph("• Provide electrical isolation between the primary and secondary circuits", list_style))
                story.append(Paragraph("• Supply current signals for protection relays and metering devices", list_style))
                
                if data.get('application') == "metering":
                    story.append(Spacer(1, 6))
                    story.append(Paragraph("For metering applications, accuracy is critical at normal operating currents. Typical accuracy classes are 0.1, 0.2, 0.5, and 1.0.", normal_style))
                    
                elif data.get('application') == "protection":
                    story.append(Spacer(1, 6))
                    story.append(Paragraph("For protection applications, the CT must maintain accuracy during fault conditions. Typical protection classes are 5P10, 5P20, 10P10, and 10P20, where the number after 'P' represents the Accuracy Limit Factor (ALF).", normal_style))
            
            else:  # VT
                # VT application notes
                story.append(Paragraph("Voltage transformers are used to:", normal_style))
                story.append(Spacer(1, 6))
                
                story.append(Paragraph("• Convert high primary voltages to lower secondary voltages for measurement", list_style))
                story.append(Paragraph("• Provide electrical isolation between the primary and secondary circuits", list_style))
                story.append(Paragraph("• Supply voltage signals for protection relays and metering devices", list_style))
                
                if data.get('application') == "metering":
                    story.append(Spacer(1, 6))
                    story.append(Paragraph("For metering applications, VTs require high accuracy at nominal voltage. Typical accuracy classes are 0.1, 0.2, 0.5, and 1.0.", normal_style))
                    
                elif data.get('application') == "protection":
                    story.append(Spacer(1, 6))
                    story.append(Paragraph("For protection applications, VTs must maintain accuracy across a wider voltage range. Typical protection classes are 3P and 6P.", normal_style))
            
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
