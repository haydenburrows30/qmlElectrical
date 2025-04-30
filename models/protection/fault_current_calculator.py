from PySide6.QtCore import QObject, Property, Signal, Slot
import math
import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt
import tempfile
import os
from datetime import datetime
from services.file_saver import FileSaver
from services.logger_config import configure_logger
import numpy as np


logger = configure_logger("qmltest", component="fault_current")

class FaultCurrentCalculator(QObject):
    """Calculator for fault current analysis including system, transformer and cable impedances
    
    Implementation follows IEC 60909 standards for short-circuit currents in three-phase AC systems.
    Key components included:
    - Per-unit impedance calculations
    - Accurate R/X component splitting based on X/R ratios
    - IEC 60909 factors for peak, breaking, and thermal currents
    - Line-Ground fault calculations according to IEC standards
    """
    
    # Define signals for QML
    calculationComplete = Signal()
    exportComplete = Signal(bool, str)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # System parameters
        self._system_voltage = 11.0  # kV
        self._system_mva = 500.0  # MVA
        self._system_xr_ratio = 15.0  # System X/R ratio
        
        # Transformer parameters
        self._transformer_mva = 5.0  # MVA
        self._transformer_z = 6.0  # %
        self._transformer_xr_ratio = 10.0  # Transformer X/R ratio
        
        # Cable parameters
        self._cable_length = 0.5  # km
        self._cable_r = 0.2  # Ω/km (resistance)
        self._cable_x = 0.15  # Ω/km (reactance)
        
        # Motor contribution (if applicable)
        self._include_motors = False
        self._motor_mva = 1.0  # MVA
        self._motor_contribution_factor = 4.0  # Typical value for induction motors
        
        # Fault parameters
        self._fault_type = "3-Phase"
        self._fault_resistance = 0.0  # Ω (arc or ground resistance)
        
        # Calculated results
        self._initial_sym_current = 0.0  # kA
        self._peak_fault_current = 0.0  # kA
        self._breaking_current = 0.0  # kA
        self._thermal_current = 0.0  # kA
        self._total_impedance = 0.0  # Ω
        self._total_r = 0.0  # Ω (resistance)
        self._total_x = 0.0  # Ω (reactance)
        self._system_pu_z = 0.0  # System impedance in per-unit
        self._transformer_pu_z = 0.0  # Transformer impedance in per-unit
        self._cable_pu_z = 0.0  # Cable impedance in per-unit
        self._effective_xr_ratio = 0.0  # Effective X/R ratio of the circuit
        
        # Initialize FileSaver
        self._file_saver = FileSaver()
        
        # Connect file saver signal to our exportComplete signal
        self._file_saver.saveStatusChanged.connect(self.exportComplete)
        
        # Initial calculation
        self._calculate()

    def _calculate(self):
        """Perform fault current calculations"""
        try:
            # Base values for per-unit calculations
            base_kv = self._system_voltage
            base_mva = self._transformer_mva
            z_base = (base_kv * 1000) ** 2 / (base_mva * 1e6)
            
            # Calculate system impedance in per-unit - using correct formula
            z_system_pu = base_mva / self._system_mva
            self._system_pu_z = z_system_pu
            
            # Split system impedance into R and X components using system X/R ratio
            system_x = z_system_pu * self._system_xr_ratio / math.sqrt(1 + self._system_xr_ratio**2)
            system_r = z_system_pu / math.sqrt(1 + self._system_xr_ratio**2)  # More accurate formula
            
            # Calculate transformer impedance in per-unit
            z_transformer_pu = self._transformer_z / 100.0
            self._transformer_pu_z = z_transformer_pu
            
            # Split transformer impedance into R and X components using transformer X/R ratio
            tx_x = z_transformer_pu * self._transformer_xr_ratio / math.sqrt(1 + self._transformer_xr_ratio**2)
            tx_r = z_transformer_pu / math.sqrt(1 + self._transformer_xr_ratio**2)  # More accurate formula
            
            # Calculate cable impedance in ohms
            cable_r_ohm = self._cable_r * self._cable_length
            cable_x_ohm = self._cable_x * self._cable_length
            
            # Convert cable impedance to per-unit
            cable_r_pu = cable_r_ohm / z_base
            cable_x_pu = cable_x_ohm / z_base
            self._cable_pu_z = math.sqrt(cable_r_pu**2 + cable_x_pu**2)
            
            # Calculate motor contribution in per-unit (if included)
            motor_x_pu = 0
            motor_r_pu = 0
            if self._include_motors:
                # For induction motors, use subtransient impedance
                motor_z_pu = 1.0 / (self._motor_mva / base_mva * self._motor_contribution_factor)
                motor_xr_ratio = 20.0  # Typical X/R ratio for motors
                motor_x_pu = motor_z_pu * motor_xr_ratio / math.sqrt(1 + motor_xr_ratio**2)
                motor_r_pu = motor_z_pu / math.sqrt(1 + motor_xr_ratio**2)  # More accurate formula
            
            # Calculate fault resistance in per-unit
            fault_r_pu = self._fault_resistance / z_base
            
            # Calculate total R, X in per-unit
            total_r_pu = system_r + tx_r + cable_r_pu + fault_r_pu
            total_x_pu = system_x + tx_x + cable_x_pu
            
            # If motors included, add their contribution (in parallel)
            if self._include_motors and (motor_r_pu > 0 or motor_x_pu > 0):
                # Convert R-jX to complex form for parallel combination
                z_circuit = complex(total_r_pu, total_x_pu)
                z_motor = complex(motor_r_pu, motor_x_pu)
                # Parallel combination: Z = Z1*Z2/(Z1+Z2)
                z_total = (z_circuit * z_motor) / (z_circuit + z_motor)
                total_r_pu = z_total.real
                total_x_pu = z_total.imag
            
            # Calculate total impedance in per-unit and ohms
            total_z_pu = math.sqrt(total_r_pu**2 + total_x_pu**2)
            self._total_r = total_r_pu * z_base
            self._total_x = total_x_pu * z_base
            self._total_impedance = total_z_pu * z_base
            
            # Calculate effective X/R ratio
            if total_r_pu > 0:
                self._effective_xr_ratio = total_x_pu / total_r_pu
            else:
                self._effective_xr_ratio = 20.0  # Default high value if R is zero
            
            # Calculate fault currents based on type
            if total_z_pu > 0:
                # Calculate base current directly using MVA and kV
                base_current_ka = base_mva * 1000 / (math.sqrt(3) * base_kv) # Base current in kA
                
                # Fault current per-unit
                fault_current_pu = 1.0 / total_z_pu
                
                # Fault current in kA before applying type factors
                base_fault_current = fault_current_pu * base_current_ka
                
                # Adjust fault current based on type - using IEC standards
                fault_factors = {
                    "3-Phase": 1.0,
                    "Line-Line": math.sqrt(3)/2,  # √3/2 = 0.866
                    "Line-Ground": 3.0/(2 + self._effective_xr_ratio),  # More accurate formula for SLG
                    "Line-Line-Ground": 1.15  # Approximation for LLG faults
                }
                
                factor = fault_factors.get(self._fault_type, 1.0)
                self._initial_sym_current = base_fault_current * factor
                
                # Calculate peak fault current (includes DC component)
                # Using IEC 60909 formula: peak = √2 × Ik × κ, where κ = 1.02 + 0.98e^(-3/X/R)
                kappa = 1.02 + 0.98 * math.exp(-3.0/self._effective_xr_ratio)
                self._peak_fault_current = self._initial_sym_current * math.sqrt(2) * kappa
                
                # Breaking current (after DC decay) - IEC 60909 approach
                # For circuit breakers with typical breaking time of 50-80ms
                t_breaking = 0.08  # seconds, typical breaking time
                dc_factor = math.exp(-2 * math.pi * 50 * t_breaking / self._effective_xr_ratio)
                breaking_factor = math.sqrt(1 + 2 * dc_factor)
                self._breaking_current = self._initial_sym_current * breaking_factor
                
                # Thermal equivalent current (1 second) - IEC 60909 formula
                duration = 1.0  # seconds
                m_factor = 1.0 / (1 + self._effective_xr_ratio) * (
                    1 - math.exp(-2 * duration / self._effective_xr_ratio)
                )
                n_factor = 1.0
                thermal_factor = math.sqrt(m_factor + n_factor)
                self._thermal_current = self._initial_sym_current * thermal_factor
            else:
                # Avoid division by zero
                self._initial_sym_current = 0
                self._peak_fault_current = 0
                self._breaking_current = 0
                self._thermal_current = 0
            
            # Notify QML that calculation is complete
            self.calculationComplete.emit()
            
        except Exception as e:
            print(f"Fault current calculation error: {e}")
    
    @Slot()
    def exportToPdf(self):
        """Export calculation results to PDF"""
        try:
            # Create timestamp for filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get save location using FileSaver
            pdf_file = self._file_saver.get_save_filepath("pdf", f"fault_current_report_{timestamp}")
            if not pdf_file:
                self.exportComplete.emit(False, "PDF export canceled")
                return False
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Create temporary directory for diagram image
            temp_dir = tempfile.mkdtemp()
            diagram_image_path = os.path.join(temp_dir, "fault_diagram.png")
            
            # Generate system diagram using matplotlib
            self._generate_system_diagram(diagram_image_path)
            
            # Prepare data for PDF generation
            data = {
                'system_voltage': self._system_voltage,
                'system_mva': self._system_mva,
                'system_xr_ratio': self._system_xr_ratio,
                'transformer_mva': self._transformer_mva,
                'transformer_z': self._transformer_z,
                'transformer_xr_ratio': self._transformer_xr_ratio,
                'cable_length': self._cable_length,
                'cable_r': self._cable_r,
                'cable_x': self._cable_x,
                'fault_type': self._fault_type,
                'fault_resistance': self._fault_resistance,
                'include_motors': self._include_motors,
                'motor_mva': self._motor_mva,
                'motor_contribution_factor': self._motor_contribution_factor,
                'initial_sym_current': self._initial_sym_current,
                'peak_fault_current': self._peak_fault_current,
                'breaking_current': self._breaking_current,
                'thermal_current': self._thermal_current,
                'total_impedance': self._total_impedance,
                'total_r': self._total_r,
                'total_x': self._total_x,
                'effective_xr_ratio': self._effective_xr_ratio,
                'system_pu_z': self._system_pu_z,
                'transformer_pu_z': self._transformer_pu_z,
                'cable_pu_z': self._cable_pu_z,
                'diagram_image_path': diagram_image_path if os.path.exists(diagram_image_path) else None
            }
            
            # Generate PDF using the fault current PDF generator
            from utils.pdf.pdf_generator_fault_current import FaultCurrentPdfGenerator
            pdf_generator = FaultCurrentPdfGenerator()
            success = pdf_generator.generate_report(data, pdf_file)
            
            # Clean up temporary files
            try:
                if os.path.exists(diagram_image_path):
                    os.unlink(diagram_image_path)
                os.rmdir(temp_dir)
            except Exception as e:
                logger.error(f"Error cleaning up temp files: {e}")
            
            # Force garbage collection to ensure resources are freed
            import gc
            gc.collect()
            
            # Signal success or failure
            if success:
                self._file_saver._emit_success_with_path(pdf_file, "PDF saved")
                return True
            else:
                self._file_saver._emit_failure_with_path(pdf_file, "Error saving PDF")
                return False
                
        except Exception as e:
            error_msg = f"Error exporting to PDF: {str(e)}"
            logger.error(error_msg)
            self.exportComplete.emit(False, error_msg)
            return False
    
    def _generate_system_diagram(self, filepath):
        """Generate a system diagram using matplotlib and save it to a file
        
        Args:
            filepath: Path to save the diagram image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create figure
            plt.figure(figsize=(10, 6))
            
            # Set up coordinates
            grid_x = [1, 3, 5, 7, 9]
            center_y = 3
            
            # Draw system source
            plt.plot([grid_x[0]], [center_y], 'o', markersize=20, 
                    markerfacecolor='white', markeredgecolor='blue', markeredgewidth=2)
            plt.text(grid_x[0], center_y + 0.4, f"{self._system_voltage} kV\n{self._system_mva} MVA", 
                    ha='center', va='center', fontsize=9)
            
            # Draw busbar
            plt.plot([grid_x[0], grid_x[4]], [center_y + 1, center_y + 1], 'k-', linewidth=3)
            
            # Draw transformer
            plt.plot([grid_x[1]], [center_y], 's', markersize=20, 
                    markerfacecolor='white', markeredgecolor='blue', markeredgewidth=2)
            plt.text(grid_x[1], center_y + 0.4, f"TX: {self._transformer_mva} MVA\nZ: {self._transformer_z}%", 
                    ha='center', va='center', fontsize=9)
            
            # Draw impedance lines for cable
            x_points = [grid_x[1] + 0.2, grid_x[2] - 0.2]
            y_points = [center_y, center_y]
            plt.plot(x_points, y_points, 'k-', linewidth=2)
            
            # Draw cable with zigzag line
            zigzag_x = np.linspace(grid_x[2], grid_x[3], 20)
            zigzag_y = center_y + 0.2 * np.sin(np.linspace(0, 6*np.pi, 20))
            plt.plot(zigzag_x, zigzag_y, 'k-', linewidth=2)
            plt.text(grid_x[2] + 0.5, center_y + 0.5, 
                   f"Cable: {self._cable_length} km\nR={self._cable_r}, X={self._cable_x} Ω/km", 
                   ha='center', va='center', fontsize=9)
            
            # Draw fault location
            fault_x = grid_x[3]
            fault_y = center_y
            plt.plot([fault_x], [fault_y], 'x', markersize=15, 
                   markeredgecolor='red', markeredgewidth=3)
            
            # Draw lightning bolt for fault
            bolt_x = [fault_x, fault_x - 0.2, fault_x + 0.2, fault_x - 0.1]
            bolt_y = [fault_y, fault_y - 0.5, fault_y - 1, fault_y - 1.5]
            plt.plot(bolt_x, bolt_y, 'r-', linewidth=2)
            
            # Add fault annotation
            plt.text(fault_x, fault_y - 1.8, 
                   f"{self._fault_type} Fault\nIf = {self._initial_sym_current:.1f} kA", 
                   ha='center', va='top', fontsize=10, color='red', fontweight='bold')
            
            # Add motor contribution if included
            if self._include_motors:
                motor_x = grid_x[2]
                motor_y = center_y - 1.5
                plt.plot([motor_x], [motor_y], 'o', markersize=15, 
                       markerfacecolor='white', markeredgecolor='purple', markeredgewidth=2)
                plt.plot([motor_x, motor_x], [center_y, motor_y], 'k-', linewidth=1.5)
                plt.text(motor_x, motor_y - 0.4, 
                       f"Motor: {self._motor_mva} MVA", 
                       ha='center', va='center', fontsize=9, color='purple')
            
            # Add impedance values
            plt.text(grid_x[3] + 0.5, center_y + 1, 
                   f"Total Z = {self._total_impedance:.3f} Ω\nR = {self._total_r:.3f} Ω, X = {self._total_x:.3f} Ω\nX/R = {self._effective_xr_ratio:.2f}", 
                   ha='left', va='center', fontsize=9, 
                   bbox=dict(facecolor='white', edgecolor='black', boxstyle='round,pad=0.5'))
            
            # Set plot limits and remove axes
            plt.xlim(0.5, 10)
            plt.ylim(0.5, 5)
            plt.axis('off')
            
            # Add title
            plt.title(f"Fault Current Analysis - {self._fault_type}", fontsize=14)
            
            # Save figure
            plt.tight_layout()
            plt.savefig(filepath, dpi=150, bbox_inches='tight')
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            import gc
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating system diagram: {e}")
            plt.close('all')  # Make sure to close figures on error
            return False
    
    # Property getters for QML - Results section
    @Property(float, notify=calculationComplete)
    def initialSymCurrent(self):
        return self._initial_sym_current
    
    @Property(float, notify=calculationComplete)
    def peakFaultCurrent(self):
        return self._peak_fault_current
    
    @Property(float, notify=calculationComplete)  
    def breakingCurrent(self):
        return self._breaking_current
    
    @Property(float, notify=calculationComplete)
    def thermalCurrent(self):
        return self._thermal_current
    
    @Property(float, notify=calculationComplete)
    def totalImpedance(self):
        return self._total_impedance
    
    @Property(float, notify=calculationComplete)
    def totalR(self):
        return self._total_r
    
    @Property(float, notify=calculationComplete)
    def totalX(self):
        return self._total_x
    
    @Property(float, notify=calculationComplete)
    def effectiveXrRatio(self):
        return self._effective_xr_ratio
    
    @Property(float, notify=calculationComplete)
    def systemPuZ(self):
        return self._system_pu_z
    
    @Property(float, notify=calculationComplete)
    def transformerPuZ(self):
        return self._transformer_pu_z
    
    @Property(float, notify=calculationComplete)
    def cablePuZ(self):
        return self._cable_pu_z
    
    # System properties
    @Property(float, notify=calculationComplete)
    def systemVoltage(self):
        return self._system_voltage
        
    @systemVoltage.setter
    def systemVoltage(self, voltage):
        if self._system_voltage != voltage and voltage > 0:
            self._system_voltage = voltage
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def systemMva(self):
        return self._system_mva
        
    @systemMva.setter
    def systemMva(self, mva):
        if self._system_mva != mva and mva > 0:
            self._system_mva = mva
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def systemXrRatio(self):
        return self._system_xr_ratio
        
    @systemXrRatio.setter
    def systemXrRatio(self, ratio):
        if self._system_xr_ratio != ratio and ratio > 0:
            self._system_xr_ratio = ratio
            self._calculate()
    
    # Transformer properties
    @Property(float, notify=calculationComplete)
    def transformerMva(self):
        return self._transformer_mva
        
    @transformerMva.setter
    def transformerMva(self, mva):
        if self._transformer_mva != mva and mva > 0:
            self._transformer_mva = mva
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def transformerZ(self):
        return self._transformer_z
        
    @transformerZ.setter
    def transformerZ(self, z):
        if self._transformer_z != z and z >= 0:
            self._transformer_z = z
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def transformerXrRatio(self):
        return self._transformer_xr_ratio
        
    @transformerXrRatio.setter
    def transformerXrRatio(self, ratio):
        if self._transformer_xr_ratio != ratio and ratio > 0:
            self._transformer_xr_ratio = ratio
            self._calculate()
    
    # Cable properties
    @Property(float, notify=calculationComplete)
    def cableLength(self):
        return self._cable_length
        
    @cableLength.setter
    def cableLength(self, length):
        if self._cable_length != length and length >= 0:
            self._cable_length = length
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def cableR(self):
        return self._cable_r
        
    @cableR.setter
    def cableR(self, r):
        if self._cable_r != r and r >= 0:
            self._cable_r = r
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def cableX(self):
        return self._cable_x
        
    @cableX.setter
    def cableX(self, x):
        if self._cable_x != x and x >= 0:
            self._cable_x = x
            self._calculate()
    
    # Fault properties
    @Property(str, notify=calculationComplete)
    def faultType(self):
        return self._fault_type
        
    @faultType.setter
    def faultType(self, fault_type):
        if self._fault_type != fault_type:
            self._fault_type = fault_type
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def faultResistance(self):
        return self._fault_resistance
        
    @faultResistance.setter
    def faultResistance(self, resistance):
        if self._fault_resistance != resistance and resistance >= 0:
            self._fault_resistance = resistance
            self._calculate()
    
    # Motor contribution properties
    @Property(bool, notify=calculationComplete)
    def includeMotors(self):
        return self._include_motors
        
    @includeMotors.setter
    def includeMotors(self, include):
        if self._include_motors != include:
            self._include_motors = include
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def motorMva(self):
        return self._motor_mva
        
    @motorMva.setter
    def motorMva(self, mva):
        if self._motor_mva != mva and mva > 0:
            self._motor_mva = mva
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def motorContributionFactor(self):
        return self._motor_contribution_factor
        
    @motorContributionFactor.setter
    def motorContributionFactor(self, factor):
        if self._motor_contribution_factor != factor and factor > 0:
            self._motor_contribution_factor = factor
            self._calculate()
    
    # Slots for receiving values from QML (keep these for backward compatibility)
    @Slot(float)
    def setSystemVoltage(self, voltage):
        self.systemVoltage = voltage
    
    @Slot(float)
    def setSystemMva(self, mva):
        self.systemMva = mva
    
    @Slot(float)
    def setSystemXrRatio(self, ratio):
        self.systemXrRatio = ratio
    
    @Slot(float)
    def setTransformerMva(self, mva):
        self.transformerMva = mva
    
    @Slot(float)
    def setTransformerZ(self, z):
        self.transformerZ = z
    
    @Slot(float)
    def setTransformerXrRatio(self, ratio):
        self.transformerXrRatio = ratio
    
    @Slot(float)
    def setCableLength(self, length):
        self.cableLength = length
    
    @Slot(float)
    def setCableR(self, r):
        self.cableR = r
    
    @Slot(float)
    def setCableX(self, x):
        self.cableX = x
    
    @Slot(str)
    def setFaultType(self, fault_type):
        self.faultType = fault_type
    
    @Slot(float)
    def setFaultResistance(self, resistance):
        self.faultResistance = resistance
    
    @Slot(bool)
    def setIncludeMotors(self, include):
        self.includeMotors = include
    
    @Slot(float)
    def setMotorMva(self, mva):
        self.motorMva = mva
    
    @Slot(float)
    def setMotorContributionFactor(self, factor):
        self.motorContributionFactor = factor
    
    # Legacy property and slot for backwards compatibility
    @Property(float, notify=calculationComplete)
    def xrRatio(self):
        return self._system_xr_ratio
    
    @xrRatio.setter
    def xrRatio(self, ratio):
        self.systemXrRatio = ratio
    
    @Slot(float)
    def setXrRatio(self, ratio):
        self.systemXrRatio = ratio
