from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
import os
from datetime import datetime
import gc

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="overcurrent_pdf")

class OvercurrentPdfGenerator:
    """Handles PDF generation for overcurrent protection calculator"""
    
    def generate_report(self, data, filepath):
        """Generate PDF report for overcurrent protection settings
        
        Args:
            data: Dictionary with calculation data and protection settings
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
            story.append(Paragraph("Overcurrent Protection Settings Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # System parameters section
            story.append(Paragraph("System Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create parameters table
            params_data = [
                ["Parameter", "Value"],
                ["Cable Cross Section", f"{data.get('cable_cross_section', 0)} mm²"],
                ["Cable Length", f"{data.get('cable_length', 0):.1f} km"],
                ["Cable Voltage", f"{data.get('cable_voltage', 0):.0f} V"],
                ["Cable Material", f"{data.get('cable_material', '')}"],
                ["Cable Type", f"{data.get('cable_type', '')}"],
                ["Installation Method", f"{data.get('cable_installation', '')}"],
                ["Soil Resistivity", f"{data.get('soil_resistivity', 0):.1f} Ω·m"],
                ["Ambient Temperature", f"{data.get('ambient_temperature', 0):.1f} °C"],
                ["System Fault Level", f"{data.get('system_fault_level', 0):.1f} MVA"],
                ["Transformer Rating", f"{data.get('transformer_rating', 0):.1f} MVA"],
                ["Transformer Impedance", f"{data.get('transformer_impedance', 0):.1f}%"],
                ["Transformer X/R Ratio", f"{data.get('transformer_xr_ratio', 0):.1f}"],
                ["Transformer Vector Group", f"{data.get('transformer_vector_group', '')}"],
                ["CT Ratio", f"{data.get('ct_ratio', 0)}:1"],
                ["Curve Standard", f"{data.get('curve_standard', '')}"]
            ]
            
            if data.get('cable_type') == 'Custom':
                params_data.append(["Cable R", f"{data.get('cable_r', 0):.3f} Ω/km"])
                params_data.append(["Cable X", f"{data.get('cable_x', 0):.3f} Ω/km"])
            
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
            
            # Cable and fault analysis section
            story.append(Paragraph("Cable & Fault Analysis", heading_style))
            story.append(Spacer(1, 12))
            
            # Create results table
            results_data = [
                ["Parameter", "Value"],
                ["Cable Impedance", f"{data.get('cable_impedance', 0):.3f} Ω"],
                ["Maximum Load Current", f"{data.get('max_load_current', 0):.1f} A"],
                ["3-Phase Fault Current", f"{data.get('fault_current_3ph', 0):.1f} A"],
                ["Phase-Phase Fault Current", f"{data.get('fault_current_2ph', 0):.1f} A"],
                ["Phase-Earth Fault Current", f"{data.get('fault_current_1ph', 0):.1f} A"]
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
            
            # Protection settings section
            story.append(Paragraph("Protection Settings", heading_style))
            story.append(Spacer(1, 12))
            
            # Phase protection settings
            story.append(Paragraph("Phase Overcurrent Protection (50/51)", subheading_style))
            story.append(Spacer(1, 6))
            
            phase_settings = [
                ["Function", "Setting", "Value"],
                ["50", "Pickup Current", f"{data.get('i_pickup_50', 0):.1f} A"],
                ["50", "Time Delay", f"{data.get('time_delay_50', 0):.2f} s"],
                ["51", "Pickup Current", f"{data.get('i_pickup_51', 0):.1f} A"],
                ["51", "Time Dial", f"{data.get('time_dial_51', 0):.2f}"],
                ["51", "Curve Type", f"{data.get('curve_type_51', '')}"]
            ]
            
            # Add CT percentage values if available
            if 'ct_ratio' in data and data['ct_ratio'] > 0:
                ct_ratio = data['ct_ratio']
                phase_settings[1][2] += f" ({data.get('i_pickup_50', 0)/ct_ratio*100:.1f}%)"
                phase_settings[3][2] += f" ({data.get('i_pickup_51', 0)/ct_ratio*100:.1f}%)"
            
            phase_table = Table(phase_settings)
            phase_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (2, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (2, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (2, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (2, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (2, 0), 12),
                ('BOTTOMPADDING', (0, 0), (2, 0), 6),
                ('BACKGROUND', (0, 1), (2, -1), colors.white),
                ('GRID', (0, 0), (2, -1), 1, colors.black),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (0, -1), 'CENTER'),
                ('ALIGN', (1, 0), (1, -1), 'LEFT'),
                ('ALIGN', (2, 0), (2, -1), 'RIGHT')
            ]))
            
            story.append(phase_table)
            story.append(Spacer(1, 12))
            
            # Earth fault protection settings
            story.append(Paragraph("Earth Fault Protection (50N/51N)", subheading_style))
            story.append(Spacer(1, 6))
            
            earth_settings = [
                ["Function", "Setting", "Value"],
                ["50N", "Pickup Current", f"{data.get('i_pickup_50n', 0):.1f} A"],
                ["50N", "Time Delay", f"{data.get('time_delay_50n', 0):.2f} s"],
                ["51N", "Pickup Current", f"{data.get('i_pickup_51n', 0):.1f} A"],
                ["51N", "Time Dial", f"{data.get('time_dial_51n', 0):.2f}"],
                ["51N", "Curve Type", f"{data.get('curve_type_51n', '')}"]
            ]
            
            # Add CT percentage values
            if 'ct_ratio' in data and data['ct_ratio'] > 0:
                ct_ratio = data['ct_ratio']
                earth_settings[1][2] += f" ({data.get('i_pickup_50n', 0)/ct_ratio*100:.1f}%)"
                earth_settings[3][2] += f" ({data.get('i_pickup_51n', 0)/ct_ratio*100:.1f}%)"
            
            earth_table = Table(earth_settings)
            earth_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (2, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (2, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (2, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (2, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (2, 0), 12),
                ('BOTTOMPADDING', (0, 0), (2, 0), 6),
                ('BACKGROUND', (0, 1), (2, -1), colors.white),
                ('GRID', (0, 0), (2, -1), 1, colors.black),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (0, -1), 'CENTER'),
                ('ALIGN', (1, 0), (1, -1), 'LEFT'),
                ('ALIGN', (2, 0), (2, -1), 'RIGHT')
            ]))
            
            story.append(earth_table)
            story.append(Spacer(1, 12))
            
            # Negative sequence protection settings
            story.append(Paragraph("Negative Sequence Protection (50Q)", subheading_style))
            story.append(Spacer(1, 6))
            
            neg_seq_settings = [
                ["Function", "Setting", "Value"],
                ["50Q", "Pickup Current", f"{data.get('i_pickup_50q', 0):.1f} A"],
                ["50Q", "Time Delay", f"{data.get('time_delay_50q', 0):.2f} s"]
            ]
            
            # Add CT percentage values
            if 'ct_ratio' in data and data['ct_ratio'] > 0:
                neg_seq_settings[1][2] += f" ({data.get('i_pickup_50q', 0)/data['ct_ratio']*100:.1f}%)"
            
            neg_seq_table = Table(neg_seq_settings)
            neg_seq_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (2, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (2, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (2, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (2, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (2, 0), 12),
                ('BOTTOMPADDING', (0, 0), (2, 0), 6),
                ('BACKGROUND', (0, 1), (2, -1), colors.white),
                ('GRID', (0, 0), (2, -1), 1, colors.black),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (0, -1), 'CENTER'),
                ('ALIGN', (1, 0), (1, -1), 'LEFT'),
                ('ALIGN', (2, 0), (2, -1), 'RIGHT')
            ]))
            
            story.append(neg_seq_table)
            story.append(Spacer(1, 24))
            
            # Add time-current curve chart if available
            chart_image_path = data.get('chart_image_path', '')
            if chart_image_path and os.path.exists(chart_image_path):
                story.append(Paragraph("Time-Current Curves", heading_style))
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
                    "Figure 1: Overcurrent Protection Time-Current Curves", 
                    caption_style
                ))
            
            # Build the PDF
            doc.build(story)
            
            # Force garbage collection
            gc.collect()
            
            return True
            
        except Exception as e:
            import traceback
            logger.error(f"Error generating PDF: {e}")
            logger.error(traceback.format_exc())
            
            # Force garbage collection even on error
            gc.collect()
            
            return False
