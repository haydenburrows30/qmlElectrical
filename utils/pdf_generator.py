from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.platypus import Image
import os

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
        
    def generate_protection_report(self, data, filename):
        """Generate a protection requirements report"""
        try:
            print("Protection report data:", data)
            doc = SimpleDocTemplate(
                filename,
                pagesize=A4,
                rightMargin=72,
                leftMargin=72,
                topMargin=72,
                bottomMargin=72
            )
            
            story = []
            story.append(Paragraph("Wind Turbine Protection Requirements", self.title_style))
            
            # Generator Section - use exact data structure
            story.append(Paragraph("Generator Protection", self.section_style))
            gen = data['generator']
            gen_data = [
                ["Parameter", "Value"],
                ["Power Rating", f"{gen['power']:.2f} kW"],
                ["Output Current", f"{gen['current']:.2f} A"],
                ["Instantaneous Overcurrent", f"{gen['overcurrent_pickup']:.2f} A (300%)"],
                ["Time Overcurrent Pickup", f"{gen['current'] * 1.1:.2f} A (110%)"],
                ["Time Overcurrent Delay", gen['time_delay']],
                ["50/51 CT Ratio", gen['ct_ratio']],
                ["Voltage Range", gen['voltage_range']],
                ["Frequency Range", gen['frequency_range']],
                ["Earth Fault", gen['earth_fault']],
                ["Anti-Islanding", gen['anti_islanding']]
            ]
            story.append(self._create_table(gen_data))
            story.append(Spacer(1, 20))
            
            # Transformer Protection Section
            story.append(Paragraph("Transformer Protection", self.section_style))
            trans = data['transformer']
            transformer_data = [
                ["Parameter", "Value"],
                ["Rating", f"{trans['rating']:.2f} kVA"],
                ["Voltage Ratio", trans['voltage']],
                ["Full Load Current", f"{trans['full_load_current']:.2f} A"],
                ["Fault Current", f"{trans['fault_current']:.2f} kA"],
                ["Ground Fault Current", f"{trans['ground_fault']:.2f} A"],
                ["CT Ratio", trans['ct_ratio']],
                ["Overcurrent Pickup", f"{trans['relay_pickup_current']:.2f} A (125% FLC)"],
                ["Time-Current Curve", trans['relay_curve_type']],
                ["Time Dial Setting", f"{trans['time_dial']:.2f}"],
                ["Instantaneous Pickup", f"{trans['instantaneous_pickup']:.2f} A (800%)"],
                ["Earth Fault Setting", "30% of FLC"],
                ["Differential Protection", f"Slope: {trans['differential_slope']:.1f}%"],
                ["Reverse Power", f"{trans['reverse_power']:.1f}% of rating"]
            ]
            story.append(self._create_table(transformer_data))
            story.append(Spacer(1, 20))
            
            # Line Protection Section
            story.append(Paragraph("Line Protection", self.section_style))
            line = data['line']
            line_data = [
                ["Parameter", "Value"],
                ["Operating Voltage", line['voltage']],
                ["Maximum Fault Current", f"{line['fault_current']:.2f} kA"],
                ["Minimum Cable Size", line['cable_size']],
                ["Line Length", f"{line['length']:.1f} km"],
                ["Voltage Regulation", f"{line['voltage_drop']:.2f}%"],
                ["Distance Protection", "Required > 10km"],
                ["Auto-Reclosure", "Single-shot"]
            ]
            story.append(self._create_table(line_data))
            story.append(Spacer(1, 20))
            
            # Protection Settings Section
            story.append(Paragraph("Protection Settings", self.section_style))
            protect_data = [["Type", "Stage", "Setting", "Time Delay"]]
            
            # Add voltage protection settings
            for v in data['protection_settings']['voltage']:
                protect_data.append([v['type'], v['stage'], v['setting'], v['time']])
                
            # Add frequency protection settings
            for f in data['protection_settings']['frequency']:
                protect_data.append([f['type'], f['stage'], f['setting'], f['time']])
            
            story.append(self._create_table(protect_data))
            
            # Build the PDF
            doc.build(story)
            
        except KeyError as e:
            print(f"Missing data field: {e}")
            print(f"Received data structure: {data}")
        except Exception as e:
            print(f"Error generating protection report: {e}")
            print(f"Data: {data}")
    
    def _create_table(self, data):
        """Helper method to create consistently styled tables"""
        if len(data[0]) == 2:  # Parameter-Value table
            table = Table(data, colWidths=[200, 200])
        else:  # Protection settings table
            table = Table(data, colWidths=[100, 100, 150, 100])
            
        table.setStyle(TableStyle([
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.white),
            ('TEXTCOLOR', (0, 1), (-1, -1), colors.black),
            ('ALIGN', (0, 1), (-1, -1), 'LEFT'),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        return table
    
    def generate_transformer_report(self, data, filename):
        """Generate a transformer report"""
        doc = SimpleDocTemplate(
            filename,
            pagesize=A4,
            rightMargin=72,
            leftMargin=72,
            topMargin=72,
            bottomMargin=72
        )
        
        story = []
        story.append(Paragraph("Transformer Analysis Report", self.title_style))
        
        # Transformer Parameters
        story.append(Paragraph("Transformer Parameters", self.section_style))
        transformer_data = [
            ["Parameter", "Value"],
            ["Rating", f"{data['transformer_rating']:.2f} kVA"],
            ["Impedance", f"{data['transformer_impedance']:.2f}%"],
            ["X/R Ratio", f"{data['transformer_xr_ratio']:.2f}"],
            ["Total Z", f"{data['transformer_z']:.2f} Ω"],
            ["R Component", f"{data['transformer_r']:.2f} Ω"],
            ["X Component", f"{data['transformer_x']:.2f} Ω"],
            ["Voltage Drop", f"{data['voltage_drop']:.2f}%"],
            ["Fault Current (HV)", f"{data['fault_current_hv']:.2f} kA"],
            ["Fault Current (LV)", f"{data['fault_current_lv']:.2f} kA"],
            ["Ground Fault Current", f"{data['ground_fault_current']:.2f} A"]
        ]
        story.append(self._create_table(transformer_data))
        story.append(Spacer(1, 20))
        
        # Line Parameters
        story.append(Paragraph("Line Parameters", self.section_style))
        line_data = [
            ["Parameter", "Value"],
            ["Total Impedance", f"{data['line_total_z']:.2f} Ω"],
            ["Voltage Drop", f"{data['voltage_drop']:.2f}%"],
            ["Unregulated Voltage", f"{data['unregulated_voltage']:.2f} kV"],
            ["Regulated Voltage", f"{data['regulated_voltage']:.2f} kV"],
            ["Recommended HV Cable", data['recommended_hv_cable']],
            ["Recommended LV Cable", data['recommended_lv_cable']]
        ]
        story.append(self._create_table(line_data))
        story.append(Spacer(1, 20))
        
        # Voltage Regulator Parameters
        story.append(Paragraph("Voltage Regulator", self.section_style))
        regulator_data = [
            ["Parameter", "Value"],
            ["Status", "Enabled" if data['regulator_enabled'] else "Disabled"],
            ["Type", data['regulator_type']],
            ["Connection", data['regulator_connection']],
            ["Tap Position", str(data['tap_position'])],
            ["Target Voltage", f"{data['regulator_target']:.2f} kV"],
            ["Bandwidth", f"{data['regulator_bandwidth']:.1f}%"],
            ["Range", f"±{data['regulator_range']:.1f}%"],
            ["Three-Phase Capacity", f"{data['regulator_three_phase_capacity']:.0f} kVA"]
        ]
        story.append(self._create_table(regulator_data))
        story.append(Spacer(1, 20))
        
        # Protection Settings
        story.append(Paragraph("Protection Settings", self.section_style))
        protection_data = [
            ["Parameter", "Value"],
            ["CT Ratio", data['ct_ratio']],
            ["Pickup Current", f"{data['relay_pickup_current']:.2f} A"],
            ["Time-Current Curve", data['relay_curve_type']],
            ["Time Dial Setting", f"{data['time_dial']:.2f}"],
            ["Differential Slope", f"{data['differential_slope']:.1f}%"],
            ["Reverse Power", f"{data['reverse_power']:.1f}%"]
        ]
        story.append(self._create_table(protection_data))
        
        # Build the PDF
        doc.build(story)
    
    def generate_wind_turbine_report(self, data, filename):
        """Generate a wind turbine analysis report
        
        Args:
            data: Dictionary containing wind turbine data
            filename: Output PDF filename
        """
        try:
            doc = SimpleDocTemplate(
                filename,
                pagesize=A4,
                rightMargin=72,
                leftMargin=72,
                topMargin=72,
                bottomMargin=72
            )
            
            # Calculate available width for content (A4 width minus margins)
            available_width = A4[0] - 144  # 72 points margin on each side
            
            story = []
            story.append(Paragraph("Wind Turbine Analysis Report", self.title_style))
            
            # Turbine Parameters
            story.append(Paragraph("Wind Turbine Parameters", self.section_style))
            params_data = [
                ["Parameter", "Value"],
                ["Blade Radius", f"{data['blade_radius']:.2f} m"],
                ["Wind Speed", f"{data['wind_speed']:.2f} m/s"],
                ["Air Density", f"{data['air_density']:.3f} kg/m³"],
                ["Power Coefficient", f"{data['power_coefficient']:.2f}"],
                ["Generator Efficiency", f"{data['efficiency']*100:.1f}%"],
                ["Cut-in Wind Speed", f"{data['cut_in_speed']:.1f} m/s"],
                ["Cut-out Wind Speed", f"{data['cut_out_speed']:.1f} m/s"],
                ["Swept Area", f"{data['swept_area']:.2f} m²"]
            ]
            story.append(self._create_table(params_data))
            story.append(Spacer(1, 20))
            
            # Turbine Output
            story.append(Paragraph("Wind Turbine Output", self.section_style))
            output_data = [
                ["Parameter", "Value"],
                ["Theoretical Power", f"{data['theoretical_power']/1000:.2f} kW"],
                ["Actual Power Output", f"{data['actual_power']/1000:.2f} kW"],
                ["Annual Energy Production", f"{data['annual_energy']:.2f} MWh/year"],
                ["Generator Rated Capacity", f"{data['rated_capacity']:.2f} kVA"],
                ["Generator Output Current", f"{data['output_current']:.2f} A"],
                ["Capacity Factor", f"{data['capacity_factor']*100:.1f}%"]
            ]
            story.append(self._create_table(output_data))
            story.append(Spacer(1, 20))
            
            # Power Curve Chart
            story.append(Paragraph("Power Curve", self.section_style))
            
            # If we have a chart image, include it
            if data['chart_image_path'] and os.path.exists(data['chart_image_path']):
                try:
                    # Get the image dimensions to calculate the proper aspect ratio
                    from PIL import Image as PILImage
                    try:
                        img_pil = PILImage.open(data['chart_image_path'])
                        img_width, img_height = img_pil.size
                        aspect_ratio = img_height / float(img_width)
                        
                        # Scale image to fit the available width while maintaining aspect ratio
                        display_width = available_width
                        display_height = available_width * aspect_ratio
                        
                        # Ensure the height isn't too large for the page
                        max_height = 4.5 * inch
                        if display_height > max_height:
                            display_height = max_height
                            display_width = display_height / aspect_ratio
                        
                        # Create the image with proper dimensions
                        img = Image(data['chart_image_path'], width=display_width, height=display_height)
                        
                        # Center the image
                        img.hAlign = 'CENTER'
                        
                        story.append(img)
                        story.append(Spacer(1, 10))
                        story.append(Paragraph("Power curve showing turbine output vs. wind speed.", 
                                              ParagraphStyle('ImageCaption', parent=self.styles["Normal"], alignment=1)))
                    except ImportError:
                        # Fall back if PIL is not available
                        img = Image(data['chart_image_path'], width=available_width * 0.9, height=3 * inch)
                        img.hAlign = 'CENTER'
                        story.append(img)
                except Exception as e:
                    print(f"Error including chart image: {e}")
                    # Add a note if image couldn't be included
                    story.append(Paragraph("Power curve chart could not be included: " + str(e), self.styles["Normal"]))
            else:
                # Add a textual note if no chart image is available
                story.append(Paragraph("Power curve chart not available.", self.styles["Normal"]))
            
            story.append(Spacer(1, 20))
            
            # Additional Technical Information
            story.append(Paragraph("Technical Notes", self.section_style))
            
            notes = [
                "Power Formula: P = ½ × ρ × A × Cp × v³ × η",
                "Where P = Power output, ρ = Air density, A = Swept area, Cp = Power coefficient, v = Wind speed, η = Generator efficiency",
                f"The Betz limit sets the theoretical maximum power coefficient at 0.593 (current model: {data['power_coefficient']:.2f})",
                "Annual energy production estimate includes typical capacity factor adjustments for wind variability",
                "Generator electrical protection should include overcurrent, undervoltage, and frequency relays"
            ]
            
            for note in notes:
                story.append(Paragraph(f"• {note}", self.styles["Normal"]))
                story.append(Spacer(1, 5))
            
            # Build the PDF
            doc.build(story)
            return True
            
        except KeyError as e:
            print(f"Missing data field in wind turbine report: {e}")
            return False
        except Exception as e:
            print(f"Error generating wind turbine report: {e}")
            import traceback
            traceback.print_exc()
            return False
