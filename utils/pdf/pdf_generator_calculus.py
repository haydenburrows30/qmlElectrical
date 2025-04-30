from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from datetime import datetime
import gc
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import io

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="calculus_pdf")

class CalculusPdfGenerator:
    """Handles PDF generation for calculus calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for calculus calculations
        
        Args:
            data: Dictionary containing calculus data
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
            
            # Create formula style
            formula_style = ParagraphStyle(
                'Formula',
                parent=styles['Normal'],
                fontSize=12,
                alignment=1  # Center alignment
            )
            
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
            story.append(Paragraph("Calculus Analysis Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Function section
            story.append(Paragraph("Function Information", heading_style))
            story.append(Spacer(1, 12))
            
            # Create function info table
            function_data = [
                ["Parameter", "Value"],
                ["Function Type", data.get('function_type', '')],
                ["Parameter A", f"{data.get('parameter_a', 0):.2f} ({data.get('parameter_a_name', 'A')})"],
            ]
            
            # Add parameter B if relevant
            if data.get('show_parameter_b', True):
                function_data.append(["Parameter B", f"{data.get('parameter_b', 0):.2f} ({data.get('parameter_b_name', 'B')})"])
            
            # Create and style the table
            function_table = Table(function_data)
            function_table.setStyle(TableStyle([
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
                ('ALIGN', (1, 0), (1, -1), 'RIGHT')
            ]))
            
            story.append(function_table)
            story.append(Spacer(1, 24))
            
            # Formulas section
            story.append(Paragraph("Mathematical Formulas", heading_style))
            story.append(Spacer(1, 12))
            
            # Function formula
            story.append(Paragraph("Original Function:", subheading_style))
            story.append(Paragraph(f"f(x) = {data.get('function_formula', '')}", formula_style))
            story.append(Spacer(1, 12))
            
            # Derivative formula
            story.append(Paragraph("Derivative:", subheading_style))
            story.append(Paragraph(f"f'(x) = {data.get('derivative_formula', '')}", formula_style))
            story.append(Spacer(1, 12))
            
            # Integral formula
            story.append(Paragraph("Integral:", subheading_style))
            story.append(Paragraph(f"∫f(x)dx = {data.get('integral_formula', '')}", formula_style))
            story.append(Spacer(1, 24))
            
            # Generate function visualization chart in memory
            chart_image_data = self._generate_function_chart_bytes(data)
            
            # Add visualization if image was generated successfully
            if chart_image_data:
                try:
                    # Add visualization section
                    story.append(Paragraph("Function Visualization", heading_style))
                    story.append(Spacer(1, 12))
                    
                    # Create image from the bytes data
                    img = Image(chart_image_data)
                    
                    # Set appropriate dimensions
                    available_width = doc.width * 0.9  # Use 90% of available width
                    img.drawWidth = available_width
                    img.drawHeight = available_width * 0.6  # Maintain aspect ratio
                    
                    story.append(img)
                    story.append(Spacer(1, 6))
                    story.append(Paragraph("Function, Derivative, and Integral Visualization", caption_style))
                    story.append(Spacer(1, 24))
                except Exception as e:
                    logger.error(f"Error including chart in PDF: {e}")
                    story.append(Paragraph("Chart visualization could not be included", normal_style))
                    story.append(Spacer(1, 24))
            
            # Application section
            story.append(Paragraph("Applications in Electrical Engineering", heading_style))
            story.append(Spacer(1, 12))
            
            # Split the application examples into paragraphs
            app_examples = data.get('application_example', '').split('\n\n')
            
            # Main application
            if len(app_examples) > 0:
                story.append(Paragraph(app_examples[0], normal_style))
                story.append(Spacer(1, 12))
            
            # Differentiation application
            if len(app_examples) > 1:
                story.append(Paragraph("Differentiation Application:", subheading_style))
                story.append(Paragraph(app_examples[1], normal_style))
                story.append(Spacer(1, 12))
            
            # Integration application
            if len(app_examples) > 2:
                story.append(Paragraph("Integration Application:", subheading_style))
                story.append(Paragraph(app_examples[2], normal_style))
                story.append(Spacer(1, 12))
            
            # Theory section
            story.append(Paragraph("Calculus Theory", heading_style))
            story.append(Spacer(1, 12))
            
            # Differentiation theory
            story.append(Paragraph("Differentiation:", subheading_style))
            story.append(Paragraph(
                "Differentiation is the process of finding the derivative of a function. " +
                "The derivative measures the rate of change of a function with respect to a variable. " +
                "In electrical engineering, derivatives are used to analyze transient behavior, " +
                "find rates of change in voltage and current, and in control system analysis.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            # Integration theory
            story.append(Paragraph("Integration:", subheading_style))
            story.append(Paragraph(
                "Integration is the process of finding the integral of a function. " +
                "The integral represents the area under a curve and is used to find total values " +
                "when given a rate of change. In electrical engineering, integration is used to " +
                "calculate total energy, charge, and for finding average values of waveforms.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            # Function-specific theory
            story.append(Paragraph(f"{data.get('function_type', '')} Functions:", subheading_style))
            
            function_theories = {
                "Sine": "Sine functions are fundamental in AC circuit analysis, representing voltage and current waveforms. " +
                        "The derivative of sine is cosine, and the integral of sine is negative cosine.",
                
                "Polynomial": "Polynomial functions model many electrical relationships, like the relationship between distance, " +
                             "velocity, and acceleration. The derivative reduces the power by 1, and the integral increases it by 1.",
                
                "Exponential": "Exponential functions model growth and decay, such as capacitor charging and discharging. " +
                              "The unique property of e^x is that its derivative is itself.",
                
                "Power": "Power functions model relationships where one quantity varies as a power of another, " +
                        "such as in semiconductors where current may vary as a power of voltage.",
                
                "Gaussian": "Gaussian functions model normal distributions and signal pulses. " +
                           "They're used in statistical analysis of noise and in signal processing."
            }
            
            function_theory = function_theories.get(data.get('function_type', ''), "")
            story.append(Paragraph(function_theory, normal_style))
            
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
    
    def _generate_function_chart_bytes(self, data):
        """Generate a visualization chart for the function, derivative, and integral in memory
        
        Args:
            data: Dictionary containing function data
            
        Returns:
            BytesIO: Image data as BytesIO object or None if generation failed
        """
        plt_created = False
        figure_created = False
        
        try:
            # Get data from the dictionary
            x_values = data.get('x_values', [])
            function_values = data.get('function_values', [])
            derivative_values = data.get('derivative_values', [])
            integral_values = data.get('integral_values', [])
            
            if not x_values or not function_values:
                logger.error("Missing data for chart generation")
                return None
            
            # Make sure matplotlib is properly configured for non-interactive backends
            import matplotlib
            matplotlib.use('Agg')  # Set Agg backend which doesn't require a display
            import matplotlib.pyplot as plt
            
            plt_created = True
            
            # Close any existing figures to prevent resource leaks
            plt.close('all')
            
            # Create figure
            plt.figure(figsize=(10, 6))
            figure_created = True
            
            # Plot function, derivative and integral
            plt.plot(x_values, function_values, 'b-', linewidth=2, label=f"f(x) = {data.get('function_formula', '')}")
            plt.plot(x_values, derivative_values, 'r-', linewidth=2, label=f"f'(x) = {data.get('derivative_formula', '')}")
            plt.plot(x_values, integral_values, 'g-', linewidth=2, label=f"∫f(x)dx = {data.get('integral_formula', '')}")
            
            # Add grid and legend
            plt.grid(True, linestyle='--', alpha=0.7)
            plt.legend(loc='upper left')
            
            # Add labels and title
            plt.xlabel('x')
            plt.ylabel('y')
            plt.title(f"{data.get('function_type', '')} Function Analysis")
            
            # Set x and y axis limits to reasonable values
            y_values = function_values + derivative_values + integral_values
            y_values = [y for y in y_values if abs(y) < 100]  # Filter out extreme values
            
            if y_values:
                y_min = min(y_values)
                y_max = max(y_values)
                y_range = y_max - y_min
                
                plt.xlim(min(x_values), max(x_values))
                plt.ylim(y_min - 0.1 * y_range, y_max + 0.1 * y_range)
            
            # Save the chart to BytesIO object
            buf = io.BytesIO()
            plt.tight_layout()
            plt.savefig(buf, format='png', dpi=150, bbox_inches='tight')
            buf.seek(0)
            
            logger.info("Successfully generated function chart in memory")
            
            return buf
            
        except Exception as e:
            logger.error(f"Error generating function chart: {e}")
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
