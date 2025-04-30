import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from datetime import datetime
import gc  # Import garbage collection

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="protection_relay_pdf")

class ProtectionRelayPdfGenerator:
    """Handles PDF generation for Protection Relay calculator"""
    
    def generate_report(self, data, filepath):
        """Generate PDF report for Protection Relay calculations
        
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
            story.append(Paragraph("Protection Relay Analysis", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Input parameters section
            story.append(Paragraph("Device Information", heading_style))
            story.append(Spacer(1, 12))
            
            # Create parameters table
            params_data = [
                ["Parameter", "Value"],
                ["Device Type", f"{data.get('device_type', 'N/A')}"],
                ["Rating", f"{data.get('rating', 'N/A')} A"],
                ["Breaking Capacity", f"{data.get('breaking_capacity', 'N/A')} A"],
                ["Description", f"{data.get('description', 'N/A')}"]
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
            
            # Protection settings section
            story.append(Paragraph("Protection Settings", heading_style))
            story.append(Spacer(1, 12))
            
            # Create settings table
            settings_data = [
                ["Parameter", "Value"],
                ["Pickup Current", f"{data.get('pickup_current', 'N/A')} A"],
                ["Time Dial Setting", f"{data.get('time_dial', 'N/A')}"],
                ["Curve Type", f"{data.get('curve_type', 'N/A')}"]
            ]
            
            # If MCB-specific data is available, add it
            if data.get('curve_letter'):
                settings_data.append(["MCB Curve", f"{data.get('curve_letter', 'N/A')}"])
            
            # Create and style the table
            settings_table = Table(settings_data)
            settings_table.setStyle(TableStyle([
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
            
            story.append(settings_table)
            story.append(Spacer(1, 24))
            
            # Results section
            story.append(Paragraph("Operation Results", heading_style))
            story.append(Spacer(1, 12))
            
            # Create results table
            results_data = [
                ["Parameter", "Value"],
                ["Fault Current", f"{data.get('fault_current', 'N/A')} A"],
                ["Operating Time", f"{data.get('operating_time', 'N/A'):.3f} s"],
                ["Trip Assessment", self._get_trip_assessment(data.get('operating_time', 0))]
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
            
            # Add time-current curve chart if available
            if 'chart_image_path' in data and data['chart_image_path'] and os.path.exists(data['chart_image_path']):
                story.append(Paragraph("Time-Current Curve", heading_style))
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
                    "Time-Current Curve with Trip Point", 
                    caption_style
                ))
                story.append(Spacer(1, 24))
                
            # Add circuit parameters section if available
            if data.get('circuit_parameters'):
                story.append(Paragraph("Circuit Parameters", heading_style))
                story.append(Spacer(1, 12))
                
                circuit_params = data.get('circuit_parameters', {})
                
                # Create circuit parameters table
                circuit_data = [
                    ["Parameter", "Value"],
                    ["Supply Voltage", f"{circuit_params.get('voltage', 'N/A')} V"],
                    ["Cable Length", f"{circuit_params.get('length', 'N/A')} m"],
                    ["Cable Size", f"{circuit_params.get('size', 'N/A')} mm²"],
                    ["Calculated Fault Current", f"{circuit_params.get('calculated_fault_current', 'N/A')} A"]
                ]
                
                # Create and style the circuit table
                circuit_table = Table(circuit_data)
                circuit_table.setStyle(TableStyle([
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
                
                story.append(circuit_table)
                story.append(Spacer(1, 24))
            
            # Add formulas and explanations
            story.append(Paragraph("Protection Formulas", heading_style))
            story.append(Spacer(1, 12))
            
            # Add the formula for IEC curves
            story.append(Paragraph("IEC Time-Current Characteristic:", subheading_style))
            story.append(Paragraph("t = TDS × a / ((I/Ip)ᵇ - 1)", normal_style))
            story.append(Spacer(1, 6))
            story.append(Paragraph("Where:", normal_style))
            story.append(Paragraph("t = operating time in seconds", normal_style))
            story.append(Paragraph("TDS = time dial setting", normal_style))
            story.append(Paragraph("I = fault current", normal_style))
            story.append(Paragraph("Ip = pickup current", normal_style))
            story.append(Paragraph("a, b = constants based on the selected curve type", normal_style))
            story.append(Spacer(1, 12))
            
            # Add curve type constants
            curve_info = self._get_curve_constants_info(data.get('curve_type', ''))
            if curve_info:
                story.append(Paragraph(f"For {data.get('curve_type', 'Selected Curve')}:", subheading_style))
                story.append(Paragraph(f"a = {curve_info.get('a')}", normal_style))
                story.append(Paragraph(f"b = {curve_info.get('b')}", normal_style))
            
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
    
    def _get_trip_assessment(self, operating_time):
        """Get trip assessment based on operating time"""
        if operating_time <= 0.1:
            return "Instantaneous Trip"
        elif operating_time <= 1.0:
            return "Fast Trip"
        elif operating_time <= 10.0:
            return "Normal Trip"
        else:
            return "Delayed Trip"
    
    def _get_curve_constants_info(self, curve_type):
        """Get constants for the curve type"""
        # Define curve constants
        curve_constants = {
            "IEC Standard Inverse": {"a": 0.14, "b": 0.02},
            "IEC Very Inverse": {"a": 13.5, "b": 1.0},
            "IEC Extremely Inverse": {"a": 80.0, "b": 2.0},
            "IEC Long Time Inverse": {"a": 120, "b": 1.0},
            "IEEE Moderately Inverse": {"a": 0.0515, "b": 0.02},
            "IEEE Very Inverse": {"a": 19.61, "b": 2.0},
            "IEEE Extremely Inverse": {"a": 28.2, "b": 2.0}
        }
        
        return curve_constants.get(curve_type, {})
