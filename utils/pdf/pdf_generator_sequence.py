from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
import os
from datetime import datetime
import gc
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import io

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="sequence_pdf")

class SequencePdfGenerator:
    """Handles PDF generation for sequence component calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for sequence component calculations
        
        Args:
            data: Dictionary containing sequence component data
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
            
            # Create caption style
            caption_style = ParagraphStyle(
                'Caption',
                parent=styles['Normal'],
                fontSize=9,
                alignment=1,  # Center alignment
                textColor=colors.darkgrey,
                italics=True
            )
            
            # Create content
            story = []
            
            # Add title
            story.append(Paragraph("Sequence Component Analysis Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Add fault type if available
            if 'fault_type' in data and data['fault_type']:
                if data['fault_type'] != "Custom":
                    story.append(Paragraph(f"Analyzed System: {data['fault_type']}", styles['Heading2']))
                    story.append(Spacer(1, 12))
            
            # Three-Phase Values section
            story.append(Paragraph("Three-Phase Values", heading_style))
            story.append(Spacer(1, 12))
            
            # Create phase values table
            phase_data = [
                ["Phase", "Voltage (V)", "Angle (°)", "Current (A)", "Angle (°)"],
                ["A", f"{data.get('voltage_a', 0):.1f}", f"{data.get('voltage_angle_a', 0):.1f}", 
                 f"{data.get('current_a', 0):.1f}", f"{data.get('current_angle_a', 0):.1f}"],
                ["B", f"{data.get('voltage_b', 0):.1f}", f"{data.get('voltage_angle_b', 0):.1f}", 
                 f"{data.get('current_b', 0):.1f}", f"{data.get('current_angle_b', 0):.1f}"],
                ["C", f"{data.get('voltage_c', 0):.1f}", f"{data.get('voltage_angle_c', 0):.1f}",
                 f"{data.get('current_c', 0):.1f}", f"{data.get('current_angle_c', 0):.1f}"]
            ]
            
            # Create and style the table
            phase_table = Table(phase_data)
            phase_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (4, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (4, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (4, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (4, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (4, 0), 12),
                ('BOTTOMPADDING', (0, 0), (4, 0), 6),
                ('BACKGROUND', (0, 1), (0, 3), colors.lightblue),
                ('BACKGROUND', (0, 1), (4, 3), colors.white),
                ('GRID', (0, 0), (4, 3), 1, colors.black),
                ('FONTNAME', (0, 1), (0, 3), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (0, 3), 'CENTER'),
                ('ALIGN', (1, 0), (4, 3), 'CENTER')
            ]))
            
            story.append(phase_table)
            story.append(Spacer(1, 24))
            
            # Create a temporary image directly in memory instead of using a file
            phasor_image_data = self._generate_phasor_diagram_bytes(data)
            
            # Add phasor diagram if image data was generated successfully
            if phasor_image_data:
                try:
                    # Add phasor diagram section
                    story.append(Paragraph("Phasor Diagram", heading_style))
                    story.append(Spacer(1, 12))
                    
                    # Create image directly from bytes
                    img = Image(phasor_image_data)
                    
                    # Set appropriate dimensions
                    available_width = doc.width * 0.7  # Use 70% of available width
                    img.drawWidth = available_width
                    img.drawHeight = available_width  # Keep it square since we're using polar coordinates
                    
                    story.append(img)
                    story.append(Spacer(1, 6))
                    story.append(Paragraph("Voltage Phasors Diagram", caption_style))
                    story.append(Spacer(1, 24))
                except Exception as img_error:
                    logger.error(f"Error processing image: {img_error}")
                    import traceback
                    logger.error(traceback.format_exc())
                    story.append(Paragraph("Phasor Diagram (Not Available)", heading_style))
                    story.append(Paragraph("Error processing the phasor diagram image.", normal_style))
                    story.append(Spacer(1, 24))
            else:
                # If image wasn't created, add a note instead
                story.append(Paragraph("Phasor Diagram (Not Available)", heading_style))
                story.append(Paragraph("The phasor diagram could not be generated.", normal_style))
                story.append(Spacer(1, 24))
            
            # Sequence Components section
            story.append(Paragraph("Sequence Components", heading_style))
            story.append(Spacer(1, 12))
            
            # Create sequence components table
            sequence_data = [
                ["Component", "Voltage (V)", "Angle (°)", "Current (A)", "Angle (°)"],
                ["Positive", f"{data.get('v_pos_mag', 0):.1f}", f"{data.get('v_pos_ang', 0):.1f}", 
                 f"{data.get('i_pos_mag', 0):.1f}", f"{data.get('i_pos_ang', 0):.1f}"],
                ["Negative", f"{data.get('v_neg_mag', 0):.1f}", f"{data.get('v_neg_ang', 0):.1f}", 
                 f"{data.get('i_neg_mag', 0):.1f}", f"{data.get('i_neg_ang', 0):.1f}"],
                ["Zero", f"{data.get('v_zero_mag', 0):.1f}", f"{data.get('v_zero_ang', 0):.1f}",
                 f"{data.get('i_zero_mag', 0):.1f}", f"{data.get('i_zero_ang', 0):.1f}"]
            ]
            
            # Create and style the table
            sequence_table = Table(sequence_data)
            sequence_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (4, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (4, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (4, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (4, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (4, 0), 12),
                ('BOTTOMPADDING', (0, 0), (4, 0), 6),
                ('BACKGROUND', (0, 1), (0, 3), colors.lightblue),
                ('BACKGROUND', (0, 1), (4, 3), colors.white),
                ('GRID', (0, 0), (4, 3), 1, colors.black),
                ('FONTNAME', (0, 1), (0, 3), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (0, 3), 'CENTER'),
                ('ALIGN', (1, 0), (4, 3), 'CENTER')
            ]))
            
            story.append(sequence_table)
            story.append(Spacer(1, 24))
            
            # System Analysis section
            story.append(Paragraph("System Analysis", heading_style))
            story.append(Spacer(1, 12))
            
            # Create system analysis table
            analysis_data = [
                ["Parameter", "Value"],
                ["Voltage Unbalance Factor", f"{data.get('v_unbalance', 0):.2f}%"],
                ["Current Unbalance Factor", f"{data.get('i_unbalance', 0):.2f}%"]
            ]
            
            # Add system status if available
            if 'system_status' in data and data['system_status']:
                analysis_data.append(["System Status", data['system_status']])
            
            # Add dominant issue if available
            if 'dominant_issue' in data and data['dominant_issue']:
                analysis_data.append(["Dominant Issue", data['dominant_issue']])
            
            # Add recommendation if available
            if 'recommendation' in data and data['recommendation']:
                analysis_data.append(["Recommendation", data['recommendation']])
            
            # Create and style the table
            analysis_table = Table(analysis_data)
            analysis_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (1, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (1, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (1, 0), 12),
                ('BOTTOMPADDING', (0, 0), (1, 0), 6),
                ('BACKGROUND', (0, 1), (0, -1), colors.lightblue),
                ('BACKGROUND', (0, 1), (1, -1), colors.white),
                ('GRID', (0, 0), (1, -1), 1, colors.black),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                ('ALIGN', (1, 0), (1, -1), 'LEFT')
            ]))
            
            story.append(analysis_table)
            story.append(Spacer(1, 24))
            
            # Theory section
            story.append(Paragraph("Sequence Component Theory", heading_style))
            story.append(Spacer(1, 12))
            
            # Basic explanation
            story.append(Paragraph("Sequence Component Analysis:", subheading_style))
            story.append(Paragraph(
                "Sequence components are a mathematical technique used to analyze unbalanced three-phase systems. " +
                "The method transforms the original three-phase system into three balanced systems: positive, negative, and zero sequence components.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            # Sequence component explanations
            story.append(Paragraph("Component Types:", subheading_style))
            story.append(Paragraph("• <b>Positive Sequence:</b> Represents the normal balanced three-phase component with positive phase rotation (A-B-C).", normal_style))
            story.append(Paragraph("• <b>Negative Sequence:</b> Represents unbalanced components with negative phase rotation (A-C-B).", normal_style))
            story.append(Paragraph("• <b>Zero Sequence:</b> Represents the in-phase component that exists only when there is current flow through neutral or ground.", normal_style))
            story.append(Spacer(1, 12))
            
            # Fault type diagnostics
            story.append(Paragraph("Fault Diagnostics:", subheading_style))
            story.append(Paragraph("Different fault types produce distinctive sequence component patterns:", normal_style))
            story.append(Spacer(1, 6))
            story.append(Paragraph("• <b>Balanced System:</b> Only positive sequence components are present.", normal_style))
            story.append(Paragraph("• <b>Single Line-to-Ground Fault:</b> All three sequence components have similar magnitudes.", normal_style))
            story.append(Paragraph("• <b>Line-to-Line Fault:</b> Positive and negative sequence components have similar magnitudes; zero sequence is minimal.", normal_style))
            story.append(Paragraph("• <b>Double Line-to-Ground Fault:</b> All three sequence components are present with significant values.", normal_style))
            story.append(Paragraph("• <b>Three-Phase Fault:</b> Only positive sequence present; others are minimal.", normal_style))
            story.append(Spacer(1, 12))
            
            # Unbalance factors
            story.append(Paragraph("Unbalance Factors:", subheading_style))
            story.append(Paragraph(
                "The voltage unbalance factor (VUF) is calculated as the ratio of negative sequence voltage to positive sequence voltage, expressed as a percentage. " +
                "Per IEEE standards, voltage unbalance should not exceed 2% for sensitive equipment and 5% in general.",
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
    
    def _generate_phasor_diagram_bytes(self, data):
        """Generate a phasor diagram for the voltage components directly as bytes
        
        Args:
            data: Dictionary containing sequence component data
            
        Returns:
            BytesIO: Image data as BytesIO object or None if generation failed
        """
        plt_created = False
        figure_created = False
        
        try:
            # Check for valid voltage values before attempting to create plot
            va_mag = data.get('voltage_a', 0)
            vb_mag = data.get('voltage_b', 0)
            vc_mag = data.get('voltage_c', 0)
            
            # Only proceed if we have real voltage values
            if va_mag <= 0 and vb_mag <= 0 and vc_mag <= 0:
                logger.warning("Cannot generate phasor diagram: all voltage magnitudes are zero")
                return None
            
            # Get max voltage for scaling - prevent division by zero
            max_voltage = max(va_mag, vb_mag, vc_mag, 1.0)
            
            # Make sure matplotlib is properly configured for non-interactive backends
            import matplotlib
            matplotlib.use('Agg')  # Set Agg backend which doesn't require a display
            import matplotlib.pyplot as plt
            
            plt_created = True
            
            # Close any existing figures to prevent resource leaks
            plt.close('all')
            
            # Create figure
            plt.figure(figsize=(8, 8))
            figure_created = True
            
            ax = plt.subplot(111, projection='polar')
            
            # Convert angles to radians
            va_ang = np.radians(data.get('voltage_angle_a', 0))
            vb_ang = np.radians(data.get('voltage_angle_b', 0))
            vc_ang = np.radians(data.get('voltage_angle_c', 0))
            
            # Draw vectors with error checking
            if va_mag > 0:
                ax.arrow(va_ang, 0, 0, va_mag, alpha=0.8, width=0.05, 
                         edgecolor='r', facecolor='r', lw=2, zorder=5, label='Va')
                
                # Add labels with magnitudes and angles - only if magnitude is significant
                if va_mag > max_voltage * 0.05:
                    ax.text(va_ang, va_mag + (max_voltage * 0.1), 
                            f"Va: {va_mag:.1f}V ∠{data.get('voltage_angle_a', 0):.1f}°", 
                            color='r', ha='center', va='center', fontweight='bold')
            
            if vb_mag > 0:
                ax.arrow(vb_ang, 0, 0, vb_mag, alpha=0.8, width=0.05, 
                         edgecolor='g', facecolor='g', lw=2, zorder=5, label='Vb')
                
                if vb_mag > max_voltage * 0.05:
                    ax.text(vb_ang, vb_mag + (max_voltage * 0.1), 
                            f"Vb: {vb_mag:.1f}V ∠{data.get('voltage_angle_b', 0):.1f}°", 
                            color='g', ha='center', va='center', fontweight='bold')
            
            if vc_mag > 0:
                ax.arrow(vc_ang, 0, 0, vc_mag, alpha=0.8, width=0.05, 
                         edgecolor='b', facecolor='b', lw=2, zorder=5, label='Vc')
                
                if vc_mag > max_voltage * 0.05:
                    ax.text(vc_ang, vc_mag + (max_voltage * 0.1), 
                            f"Vc: {vc_mag:.1f}V ∠{data.get('voltage_angle_c', 0):.1f}°", 
                            color='b', ha='center', va='center', fontweight='bold')
            
            # Set grid and limits
            ax.set_rmax(max_voltage * 1.2)
            ax.set_rticks([max_voltage * 0.25, max_voltage * 0.5, max_voltage * 0.75, max_voltage])
            ax.set_rlabel_position(0)
            ax.grid(True)
            
            # Add title
            plt.title("Three-Phase Voltage Phasors", fontsize=14)
            
            # Save the figure to a BytesIO object
            buf = io.BytesIO()
            plt.tight_layout()
            plt.savefig(buf, format='png', dpi=150, bbox_inches='tight')
            buf.seek(0)
            
            logger.info("Successfully generated phasor diagram in memory")
            
            return buf
            
        except Exception as e:
            logger.error(f"Error generating phasor diagram: {e}")
            import traceback
            logger.error(traceback.format_exc())
            return None
        
        finally:
            try:
                # Close all figures to prevent resource leaks
                if plt_created and figure_created:
                    import matplotlib.pyplot as plt
                    plt.close('all')
            except:
                pass
            
            # Force garbage collection
            import gc
            gc.collect()
    
    # Keep the original method for backward compatibility, but make it use the new in-memory method
    def _generate_phasor_diagram(self, data, filepath):
        """Generate a phasor diagram for the voltage components
        
        Args:
            data: Dictionary containing sequence component data
            filepath: Path to save the diagram image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Get image data in memory
            img_data = self._generate_phasor_diagram_bytes(data)
            if img_data is None:
                return False
                
            # Save the image data to a file
            with open(filepath, 'wb') as f:
                f.write(img_data.getvalue())
                
            # Verify the file was created and is readable
            if os.path.exists(filepath) and os.access(filepath, os.R_OK):
                logger.info(f"Successfully saved phasor diagram to {filepath}")
                return True
            else:
                logger.error(f"Could not verify created image at {filepath}")
                return False
                
        except Exception as e:
            logger.error(f"Error saving phasor diagram to file: {e}")
            return False
