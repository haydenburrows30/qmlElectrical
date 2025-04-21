from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.platypus import Image
import os
from datetime import datetime

class PDFGenerator:
    def __init__(self):
        self.styles = getSampleStyleSheet()
        self.title_style = ParagraphStyle(
            'CustomTitle',
            parent=self.styles['Heading1'],
            fontSize=16,
            spaceAfter=30
        )
        self.section_style = ParagraphStyle(
            'SectionTitle',
            parent=self.styles['Heading2'],
            fontSize=12,
            spaceAfter=12
        )
        
    def generate_protection_report(self, data, filepath):
        """Generate a protection requirements report
        
        Args:
            data: Dictionary containing protection requirements data
            filepath: Output PDF filename - should be provided by FileSaver
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Ensure filepath ends with .pdf
            if not filepath.lower().endswith('.pdf'):
                filepath += '.pdf'
                
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
            normal_style = styles["Normal"]
            
            # Create content
            story = []
            
            # Add title
            story.append(Paragraph("Protection Requirements Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Debug information - print what data was received
            print(f"Protection report data received: {type(data)}")
            if isinstance(data, dict):
                print(f"Keys in data: {data.keys()}")
            
            # Convert QJSValue data to Python dictionary if needed
            if hasattr(data, 'toVariant'):
                data = data.toVariant()
            
            # System parameters section
            story.append(Paragraph("System Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Extract system parameters
            if isinstance(data, dict) and 'generator' in data and 'transformer' in data and 'line' in data:
                # Get generator data
                generator = data.get('generator', {})
                transformer = data.get('transformer', {})
                line = data.get('line', {})
                
                # Create system parameters table
                system_data = [
                    ["Parameter", "Value"],
                    ["Wind Turbine Rating", f"{generator.get('power', 'N/A')} kW"],
                    ["Wind Turbine Output Current", f"{generator.get('current', 'N/A')} A"],
                    ["Transformer Rating", f"{transformer.get('rating', 'N/A')} kVA"],
                    ["Transformer Voltage", f"{transformer.get('voltage', 'N/A')}"],
                    ["Fault Current HV", f"{transformer.get('fault_current', 'N/A')} kA"],
                    ["Ground Fault Current", f"{transformer.get('ground_fault', 'N/A')} kA"],
                    ["Line Length", f"{line.get('length', 'N/A')} km"],
                    ["Line Voltage Drop", f"{line.get('voltage_drop', 'N/A')} %"]
                ]
                
                # Create system table
                system_table = Table(system_data)
                system_table.setStyle(TableStyle([
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
                
                story.append(system_table)
                story.append(Spacer(1, 24))
                
                # Protection requirements section
                story.append(Paragraph("Protection Requirements", heading_style))
                story.append(Spacer(1, 12))
                
                # Generator protection
                story.append(Paragraph("Generator Protection (400V)", styles["Heading2"]))
                story.append(Spacer(1, 6))
                
                generator_protection = [
                    ["Protection", "Setting/Value"],
                    ["Overcurrent Pickup", f"{generator.get('overcurrent_pickup', 'N/A')} A ({generator.get('ct_ratio', 'N/A')})"],
                    ["Under/Over Voltage", f"{generator.get('voltage_range', 'N/A')}"],
                    ["Under/Over Frequency", f"{generator.get('frequency_range', 'N/A')}"],
                    ["Earth Fault Setting", f"{generator.get('earth_fault', 'N/A')}"],
                    ["Anti-Islanding", f"{generator.get('anti_islanding', 'N/A')}"]
                ]
                
                generator_table = Table(generator_protection, colWidths=[200, 300])
                generator_table.setStyle(TableStyle([
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
                    ('VALIGN', (0, 0), (1, -1), 'TOP')
                ]))
                
                story.append(generator_table)
                story.append(Spacer(1, 12))
                
                # Transformer protection
                story.append(Paragraph("Transformer Protection (11kV)", styles["Heading2"]))
                story.append(Spacer(1, 6))
                
                transformer_protection = [
                    ["Protection", "Setting/Value"],
                    ["CT Ratio", f"{transformer.get('ct_ratio', 'N/A')}"],
                    ["Relay Pickup Current", f"{transformer.get('relay_pickup_current', 'N/A')} A"],
                    ["Time-Current Curve", f"{transformer.get('relay_curve_type', 'N/A')}"],
                    ["Time Dial Setting", f"{transformer.get('time_dial', 'N/A')}"],
                    ["Instantaneous Pickup", f"{transformer.get('instantaneous_pickup', 'N/A')} A"],
                    ["Differential Protection", f"Slope: {transformer.get('differential_slope', 'N/A')}%"],
                    ["Reverse Power Protection", f"{transformer.get('reverse_power', 'N/A')}"]
                ]
                
                transformer_table = Table(transformer_protection, colWidths=[200, 300])
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
                    ('VALIGN', (0, 0), (1, -1), 'TOP')
                ]))
                
                story.append(transformer_table)
                story.append(Spacer(1, 12))
                
                # Line protection
                story.append(Paragraph("Line Protection Requirements", styles["Heading2"]))
                story.append(Spacer(1, 6))
                
                line_protection = [
                    ["Protection", "Setting/Value"],
                    ["Fault Current at 11kV", f"{line.get('fault_current', 'N/A')} kA"],
                    ["Minimum Cable Size", f"{line.get('cable_size', 'N/A')}"],
                    ["Distance Protection", f"{'Required' if line.get('length', 0) > 10 else 'Not Required'}"],
                    ["Auto-Reclosure", "Single-shot"]
                ]
                
                line_table = Table(line_protection, colWidths=[200, 300])
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
                    ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                    ('VALIGN', (0, 0), (1, -1), 'TOP')
                ]))
                
                story.append(line_table)
                story.append(Spacer(1, 12))
                
                # G99 Requirements
                story.append(Paragraph("G99 Connection Requirements", styles["Heading2"]))
                story.append(Spacer(1, 6))
                
                g99_requirements = [
                    ["Requirement", "Setting"],
                    ["Frequency Range", "47.5Hz - 52Hz"],
                    ["Voltage Range", "-10% to +10% of nominal"],
                    ["Power Factor Control", "0.95 lagging to 0.95 leading"],
                    ["LVRT Capability", "Required"],
                    ["RoCoF Protection", "1Hz/s"],
                    ["Vector Shift Protection", "12 degrees"]
                ]
                
                g99_table = Table(g99_requirements, colWidths=[200, 300])
                g99_table.setStyle(TableStyle([
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
                    ('VALIGN', (0, 0), (1, -1), 'TOP')
                ]))
                
                story.append(g99_table)
                
                # Add protection settings from data if available
                if 'protection_settings' in data:
                    story.append(Spacer(1, 24))
                    story.append(Paragraph("Protection Relay Settings", heading_style))
                    story.append(Spacer(1, 12))
                    
                    # Voltage protection settings
                    if 'voltage' in data['protection_settings']:
                        story.append(Paragraph("Voltage Protection Settings", styles["Heading2"]))
                        story.append(Spacer(1, 6))
                        
                        voltage_settings = [["Type", "Stage", "Setting", "Time"]]
                        for setting in data['protection_settings']['voltage']:
                            voltage_settings.append([
                                setting.get('type', 'N/A'),
                                setting.get('stage', 'N/A'),
                                setting.get('setting', 'N/A'),
                                setting.get('time', 'N/A')
                            ])
                        
                        voltage_table = Table(voltage_settings, colWidths=[100, 80, 200, 100])
                        voltage_table.setStyle(TableStyle([
                            ('BACKGROUND', (0, 0), (3, 0), colors.lightblue),
                            ('TEXTCOLOR', (0, 0), (3, 0), colors.whitesmoke),
                            ('ALIGN', (0, 0), (3, 0), 'CENTER'),
                            ('FONTNAME', (0, 0), (3, 0), 'Helvetica-Bold'),
                            ('FONTSIZE', (0, 0), (3, 0), 12),
                            ('BOTTOMPADDING', (0, 0), (3, 0), 6),
                            ('BACKGROUND', (0, 1), (3, -1), colors.white),
                            ('GRID', (0, 0), (3, -1), 1, colors.black),
                            ('ALIGN', (0, 0), (3, -1), 'CENTER'),
                            ('VALIGN', (0, 0), (3, -1), 'TOP')
                        ]))
                        
                        story.append(voltage_table)
                        story.append(Spacer(1, 12))
                    
                    # Frequency protection settings
                    if 'frequency' in data['protection_settings']:
                        story.append(Paragraph("Frequency Protection Settings", styles["Heading2"]))
                        story.append(Spacer(1, 6))
                        
                        frequency_settings = [["Type", "Stage", "Setting", "Time"]]
                        for setting in data['protection_settings']['frequency']:
                            frequency_settings.append([
                                setting.get('type', 'N/A'),
                                setting.get('stage', 'N/A'),
                                setting.get('setting', 'N/A'),
                                setting.get('time', 'N/A')
                            ])
                        
                        frequency_table = Table(frequency_settings, colWidths=[100, 80, 200, 100])
                        frequency_table.setStyle(TableStyle([
                            ('BACKGROUND', (0, 0), (3, 0), colors.lightblue),
                            ('TEXTCOLOR', (0, 0), (3, 0), colors.whitesmoke),
                            ('ALIGN', (0, 0), (3, 0), 'CENTER'),
                            ('FONTNAME', (0, 0), (3, 0), 'Helvetica-Bold'),
                            ('FONTSIZE', (0, 0), (3, 0), 12),
                            ('BOTTOMPADDING', (0, 0), (3, 0), 6),
                            ('BACKGROUND', (0, 1), (3, -1), colors.white),
                            ('GRID', (0, 0), (3, -1), 1, colors.black),
                            ('ALIGN', (0, 0), (3, -1), 'CENTER'),
                            ('VALIGN', (0, 0), (3, -1), 'TOP')
                        ]))
                        
                        story.append(frequency_table)
                
            else:
                # If we don't have the expected data structure, show a simple message
                story.append(Paragraph("No detailed protection data available. Please check the input parameters.", normal_style))
            
            # Build PDF
            doc.build(story)
            
            print(f"Protection report generated successfully at {filepath}")
            return True
            
        except Exception as e:
            print(f"Error generating protection report: {e}")
            import traceback
            traceback.print_exc()
            return False

    def generate_transformer_report(self, data, filepath):
        """Generate a PDF report for transformer-line calculations
        
        Args:
            data: Dictionary containing transformer-line calculation data
            filepath: Path to save the PDF report - should be provided by FileSaver
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Ensure filepath ends with .pdf
            if not filepath.lower().endswith('.pdf'):
                filepath += '.pdf'
                
            # Create PDF document
            doc = SimpleDocTemplate(
                filepath,
                pagesize=A4,
                rightMargin=72,
                leftMargin=72,
                topMargin=72,
                bottomMargin=72
            )
            
            # Create content
            styles = getSampleStyleSheet()
            title_style = styles["Title"]
            heading_style = styles["Heading1"]
            normal_style = styles["Normal"]
            
            # Create content list
            content = []
            
            # Add title
            content.append(Paragraph("Transformer-Line Analysis Report", title_style))
            content.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            content.append(Paragraph(f"Generated: {timestamp}", normal_style))
            content.append(Spacer(1, 24))
            
            # Transformer parameters section
            content.append(Paragraph("Transformer Parameters", heading_style))
            transformer_data = [
                ["Parameter", "Value"],
                ["Rating", f"{data.get('transformer_rating', 'N/A')} kVA"],
                ["HV Voltage", f"{data.get('transformer_hv_voltage', 'N/A')} V"],
                ["LV Voltage", f"{data.get('transformer_lv_voltage', 'N/A')} V"],
                ["Impedance", f"{data.get('transformer_impedance', 'N/A')} %"],
                ["X/R Ratio", f"{data.get('transformer_xr_ratio', 'N/A')}"],
                ["Transformer Z", f"{data.get('transformer_z', 'N/A'):.3f} Ω"],
                ["Transformer R", f"{data.get('transformer_r', 'N/A'):.3f} Ω"],
                ["Transformer X", f"{data.get('transformer_x', 'N/A'):.3f} Ω"]
            ]
            
            # Create transformer table
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
            
            content.append(transformer_table)
            content.append(Spacer(1, 24))
            
            # Line parameters section
            content.append(Paragraph("Line Parameters", heading_style))
            line_data = [
                ["Parameter", "Value"],
                ["Length", f"{data.get('line_length', 'N/A')} km"],
                ["Resistance/km", f"{data.get('line_r', 'N/A')} Ω/km"],
                ["Reactance/km", f"{data.get('line_x', 'N/A')} Ω/km"],
                ["Total Impedance", f"{data.get('line_total_z', 'N/A'):.3f} Ω"],
                ["Voltage Drop", f"{data.get('voltage_drop', 'N/A'):.2f} %"],
                ["Unregulated Voltage", f"{data.get('unregulated_voltage', 'N/A'):.2f} kV"],
                ["Regulated Voltage", f"{data.get('regulated_voltage', 'N/A'):.2f} kV"]
            ]
            
            # Create line table
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
                ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                ('ALIGN', (1, 0), (1, -1), 'RIGHT')
            ]))
            
            content.append(line_table)
            content.append(Spacer(1, 24))
            
            # Fault analysis section
            content.append(Paragraph("Fault Analysis", heading_style))
            fault_data = [
                ["Parameter", "Value"],
                ["LV Fault Current", f"{data.get('fault_current_lv', 'N/A'):.2f} kA"],
                ["HV Fault Current", f"{data.get('fault_current_hv', 'N/A'):.2f} kA"],
                ["Single Line-to-Ground", f"{data.get('fault_current_slg', 'N/A'):.2f} kA"],
                ["Ground Fault Current", f"{data.get('ground_fault_current', 'N/A'):.3f} kA"]
            ]
            
            # Create fault table
            fault_table = Table(fault_data)
            fault_table.setStyle(TableStyle([
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
            
            content.append(fault_table)
            content.append(Spacer(1, 24))
            
            # Protection settings section
            content.append(Paragraph("Protection Settings", heading_style))
            protection_data = [
                ["Parameter", "Value"],
                ["CT Ratio", f"{data.get('ct_ratio', 'N/A')}"],
                ["Relay Pickup Current", f"{data.get('relay_pickup_current', 'N/A'):.2f} A"],
                ["Relay Curve Type", f"{data.get('relay_curve_type', 'N/A')}"],
                ["Time Dial Setting", f"{data.get('time_dial', 'N/A'):.2f}"]
            ]
            
            # Create protection table
            protection_table = Table(protection_data)
            protection_table.setStyle(TableStyle([
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
            
            content.append(protection_table)
            content.append(Spacer(1, 24))
            
            # Regulator details section
            if data.get('regulator_enabled', False):
                content.append(Paragraph("Voltage Regulator", heading_style))
                regulator_data = [
                    ["Parameter", "Value"],
                    ["Type", f"{data.get('regulator_type', 'N/A')}"],
                    ["Connection", f"{data.get('regulator_connection', 'N/A')}"],
                    ["Capacity", f"{data.get('regulator_three_phase_capacity', 'N/A'):.1f} kVA"],
                    ["Target Voltage", f"{data.get('regulator_target', 'N/A'):.2f} kV"],
                    ["Bandwidth", f"{data.get('regulator_bandwidth', 'N/A'):.1f} %"],
                    ["Range", f"±{data.get('regulator_range', 'N/A'):.1f} %"],
                    ["Tap Position", f"{data.get('tap_position', 'N/A')}"]
                ]
                
                # Create regulator table
                regulator_table = Table(regulator_data)
                regulator_table.setStyle(TableStyle([
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
                
                content.append(regulator_table)
                content.append(Spacer(1, 24))
            
            # Cable recommendations section
            content.append(Paragraph("Cable Recommendations", heading_style))
            cable_data = [
                ["Cable Type", "Recommended Size"],
                ["HV Cable", f"{data.get('recommended_hv_cable', 'N/A')}"],
                ["LV Cable", f"{data.get('recommended_lv_cable', 'N/A')}"]
            ]
            
            # Create cable table
            cable_table = Table(cable_data)
            cable_table.setStyle(TableStyle([
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
            
            content.append(cable_table)
            
            # Build the PDF
            doc.build(content)
            
            print(f"Transformer report generated successfully at {filepath}")
            return True
            
        except Exception as e:
            print(f"Error generating transformer report: {e}")
            import traceback
            traceback.print_exc()
            return False

    def generate_wind_turbine_report(self, data, filepath):
        """Generate a wind turbine analysis report
        
        Args:
            data: Dictionary containing wind turbine data
            filepath: Output PDF filename
            
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
            normal_style = styles["Normal"]
            subheading_style = styles["Heading2"]
            
            # Create content
            story = []
            
            # Add title
            story.append(Paragraph("Wind Turbine Analysis Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Input parameters section
            story.append(Paragraph("Input Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            input_data = [
                ["Parameter", "Value"],
                ["Blade Radius", f"{data.get('blade_radius', 0):.2f} m"],
                ["Air Density", f"{data.get('air_density', 0):.3f} kg/m³"],
                ["Wind Speed", f"{data.get('wind_speed', 0):.1f} m/s"],
                ["Power Coefficient", f"{data.get('power_coefficient', 0):.3f}"],
                ["Efficiency", f"{data.get('efficiency', 0) * 100:.1f}%"],
                ["Cut-in Speed", f"{data.get('cut_in_speed', 0):.1f} m/s"],
                ["Cut-out Speed", f"{data.get('cut_out_speed', 0):.1f} m/s"]
            ]
            
            # Create input parameters table
            input_table = Table(input_data)
            input_table.setStyle(TableStyle([
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
            
            story.append(input_table)
            story.append(Spacer(1, 24))
            
            # Results section
            story.append(Paragraph("Calculation Results", heading_style))
            story.append(Spacer(1, 12))
            
            results_data = [
                ["Parameter", "Value"],
                ["Swept Area", f"{data.get('swept_area', 0):.2f} m²"],
                ["Theoretical Power", f"{data.get('theoretical_power', 0) / 1000:.2f} kW"],
                ["Actual Power", f"{data.get('actual_power', 0) / 1000:.2f} kW"],
                ["Annual Energy", f"{data.get('annual_energy', 0) / 1000:.2f} MWh"],
                ["Capacity Factor", f"{data.get('capacity_factor', 0) * 100:.1f}%"],
                ["Rated Capacity", f"{data.get('rated_capacity', 0):.2f} kVA"],
                ["Output Current", f"{data.get('output_current', 0):.2f} A"]
            ]
            
            # Create results table
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
            
            # Add power curve chart if image path provided
            chart_image_path = data.get('chart_image_path', '')
            if chart_image_path and os.path.exists(chart_image_path):
                try:
                    story.append(Paragraph("Power Curve", heading_style))
                    story.append(Spacer(1, 12))
                    img = Image(chart_image_path)
                    img.drawHeight = 300
                    img.drawWidth = 450
                    story.append(img)
                    story.append(Spacer(1, 24))
                except Exception as e:
                    print(f"Warning: Couldn't add power curve image to PDF: {e}")
            
            # Build PDF
            doc.build(story)
            
            print(f"Wind turbine report generated successfully at {filepath}")
            return True
            
        except Exception as e:
            print(f"Error generating wind turbine report: {e}")
            import traceback
            traceback.print_exc()
            return False
