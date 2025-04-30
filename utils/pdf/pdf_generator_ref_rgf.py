import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from datetime import datetime
import gc

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="ref_rgf_pdf")

class RefRgfPdfGenerator:
    """Handles PDF generation for REF/RGF calculator"""
    
    def generate_report(self, data, filepath):
        """Generate PDF report for REF/RGF calculations
        
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
            story.append(Paragraph("REF/RGF Protection Analysis", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Input parameters section
            story.append(Paragraph("Transformer Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create parameters table
            transformer_data = [
                ["Parameter", "Value"],
                ["Transformer Rating", f"{data['transformer_mva']:.2f} MVA"],
                ["HV Voltage", f"{data['hv_transformer_voltage']:.1f} kV"],
                ["LV Voltage", f"{data['lv_transformer_voltage']:.1f} kV"],
                ["Connection Type", f"{data['connection_type']}"],
                ["Impedance", f"{data['impedance']:.2f}%"]
            ]
            
            # Create and style the table
            transformer_table = Table(transformer_data)
            transformer_table.setStyle(TableStyle([
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
            
            story.append(transformer_table)
            story.append(Spacer(1, 24))
            
            # CT Parameters section
            story.append(Paragraph("Current Transformer Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create CT parameters table
            ct_data = [
                ["Parameter", "Value"],
                ["Phase CT Ratio", f"{data['ph_ct_ratio']}:{data['ct_secondary_type']}"],
                ["Neutral CT Ratio", f"{data['n_ct_ratio']}:{data['ct_secondary_type']}"],
                ["Fault Point", f"{data['fault_point']:.1f}%"]
            ]
            
            # Create and style the table
            ct_table = Table(ct_data)
            ct_table.setStyle(TableStyle([
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
            
            story.append(ct_table)
            story.append(Spacer(1, 24))
            
            # Results section
            story.append(Paragraph("Protection Results", heading_style))
            story.append(Spacer(1, 12))
            
            # Create results table
            results_data = [
                ["Parameter", "Value"],
                ["Load Current", f"{data['load_current']:.2f} A"],
                ["Fault Current", f"{data['fault_current']:.2f} A"],
                ["Fault at {:.1f}%".format(data['fault_point']), f"{data['fault_point_five']:.2f} A"],
                ["G-Diff Pickup", f"{data['g_diff_pickup']:.4f} A"]
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
            
            # Add REF/RGF diagram if available
            if 'chart_image_path' in data and data['chart_image_path'] and os.path.exists(data['chart_image_path']):
                story.append(Paragraph("REF/RGF Protection Diagram", heading_style))
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
                    "Figure 1: REF/RGF Protection Diagram for Transformer", 
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Add explanation section
            story.append(Paragraph("REF/RGF Protection Explanation", heading_style))
            story.append(Spacer(1, 12))
            
            story.append(Paragraph(
                "Restricted Earth Fault (REF) and Restricted Ground Fault (RGF) protection are differential "
                "protection schemes used to protect transformers from internal earth faults. These protection "
                "schemes are particularly effective at detecting faults close to the neutral point of the "
                "transformer, where the fault current may be too low for overcurrent protection to operate.",
                normal_style
            ))
            story.append(Spacer(1, 6))
            
            story.append(Paragraph("Protection Settings:", subheading_style))
            story.append(Paragraph(
                "The G-Diff pickup value is calculated based on the fault current at a specific percentage point "
                f"of the transformer winding (in this case, {data['fault_point']:.1f}%). The pickup value is "
                "typically set to be sensitive enough to detect low-level earth faults while avoiding nuisance "
                "tripping during normal operation.",
                normal_style
            ))
            story.append(Spacer(1, 6))
            
            story.append(Paragraph("CT Requirements:", subheading_style))
            story.append(Paragraph(
                "Current transformers used for REF/RGF protection must have identical ratios and characteristics "
                "to ensure sensitive and stable operation. The secondary ratings are typically "
                f"{data['ct_secondary_type']} based on the application, and the ratio is selected based on "
                "the maximum load current with margin for overload conditions.",
                normal_style
            ))
            story.append(Spacer(1, 6))
            
            story.append(Paragraph("REF/RGF Relay Operation:", subheading_style))
            story.append(Paragraph(
                "The REF/RGF relay operates on the principle of current balance. During normal operation or "
                "external faults, the sum of the currents entering and leaving the protected zone is zero. "
                "During an internal fault, the sum becomes non-zero, causing the relay to operate.",
                normal_style
            ))
            
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
