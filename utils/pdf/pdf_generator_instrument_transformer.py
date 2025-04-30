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
logger = configure_logger("qmltest", component="instrument_transformer_pdf")

class InstrumentTransformerPdfGenerator:
    """Handles PDF generation for instrument transformer calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for instrument transformer calculations
        
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
            story.append(Paragraph("Instrument Transformer Analysis Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Current Transformer section
            story.append(Paragraph("Current Transformer Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create CT parameters table
            ct_data = [
                ["Parameter", "Value"],
                ["CT Type", data.get('ct_type', 'N/A')],
                ["CT Ratio", data.get('ct_ratio', 'N/A')],
                ["Burden", f"{data.get('ct_burden', 0):.1f} VA"],
                ["Power Factor", f"{data.get('power_factor', 0) * 100:.0f}%"],
                ["Temperature", f"{data.get('temperature', 0):.1f} °C"],
                ["Accuracy Class", data.get('accuracy_class', 'N/A')]
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
            
            # Current Transformer Results section
            story.append(Paragraph("Current Transformer Results", heading_style))
            story.append(Spacer(1, 12))
            
            # Create CT results table
            ct_results_data = [
                ["Parameter", "Value"],
                ["Knee Point Voltage", f"{data.get('knee_point_voltage', 0):.1f} V"],
                ["Maximum Fault Current", f"{data.get('max_fault_current', 0):.1f} A"],
                ["Minimum CT Burden", f"{data.get('min_accuracy_burden', 0):.2f} Ω"],
                ["Error Margin", f"{data.get('error_margin', 0):.2f}%"],
                ["Temperature Effect", f"{data.get('temperature_effect', 0):.2f}%"],
                ["Saturation Status", data.get('saturation_status', 'N/A')],
                ["Saturation Factor", f"{data.get('saturation_factor', 0):.2f}"]
            ]
            
            # Create and style the results table
            ct_results_table = Table(ct_results_data)
            ct_results_table.setStyle(TableStyle([
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
            
            story.append(ct_results_table)
            story.append(Spacer(1, 24))
            
            # Voltage Transformer section
            story.append(Paragraph("Voltage Transformer Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create VT parameters table
            vt_data = [
                ["Parameter", "Value"],
                ["VT Ratio", data.get('vt_ratio', 'N/A')],
                ["VT Burden", f"{data.get('vt_burden', 0):.1f} VA"],
                ["Rated Voltage Factor", data.get('rated_voltage_factor', 'N/A')]
            ]
            
            # Create and style the table
            vt_table = Table(vt_data)
            vt_table.setStyle(TableStyle([
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
            
            story.append(vt_table)
            story.append(Spacer(1, 24))
            
            # Voltage Transformer Results section
            story.append(Paragraph("Voltage Transformer Results", heading_style))
            story.append(Spacer(1, 12))
            
            # Create VT results table
            vt_results_data = [
                ["Parameter", "Value"],
                ["VT Rated Voltage", f"{data.get('vt_rated_voltage', 0):.1f} V"],
                ["VT Impedance", f"{data.get('vt_impedance', 0):.1f} Ω"],
                ["VT Burden Status", data.get('vt_burden_status', 'N/A')],
                ["Burden Utilization", f"{data.get('vt_burden_utilization', 0):.1f}%"]
            ]
            
            # Create and style the results table
            vt_results_table = Table(vt_results_data)
            vt_results_table.setStyle(TableStyle([
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
            
            story.append(vt_results_table)
            story.append(Spacer(1, 24))
            
            # Add saturation curve chart if image path is provided
            if 'chart_image_path' in data and data['chart_image_path'] and os.path.exists(data['chart_image_path']):
                story.append(Paragraph("CT Saturation Curve", heading_style))
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
                    "Figure 1: CT Saturation Curve showing voltage vs. current relationship",
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Add harmonics chart if image path is provided
            if 'harmonics_image_path' in data and data['harmonics_image_path'] and os.path.exists(data['harmonics_image_path']):
                story.append(Paragraph("Harmonic Analysis", heading_style))
                story.append(Spacer(1, 12))
                
                # Get the image dimensions to maintain aspect ratio
                from PIL import Image as PILImage
                with PILImage.open(data['harmonics_image_path']) as img:
                    orig_width, orig_height = img.size
                
                # Calculate the aspect ratio
                aspect_ratio = orig_height / orig_width
                
                # Calculate appropriate image width based on available page width
                available_width = doc.width * 0.95  # Use 95% of available width
                
                # Set the image width and calculate height to maintain aspect ratio
                img = Image(data['harmonics_image_path'])
                img.drawWidth = available_width
                img.drawHeight = available_width * aspect_ratio
                
                # Add the image
                story.append(img)
                story.append(Spacer(1, 12))
                
                # Add image caption with custom caption style
                story.append(Paragraph(
                    "Figure 2: Harmonic Content Analysis for the Current Transformer",
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Add recommendations if available
            if data.get('accuracy_recommendation', '') and data.get('accuracy_recommendation', '') != "No issues detected. Operation within specifications.":
                story.append(Paragraph("Recommendations", heading_style))
                story.append(Spacer(1, 12))
                
                # Split recommendations into paragraphs
                recommendation_text = data.get('accuracy_recommendation', '')
                recommendations = recommendation_text.split('\n')
                
                for recommendation in recommendations:
                    if recommendation.strip():
                        story.append(Paragraph(recommendation.strip(), normal_style))
                        story.append(Spacer(1, 6))
            
            # Environmental factors section if available
            if 'environmental_factors' in data and data['environmental_factors']:
                story.append(Paragraph("Environmental Factors", heading_style))
                story.append(Spacer(1, 12))
                
                env_data = [["Factor", "Value", "Unit", "Effect (%)"]]
                
                for factor in data['environmental_factors']:
                    env_data.append([
                        factor.get('factor', 'N/A'),
                        f"{factor.get('value', 0):.1f}",
                        factor.get('unit', ''),
                        f"{factor.get('effect', 0):.2f}"
                    ])
                
                env_table = Table(env_data)
                env_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (3, 0), colors.lightblue),
                    ('TEXTCOLOR', (0, 0), (3, 0), colors.whitesmoke),
                    ('ALIGN', (0, 0), (3, 0), 'CENTER'),
                    ('FONTNAME', (0, 0), (3, 0), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (3, 0), 12),
                    ('BOTTOMPADDING', (0, 0), (3, 0), 6),
                    ('BACKGROUND', (0, 1), (3, -1), colors.white),
                    ('GRID', (0, 0), (3, -1), 1, colors.black),
                    ('ALIGN', (1, 1), (3, -1), 'CENTER'),
                    ('ALIGN', (0, 0), (0, -1), 'LEFT')
                ]))
                
                story.append(env_table)
                story.append(Spacer(1, 24))
            
            # Theory section
            story.append(Paragraph("Instrument Transformer Theory", heading_style))
            story.append(Spacer(1, 12))
            
            # CT theory
            story.append(Paragraph("Current Transformer Saturation", subheading_style))
            story.append(Paragraph(
                "Current transformers operate on the principle of electromagnetic induction. "
                "The knee point voltage is the point at which the CT core begins to saturate, "
                "reducing accuracy. A saturated CT may fail to properly reproduce the primary current "
                "waveform, leading to protection relay misoperation.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            # Accuracy class explanation
            story.append(Paragraph("Accuracy Class", subheading_style))
            story.append(Paragraph(
                "The accuracy class (e.g., 0.5, 1.0, 5P10) defines the maximum allowable error. "
                "For measurement CTs, the number represents the percentage error. For protection CTs, "
                "5P10 means 5% error at rated current and accuracy up to 10 times rated current.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            # VT theory
            story.append(Paragraph("Voltage Transformer Burden", subheading_style))
            story.append(Paragraph(
                "The burden of a voltage transformer represents the load connected to its secondary. "
                "VTs should operate within their rated burden range for optimal accuracy. "
                "Under-burdened VTs may experience ferroresonance, while over-burdened VTs have increased errors.",
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
            
    def generate_saturation_curve(self, data, filepath):
        """Generate a CT saturation curve chart and save to file
        
        Args:
            data: Dictionary with CT data
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Extract data
            knee_point = data.get('knee_point_voltage', 0)
            secondary_current = data.get('secondary_current', 5)
            saturation_curve = data.get('saturation_curve', [])
            
            # Create figure
            plt.figure(figsize=(8, 6))
            
            if saturation_curve and len(saturation_curve) > 0:
                # Plot using provided curve data
                voltages = [point['voltage'] for point in saturation_curve]
                currents = [point['current'] for point in saturation_curve]
                plt.plot(voltages, currents, 'b-', linewidth=2)
            else:
                # Generate a curve based on knee point and secondary current
                if knee_point > 0:
                    # Generate points for the curve
                    v_points = np.linspace(0, knee_point * 2, 100)
                    i_points = []
                    
                    for v in v_points:
                        if v <= knee_point:
                            # Linear region
                            i = v / (0.1 * secondary_current) if secondary_current > 0 else 0
                        else:
                            # Saturation region
                            excess = v - knee_point
                            i = secondary_current + 2 * np.power(excess / max(0.001, knee_point), 0.3) * secondary_current
                        i_points.append(i)
                    
                    plt.plot(v_points, i_points, 'b-', linewidth=2)
            
            # Add knee point marker if available
            if knee_point > 0:
                plt.plot(knee_point, secondary_current, 'ro', markersize=8)
                plt.annotate(f"Knee Point: {knee_point:.1f}V", 
                           xy=(knee_point, secondary_current),
                           xytext=(knee_point * 0.6, secondary_current * 1.5),
                           arrowprops=dict(facecolor='red', shrink=0.05))
            
            # Set labels and title
            plt.title('Current Transformer Saturation Curve')
            plt.xlabel('Voltage (V)')
            plt.ylabel('Current (A)')
            plt.grid(True)
            
            # Add CT ratio and knee point info
            ct_ratio = data.get('ct_ratio', 'N/A')
            plt.figtext(0.5, 0.01, 
                      f"CT Ratio: {ct_ratio} | Knee Point: {knee_point:.1f}V | "
                      f"Accuracy Class: {data.get('accuracy_class', 'N/A')}", 
                      ha="center", fontsize=9, bbox={"facecolor":"lightblue", "alpha":0.2, "pad":5})
            
            # Save the figure
            plt.tight_layout(rect=[0, 0.03, 1, 0.97])
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating saturation curve: {e}")
            # Make sure to close figures on error
            plt.close('all')
            return False
    
    def generate_harmonics_chart(self, data, filepath):
        """Generate a harmonics bar chart and save to file
        
        Args:
            data: Dictionary with harmonics data
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Extract harmonics data
            harmonics = data.get('harmonics', {})
            
            if not harmonics:
                return False
                
            # Create labels and values
            labels = []
            values = []
            
            for order in ['1st', '3rd', '5th', '7th']:
                if order in harmonics:
                    labels.append(order)
                    values.append(harmonics[order])
            
            # Create figure
            plt.figure(figsize=(8, 5))
            
            # Create bar chart
            bars = plt.bar(labels, values, color=['blue', 'red', 'green', 'orange'])
            
            # Add value labels on top of bars
            for bar in bars:
                height = bar.get_height()
                plt.text(bar.get_x() + bar.get_width()/2., height + 1,
                        f'{height:.1f}%',
                        ha='center', va='bottom', fontsize=9)
            
            # Set labels and title
            plt.title('Harmonic Content Analysis')
            plt.ylabel('Amplitude (%)')
            plt.ylim(0, max(values) * 1.2 if values else 100)
            
            # Add grid for y-axis only
            plt.grid(axis='y', linestyle='--', alpha=0.7)
            
            # Add CT saturation info
            saturation_status = data.get('saturation_status', 'N/A')
            saturation_factor = data.get('saturation_factor', 0)
            
            plt.figtext(0.5, 0.01, 
                      f"Saturation Status: {saturation_status} | "
                      f"Saturation Factor: {saturation_factor:.2f}", 
                      ha="center", fontsize=9, bbox={"facecolor":"lightblue", "alpha":0.2, "pad":5})
            
            # Save the figure
            plt.tight_layout(rect=[0, 0.03, 1, 0.97])
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating harmonics chart: {e}")
            # Make sure to close figures on error
            plt.close('all')
            return False
