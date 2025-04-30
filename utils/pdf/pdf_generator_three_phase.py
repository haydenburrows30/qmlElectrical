import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from datetime import datetime
import gc

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="three_phase_pdf")

class ThreePhasePdfGenerator:
    """Handles PDF generation for Three-Phase calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for three-phase system analysis
        
        Args:
            data: Dictionary with three-phase data
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
            
            # Create smaller font style for tables
            small_style = ParagraphStyle(
                'Small',
                parent=styles['Normal'],
                fontSize=8
            )
            
            # Create content
            story = []
            
            # Add title
            story.append(Paragraph("Three-Phase System Analysis Report", title_style))
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
                ["Frequency", f"{data.get('frequency', 50):.1f} Hz"],
                ["Configuration", "3-Phase, 3-Wire" if data.get('three_wire', True) else "3-Phase, 4-Wire"]
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
            
            # Voltage and Current Data section - Split into multiple tables
            story.append(Paragraph("Voltage and Current Measurements", heading_style))
            story.append(Spacer(1, 12))
            
            # Create RMS voltage table
            voltage_data = [
                ["Phase", "RMS Voltage (V)", "Peak Voltage (V)", "Phase Angle (°)"],
                ["A", f"{data.get('rms_a', 0):.1f}", f"{data.get('peak_a', 0):.1f}", f"{data.get('phase_angle_a', 0):.1f}"],
                ["B", f"{data.get('rms_b', 0):.1f}", f"{data.get('peak_b', 0):.1f}", f"{data.get('phase_angle_b', 0):.1f}"],
                ["C", f"{data.get('rms_c', 0):.1f}", f"{data.get('peak_c', 0):.1f}", f"{data.get('phase_angle_c', 0):.1f}"]
            ]
            
            # Create and style the voltage table
            voltage_table = Table(voltage_data, colWidths=[doc.width*0.15, doc.width*0.25, doc.width*0.25, doc.width*0.25])
            voltage_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 10),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 6),
                ('BACKGROUND', (0, 1), (-1, -1), colors.white),
                ('GRID', (0, 0), (-1, -1), 1, colors.black),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
                ('ALIGN', (0, 1), (0, -1), 'CENTER'),
                ('ALIGN', (1, 1), (-1, -1), 'CENTER')
            ]))
            
            story.append(voltage_table)
            story.append(Spacer(1, 12))
            
            # Create current table separately
            current_data = [
                ["Phase", "Current (A)", "Phase Angle (°)", "Power Factor"],
                ["A", f"{data.get('current_a', 0):.1f}", f"{data.get('current_angle_a', 0):.1f}", f"{data.get('power_factor_a', 0):.3f}"],
                ["B", f"{data.get('current_b', 0):.1f}", f"{data.get('current_angle_b', 0):.1f}", f"{data.get('power_factor_b', 0):.3f}"],
                ["C", f"{data.get('current_c', 0):.1f}", f"{data.get('current_angle_c', 0):.1f}", f"{data.get('power_factor_c', 0):.3f}"]
            ]
            
            # Create and style the current table
            current_table = Table(current_data, colWidths=[doc.width*0.15, doc.width*0.25, doc.width*0.25, doc.width*0.25])
            current_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 10),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 6),
                ('BACKGROUND', (0, 1), (-1, -1), colors.white),
                ('GRID', (0, 0), (-1, -1), 1, colors.black),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
                ('ALIGN', (0, 1), (0, -1), 'CENTER'),
                ('ALIGN', (1, 1), (-1, -1), 'CENTER')
            ]))
            
            story.append(current_table)
            story.append(Spacer(1, 24))
            
            # Line-to-Line Voltage section
            story.append(Paragraph("Line-to-Line Voltages", heading_style))
            story.append(Spacer(1, 12))
            
            # Create line voltage table
            line_data = [
                ["Line", "RMS Voltage (V)"],
                ["A-B", f"{data.get('rms_ab', 0):.1f}"],
                ["B-C", f"{data.get('rms_bc', 0):.1f}"],
                ["C-A", f"{data.get('rms_ca', 0):.1f}"]
            ]
            
            # Create and style the line voltage table
            line_table = Table(line_data)
            line_table.setStyle(TableStyle([
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
                ('ALIGN', (1, 0), (1, -1), 'CENTER')
            ]))
            
            story.append(line_table)
            story.append(Spacer(1, 24))
            
            # Sequence Components section
            story.append(Paragraph("Symmetrical Components", heading_style))
            story.append(Spacer(1, 12))
            
            # Create sequence components table
            seq_data = [
                ["Component", "Voltage (V)", "Current (A)"],
                ["Positive Sequence", f"{data.get('positive_seq', 0):.1f}", f"{data.get('positive_seq_current', 0):.1f}"],
                ["Negative Sequence", f"{data.get('negative_seq', 0):.1f}", f"{data.get('negative_seq_current', 0):.1f}"],
                ["Zero Sequence", f"{data.get('zero_seq', 0):.1f}", f"{data.get('zero_seq_current', 0):.1f}"],
                ["Voltage Unbalance", f"{data.get('voltage_unbalance', 0):.2f}%", ""],
                ["Current Unbalance", "", f"{data.get('current_unbalance', 0):.2f}%"]
            ]
            
            # Create and style the sequence components table
            seq_table = Table(seq_data)
            seq_table.setStyle(TableStyle([
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
                ('ALIGN', (1, 0), (2, -1), 'CENTER'),
                # Highlight unbalance values if they exceed thresholds
                ('TEXTCOLOR', (1, 2), (1, 2), colors.red if data.get('negative_seq', 0) > 5 else colors.black),
                ('TEXTCOLOR', (2, 2), (2, 2), colors.red if data.get('negative_seq_current', 0) > 5 else colors.black),
                ('TEXTCOLOR', (1, 3), (1, 3), colors.red if data.get('zero_seq', 0) > 5 else colors.black),
                ('TEXTCOLOR', (2, 3), (2, 3), colors.red if data.get('zero_seq_current', 0) > 0.1 else colors.black),
                ('TEXTCOLOR', (1, 4), (1, 4), colors.red if data.get('voltage_unbalance', 0) > 2 else colors.black),
                ('TEXTCOLOR', (2, 5), (2, 5), colors.red if data.get('current_unbalance', 0) > 10 else colors.black)
            ]))
            
            story.append(seq_table)
            story.append(Spacer(1, 24))
            
            # Power Analysis section
            story.append(Paragraph("Power Analysis", heading_style))
            story.append(Spacer(1, 12))
            
            # Create power analysis table
            power_data = [
                ["Parameter", "Value"],
                ["Active Power (P)", f"{data.get('active_power', 0):.2f} kW"],
                ["Reactive Power (Q)", f"{data.get('reactive_power', 0):.2f} kVAR"],
                ["Apparent Power (S)", f"{data.get('apparent_power', 0):.2f} kVA"],
                ["System Power Factor", f"{data.get('avg_power_factor', 0):.3f}"],
                ["Total Harmonic Distortion", f"{data.get('thd', 0):.2f}%"]
            ]
            
            # Create and style the power analysis table
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
            
            # Add waveform chart if available
            if 'waveform_chart_path' in data and data['waveform_chart_path'] and os.path.exists(data['waveform_chart_path']):
                story.append(Paragraph("Three-Phase Waveforms", heading_style))
                story.append(Spacer(1, 12))
                
                # Get the image dimensions to maintain aspect ratio
                from PIL import Image as PILImage
                with PILImage.open(data['waveform_chart_path']) as img:
                    orig_width, orig_height = img.size
                
                # Calculate the aspect ratio
                aspect_ratio = orig_height / orig_width
                
                # Calculate appropriate image width based on available page width
                available_width = doc.width * 0.95  # Use 95% of available width
                
                # Set the image width and calculate height to maintain aspect ratio
                img = Image(data['waveform_chart_path'])
                img.drawWidth = available_width
                img.drawHeight = available_width * aspect_ratio
                
                # Add the image
                story.append(img)
                story.append(Spacer(1, 12))
                
                # Add image caption with custom caption style
                story.append(Paragraph(
                    "Figure 1: Three-Phase Voltage Waveforms", 
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Add phasor diagram if available
            if 'phasor_chart_path' in data and data['phasor_chart_path'] and os.path.exists(data['phasor_chart_path']):
                story.append(Paragraph("Phasor Diagram", heading_style))
                story.append(Spacer(1, 12))
                
                # Get the image dimensions to maintain aspect ratio
                from PIL import Image as PILImage
                with PILImage.open(data['phasor_chart_path']) as img:
                    orig_width, orig_height = img.size
                
                # Calculate the aspect ratio
                aspect_ratio = orig_height / orig_width
                
                # Calculate appropriate image width based on available page width
                available_width = doc.width * 0.95  # Use 95% of available width
                
                # Set the image width and calculate height to maintain aspect ratio
                img = Image(data['phasor_chart_path'])
                img.drawWidth = available_width
                img.drawHeight = available_width * aspect_ratio
                
                # Add the image
                story.append(img)
                story.append(Spacer(1, 12))
                
                # Add image caption with custom caption style
                story.append(Paragraph(
                    "Figure 2: Voltage and Current Phasor Diagram", 
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Add notes on the three-phase system
            story.append(Paragraph("Notes on Three-Phase Analysis", heading_style))
            story.append(Spacer(1, 12))
            
            # Add explanatory text for symmetrical components
            story.append(Paragraph("Symmetrical Components", subheading_style))
            story.append(Paragraph(
                "Symmetrical components are mathematical transformations used to analyze unbalanced three-phase systems. "
                "They consist of three components:",
                normal_style
            ))
            story.append(Spacer(1, 6))
            
            # Explanation of each component
            story.append(Paragraph("• <b>Positive Sequence:</b> Three equal phasors with 120° displacement, rotating in the normal sequence. "
                                 "These are the desired, balanced components.", normal_style))
            story.append(Paragraph("• <b>Negative Sequence:</b> Three equal phasors with 120° displacement, rotating in the reverse sequence. "
                                 "These are undesirable and cause reverse rotation in motors.", normal_style))
            story.append(Paragraph("• <b>Zero Sequence:</b> Three equal phasors with zero displacement (in phase). "
                                 "These cannot exist in a three-wire system without a neutral path.", normal_style))
            story.append(Spacer(1, 12))
            
            # Add note on voltage unbalance
            story.append(Paragraph("Voltage Unbalance", subheading_style))
            story.append(Paragraph(
                "Voltage unbalance is calculated as the ratio of negative sequence voltage to positive sequence voltage, expressed as a percentage. "
                "Per IEEE standards, voltage unbalance should not exceed 2% for sensitive equipment.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            # Add note on power factor
            story.append(Paragraph("Power Factor", subheading_style))
            story.append(Paragraph(
                "Power factor is the ratio of active power (kW) to apparent power (kVA). It represents how effectively electrical power is being used. "
                "A power factor of 1.0 is ideal, while lower values indicate inefficient power usage and may incur utility penalties.",
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
