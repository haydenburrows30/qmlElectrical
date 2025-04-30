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
import matplotlib.pyplot as plt
import numpy as np

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="harmonics_pdf")

class HarmonicsPdfGenerator:
    """Handles PDF generation for harmonics analyzer"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for harmonic analysis
        
        Args:
            data: Dictionary containing harmonic analysis data
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
            story.append(Paragraph("Harmonic Analysis Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Harmonic components section
            story.append(Paragraph("Harmonic Components", heading_style))
            story.append(Spacer(1, 12))
            
            # Create harmonics table
            harmonics_data = [
                ["Order", "Magnitude (%)", "Phase (degrees)"]
            ]
            
            # Add harmonic data
            harmonic_orders = data.get('harmonic_orders', [1, 3, 5, 7, 11, 13])
            individual_distortion = data.get('individual_distortion', [])
            harmonic_phases = data.get('harmonic_phases', [])
            
            for i, order in enumerate(harmonic_orders):
                if i < len(individual_distortion) and i < len(harmonic_phases):
                    harmonics_data.append([
                        order,
                        f"{individual_distortion[i]:.2f}",
                        f"{harmonic_phases[i]:.2f}"
                    ])
            
            # Create and style the harmonic components table
            harmonics_table = Table(harmonics_data)
            harmonics_table.setStyle(TableStyle([
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
                ('ALIGN', (1, 0), (2, -1), 'CENTER')
            ]))
            
            story.append(harmonics_table)
            story.append(Spacer(1, 24))
            
            # Analysis results section
            story.append(Paragraph("Analysis Results", heading_style))
            story.append(Spacer(1, 12))
            
            # Create results table
            results_data = [
                ["Parameter", "Value"],
                ["Total Harmonic Distortion (THD)", f"{data.get('thd', 0):.2f}%"],
                ["Crest Factor", f"{data.get('crest_factor', 0):.2f}"],
                ["Form Factor", f"{data.get('form_factor', 0):.2f}"]
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
            
            # Add waveform chart if image path is provided
            waveform_image_path = data.get('waveform_image_path', '')
            if waveform_image_path and os.path.exists(waveform_image_path):
                story.append(Paragraph("Waveform Visualization", heading_style))
                story.append(Spacer(1, 12))
                
                # Get the image dimensions to maintain aspect ratio
                from PIL import Image as PILImage
                with PILImage.open(waveform_image_path) as img:
                    orig_width, orig_height = img.size
                
                # Calculate the aspect ratio
                aspect_ratio = orig_height / orig_width
                
                # Calculate appropriate image width based on available page width
                available_width = doc.width * 0.95  # Use 95% of available width
                
                # Set the image width and calculate height to maintain aspect ratio
                img = Image(waveform_image_path)
                img.drawWidth = available_width
                img.drawHeight = available_width * aspect_ratio
                
                # Add the image
                story.append(img)
                story.append(Spacer(1, 12))
                
                # Add image caption
                story.append(Paragraph(
                    "Figure 1: Waveform with Harmonic Components",
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Add harmonics spectrum chart if image path is provided
            spectrum_image_path = data.get('spectrum_image_path', '')
            if spectrum_image_path and os.path.exists(spectrum_image_path):
                story.append(Paragraph("Harmonic Spectrum", heading_style))
                story.append(Spacer(1, 12))
                
                # Get the image dimensions to maintain aspect ratio
                from PIL import Image as PILImage
                with PILImage.open(spectrum_image_path) as img:
                    orig_width, orig_height = img.size
                
                # Calculate the aspect ratio
                aspect_ratio = orig_height / orig_width
                
                # Calculate appropriate image width based on available page width
                available_width = doc.width * 0.95  # Use 95% of available width
                
                # Set the image width and calculate height to maintain aspect ratio
                img = Image(spectrum_image_path)
                img.drawWidth = available_width
                img.drawHeight = available_width * aspect_ratio
                
                # Add the image
                story.append(img)
                story.append(Spacer(1, 12))
                
                # Add image caption
                story.append(Paragraph(
                    "Figure 2: Harmonic Spectrum Analysis",
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Add explanation section
            story.append(Paragraph("Harmonic Analysis Explanation", heading_style))
            story.append(Spacer(1, 12))
            
            story.append(Paragraph("Total Harmonic Distortion (THD)", subheading_style))
            story.append(Paragraph(
                "Total Harmonic Distortion (THD) is a measurement of the harmonic distortion present in a signal "
                "and is defined as the ratio of the sum of the powers of all harmonic components to the power of the fundamental frequency. "
                "In power systems, lower THD values indicate a cleaner sine wave with fewer harmonics.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            story.append(Paragraph("Crest Factor", subheading_style))
            story.append(Paragraph(
                "The Crest Factor is the ratio of the peak value to the RMS value of a waveform. "
                "For a pure sine wave, the crest factor is √2 ≈ 1.414. "
                "Higher crest factors indicate waveforms with high peaks relative to their RMS value.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            story.append(Paragraph("Form Factor", subheading_style))
            story.append(Paragraph(
                "The Form Factor is the ratio of the RMS value to the average absolute value of a waveform. "
                "For a pure sine wave, the form factor is π/(2√2) ≈ 1.11. "
                "This factor helps characterize the shape of a periodic waveform.",
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
    
    def generate_waveform_chart(self, data, filepath):
        """Generate a waveform chart and save to file
        
        Args:
            data: Dictionary with waveform data
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Extract waveform data
            waveform_points = data.get('waveform_points', [])
            fundamental_points = data.get('fundamental_points', [])
            show_fundamental = data.get('show_fundamental', False)
            
            # Create figure
            plt.figure(figsize=(10, 6))
            
            # Convert QPointF to arrays if needed
            if waveform_points:
                # Check if we have QPointF objects or simple lists
                if hasattr(waveform_points[0], 'x') and hasattr(waveform_points[0], 'y'):
                    # Extract x and y coordinates from QPointF objects
                    x_values = [point.x() for point in waveform_points]
                    y_values = [point.y() for point in waveform_points]
                else:
                    # Assume we have [x, y] pairs
                    x_values = [point[0] for point in waveform_points]
                    y_values = [point[1] for point in waveform_points]
                
                # Plot the waveform
                plt.plot(x_values, y_values, 'b-', linewidth=2, label='Combined Waveform')
            
            # Plot fundamental if requested
            if show_fundamental and fundamental_points:
                if hasattr(fundamental_points[0], 'x') and hasattr(fundamental_points[0], 'y'):
                    # Extract x and y coordinates from QPointF objects
                    x_fund = [point.x() for point in fundamental_points]
                    y_fund = [point.y() for point in fundamental_points]
                else:
                    # Assume we have [x, y] pairs
                    x_fund = [point[0] for point in fundamental_points]
                    y_fund = [point[1] for point in fundamental_points]
                
                # Plot the fundamental
                plt.plot(x_fund, y_fund, 'r--', linewidth=1.5, label='Fundamental')
            
            # Set labels and title
            plt.title('Waveform Analysis')
            plt.xlabel('Angle (degrees)')
            plt.ylabel('Amplitude')
            
            # Add grid and legend
            plt.grid(True, alpha=0.3)
            plt.legend()
            
            # Set x-axis limits to show one complete cycle (0-360 degrees)
            plt.xlim(0, 360)
            
            # Add THD and other information as text
            thd = data.get('thd', 0.0)
            cf = data.get('crest_factor', 0.0)
            ff = data.get('form_factor', 0.0)
            plt.figtext(0.5, 0.01, 
                      f"THD: {thd:.2f}% | Crest Factor: {cf:.2f} | Form Factor: {ff:.2f}", 
                      ha="center", fontsize=9, bbox={"facecolor":"lightblue", "alpha":0.2, "pad":5})
            
            # Save the figure
            plt.tight_layout(rect=[0, 0.03, 1, 0.97])
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating waveform chart: {e}")
            # Make sure to close figures on error
            plt.close('all')
            return False
    
    def generate_spectrum_chart(self, data, filepath):
        """Generate a harmonic spectrum chart and save to file
        
        Args:
            data: Dictionary with harmonic spectrum data
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Extract harmonic data
            harmonic_orders = data.get('harmonic_orders', [1, 3, 5, 7, 11, 13])
            individual_distortion = data.get('individual_distortion', [])
            harmonic_phases = data.get('harmonic_phases', [])
            show_phases = data.get('show_phases', False)
            
            # Create figure
            plt.figure(figsize=(10, 6))
            
            # Bar positions
            bar_width = 0.35
            index = np.arange(len(harmonic_orders))
            
            # Plot magnitude bars
            bars = plt.bar(index, individual_distortion, bar_width, 
                         label='Magnitude (%)', color='blue', alpha=0.7)
            
            # Add value labels on top of bars
            for bar in bars:
                height = bar.get_height()
                plt.text(bar.get_x() + bar.get_width()/2., height + 1,
                        f'{height:.1f}%',
                        ha='center', va='bottom', fontsize=9)
            
            # Plot phase bars if requested
            if show_phases:
                phase_bars = plt.bar(index + bar_width, harmonic_phases, bar_width,
                                  label='Phase (degrees)', color='red', alpha=0.7)
                
                # Add value labels on top of phase bars
                for bar in phase_bars:
                    height = bar.get_height()
                    plt.text(bar.get_x() + bar.get_width()/2., height + 1,
                            f'{height:.1f}°',
                            ha='center', va='bottom', fontsize=9)
            
            # Set labels and title
            plt.title('Harmonic Spectrum')
            plt.xlabel('Harmonic Order')
            plt.ylabel('Magnitude (%)')
            
            # Set x-axis tick labels to harmonic orders
            plt.xticks(index + bar_width/2 if show_phases else index, harmonic_orders)
            
            # Add grid and legend
            plt.grid(True, axis='y', alpha=0.3)
            plt.legend()
            
            # Add THD as text
            thd = data.get('thd', 0.0)
            plt.figtext(0.5, 0.01, 
                      f"Total Harmonic Distortion (THD): {thd:.2f}%", 
                      ha="center", fontsize=9, bbox={"facecolor":"lightblue", "alpha":0.2, "pad":5})
            
            # Save the figure
            plt.tight_layout(rect=[0, 0.03, 1, 0.97])
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating spectrum chart: {e}")
            # Make sure to close figures on error
            plt.close('all')
            return False
