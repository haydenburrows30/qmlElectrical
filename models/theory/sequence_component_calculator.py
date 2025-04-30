import math
import numpy as np
from PySide6.QtCore import QObject, Signal, Slot, Property
import logging

logger = logging.getLogger(__name__)

class SequenceComponentCalculator(QObject):
    """Calculator for three-phase sequence components.
    
    Features:
    - Calculates positive, negative, and zero sequence components
    - Supports both voltage and current inputs
    - Handles unbalanced three-phase systems
    - Provides phase angle information
    
    Signals:
        dataChanged: Emitted when input parameters are updated
    """
    
    dataChanged = Signal()
    exportComplete = Signal(bool, str)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Voltage magnitude defaults (line-to-neutral)
        self._voltageA = 230.0
        self._voltageB = 230.0
        self._voltageC = 230.0
        
        # Voltage phase angles
        self._voltageAngleA = 0.0
        self._voltageAngleB = -120.0
        self._voltageAngleC = 120.0
        
        # Current magnitude defaults
        self._currentA = 100.0
        self._currentB = 100.0
        self._currentC = 100.0
        
        # Current phase angles
        self._currentAngleA = -30.0  # Lagging by 30 degrees
        self._currentAngleB = -150.0  # -120 - 30 degrees
        self._currentAngleC = 90.0    # 120 - 30 degrees
        
        # Cache for calculated values
        self._cache = {}
        self._cache_key = None
        
        # Calculate initial values
        self._calculate_sequence_components()
        
        # Initialize file saver
        from services.file_saver import FileSaver
        self._file_saver = FileSaver()
        
        # Connect file saver signal to our exportComplete signal
        self._file_saver.saveStatusChanged.connect(self.exportComplete)
    
    def _get_cache_key(self) -> tuple:
        """Create a tuple key for caching calculated values"""
        return (
            self._voltageA, self._voltageB, self._voltageC,
            self._voltageAngleA, self._voltageAngleB, self._voltageAngleC,
            self._currentA, self._currentB, self._currentC,
            self._currentAngleA, self._currentAngleB, self._currentAngleC
        )
    
    def _calculate_sequence_components(self):
        """Calculate all sequence components for voltage and current"""
        cache_key = self._get_cache_key()
        
        # Return cached values if inputs haven't changed
        if cache_key == self._cache_key and self._cache:
            return
            
        # Convert voltage values to phasors
        va = self._voltageA * np.exp(1j * np.radians(self._voltageAngleA))
        vb = self._voltageB * np.exp(1j * np.radians(self._voltageAngleB))
        vc = self._voltageC * np.exp(1j * np.radians(self._voltageAngleC))
        
        # Convert current values to phasors
        ia = self._currentA * np.exp(1j * np.radians(self._currentAngleA))
        ib = self._currentB * np.exp(1j * np.radians(self._currentAngleB))
        ic = self._currentC * np.exp(1j * np.radians(self._currentAngleC))
        
        # Operator a = 1∠120° (complex rotation operator)
        a = complex(-0.5, 0.866)  # 1∠120°
        a2 = complex(-0.5, -0.866)  # 1∠240° or a²
        
        # Calculate voltage sequence components
        # Positive sequence: (Va + a*Vb + a²*Vc)/3
        v_pos = (va + a * vb + a2 * vc) / 3
        # Negative sequence: (Va + a²*Vb + a*Vc)/3
        v_neg = (va + a2 * vb + a * vc) / 3
        # Zero sequence: (Va + Vb + Vc)/3
        v_zero = (va + vb + vc) / 3
        
        # Calculate current sequence components
        # Positive sequence: (Ia + a*Ib + a²*Ic)/3
        i_pos = (ia + a * ib + a2 * ic) / 3
        # Negative sequence: (Ia + a²*Ib + a*Ic)/3
        i_neg = (ia + a2 * ib + a * ic) / 3
        # Zero sequence: (Ia + Ib + Ic)/3
        i_zero = (ia + ib + ic) / 3
        
        # Cache the results
        self._cache = {
            'v_pos_mag': abs(v_pos),
            'v_pos_ang': np.degrees(np.angle(v_pos)),
            'v_neg_mag': abs(v_neg),
            'v_neg_ang': np.degrees(np.angle(v_neg)),
            'v_zero_mag': abs(v_zero),
            'v_zero_ang': np.degrees(np.angle(v_zero)),
            'i_pos_mag': abs(i_pos),
            'i_pos_ang': np.degrees(np.angle(i_pos)),
            'i_neg_mag': abs(i_neg),
            'i_neg_ang': np.degrees(np.angle(i_neg)),
            'i_zero_mag': abs(i_zero),
            'i_zero_ang': np.degrees(np.angle(i_zero)),
            'unbalance_factor_v': 100 * abs(v_neg) / abs(v_pos) if abs(v_pos) > 0 else 0,
            'unbalance_factor_i': 100 * abs(i_neg) / abs(i_pos) if abs(i_pos) > 0 else 0
        }
        self._cache_key = cache_key
        
        logger.debug("Sequence Components Calculated:")
        logger.debug(f"Voltage Positive: {self._cache['v_pos_mag']:.2f} V ∠{self._cache['v_pos_ang']:.2f}°")
        logger.debug(f"Voltage Negative: {self._cache['v_neg_mag']:.2f} V ∠{self._cache['v_neg_ang']:.2f}°")
        logger.debug(f"Voltage Zero: {self._cache['v_zero_mag']:.2f} V ∠{self._cache['v_zero_ang']:.2f}°")
        logger.debug(f"Current Positive: {self._cache['i_pos_mag']:.2f} A ∠{self._cache['i_pos_ang']:.2f}°")
        logger.debug(f"Current Negative: {self._cache['i_neg_mag']:.2f} A ∠{self._cache['i_neg_ang']:.2f}°")
        logger.debug(f"Current Zero: {self._cache['i_zero_mag']:.2f} A ∠{self._cache['i_zero_ang']:.2f}°")
        logger.debug(f"Voltage Unbalance: {self._cache['unbalance_factor_v']:.2f}%")
        logger.debug(f"Current Unbalance: {self._cache['unbalance_factor_i']:.2f}%")
    
    # Voltage Properties
    @Property(float, notify=dataChanged)
    def voltageA(self):
        return self._voltageA
    
    @voltageA.setter
    def voltageA(self, value):
        if self._voltageA != value and value >= 0:
            self._voltageA = value
            self._calculate_sequence_components()
            self.dataChanged.emit()
    
    @Property(float, notify=dataChanged)
    def voltageB(self):
        return self._voltageB
    
    @voltageB.setter
    def voltageB(self, value):
        if self._voltageB != value and value >= 0:
            self._voltageB = value
            self._calculate_sequence_components()
            self.dataChanged.emit()
    
    @Property(float, notify=dataChanged)
    def voltageC(self):
        return self._voltageC
    
    @voltageC.setter
    def voltageC(self, value):
        if self._voltageC != value and value >= 0:
            self._voltageC = value
            self._calculate_sequence_components()
            self.dataChanged.emit()
    
    @Property(float, notify=dataChanged)
    def voltageAngleA(self):
        return self._voltageAngleA
    
    @voltageAngleA.setter
    def voltageAngleA(self, value):
        if self._voltageAngleA != value:
            self._voltageAngleA = value
            self._calculate_sequence_components()
            self.dataChanged.emit()
    
    @Property(float, notify=dataChanged)
    def voltageAngleB(self):
        return self._voltageAngleB
    
    @voltageAngleB.setter
    def voltageAngleB(self, value):
        if self._voltageAngleB != value:
            self._voltageAngleB = value
            self._calculate_sequence_components()
            self.dataChanged.emit()
    
    @Property(float, notify=dataChanged)
    def voltageAngleC(self):
        return self._voltageAngleC
    
    @voltageAngleC.setter
    def voltageAngleC(self, value):
        if self._voltageAngleC != value:
            self._voltageAngleC = value
            self._calculate_sequence_components()
            self.dataChanged.emit()
    
    # Current Properties
    @Property(float, notify=dataChanged)
    def currentA(self):
        return self._currentA
    
    @currentA.setter
    def currentA(self, value):
        if self._currentA != value and value >= 0:
            self._currentA = value
            self._calculate_sequence_components()
            self.dataChanged.emit()
    
    @Property(float, notify=dataChanged)
    def currentB(self):
        return self._currentB
    
    @currentB.setter
    def currentB(self, value):
        if self._currentB != value and value >= 0:
            self._currentB = value
            self._calculate_sequence_components()
            self.dataChanged.emit()
    
    @Property(float, notify=dataChanged)
    def currentC(self):
        return self._currentC
    
    @currentC.setter
    def currentC(self, value):
        if self._currentC != value and value >= 0:
            self._currentC = value
            self._calculate_sequence_components()
            self.dataChanged.emit()
    
    @Property(float, notify=dataChanged)
    def currentAngleA(self):
        return self._currentAngleA
    
    @currentAngleA.setter
    def currentAngleA(self, value):
        if self._currentAngleA != value:
            self._currentAngleA = value
            self._calculate_sequence_components()
            self.dataChanged.emit()
    
    @Property(float, notify=dataChanged)
    def currentAngleB(self):
        return self._currentAngleB
    
    @currentAngleB.setter
    def currentAngleB(self, value):
        if self._currentAngleB != value:
            self._currentAngleB = value
            self._calculate_sequence_components()
            self.dataChanged.emit()
    
    @Property(float, notify=dataChanged)
    def currentAngleC(self):
        return self._currentAngleC
    
    @currentAngleC.setter
    def currentAngleC(self, value):
        if self._currentAngleC != value:
            self._currentAngleC = value
            self._calculate_sequence_components()
            self.dataChanged.emit()
    
    # Sequence Component Results (Voltage)
    @Property(float, notify=dataChanged)
    def voltagePositiveMagnitude(self):
        self._calculate_sequence_components()
        return self._cache.get('v_pos_mag', 0.0)
    
    @Property(float, notify=dataChanged)
    def voltagePositiveAngle(self):
        self._calculate_sequence_components()
        return self._cache.get('v_pos_ang', 0.0)
    
    @Property(float, notify=dataChanged)
    def voltageNegativeMagnitude(self):
        self._calculate_sequence_components()
        return self._cache.get('v_neg_mag', 0.0)
    
    @Property(float, notify=dataChanged)
    def voltageNegativeAngle(self):
        self._calculate_sequence_components()
        return self._cache.get('v_neg_ang', 0.0)
    
    @Property(float, notify=dataChanged)
    def voltageZeroMagnitude(self):
        self._calculate_sequence_components()
        return self._cache.get('v_zero_mag', 0.0)
    
    @Property(float, notify=dataChanged)
    def voltageZeroAngle(self):
        self._calculate_sequence_components()
        return self._cache.get('v_zero_ang', 0.0)
    
    # Sequence Component Results (Current)
    @Property(float, notify=dataChanged)
    def currentPositiveMagnitude(self):
        self._calculate_sequence_components()
        return self._cache.get('i_pos_mag', 0.0)
    
    @Property(float, notify=dataChanged)
    def currentPositiveAngle(self):
        self._calculate_sequence_components()
        return self._cache.get('i_pos_ang', 0.0)
    
    @Property(float, notify=dataChanged)
    def currentNegativeMagnitude(self):
        self._calculate_sequence_components()
        return self._cache.get('i_neg_mag', 0.0)
    
    @Property(float, notify=dataChanged)
    def currentNegativeAngle(self):
        self._calculate_sequence_components()
        return self._cache.get('i_neg_ang', 0.0)
    
    @Property(float, notify=dataChanged)
    def currentZeroMagnitude(self):
        self._calculate_sequence_components()
        return self._cache.get('i_zero_mag', 0.0)
    
    @Property(float, notify=dataChanged)
    def currentZeroAngle(self):
        self._calculate_sequence_components()
        return self._cache.get('i_zero_ang', 0.0)
    
    # Additional metrics
    @Property(float, notify=dataChanged)
    def voltageUnbalanceFactor(self):
        self._calculate_sequence_components()
        return self._cache.get('unbalance_factor_v', 0.0)
    
    @Property(float, notify=dataChanged)
    def currentUnbalanceFactor(self):
        self._calculate_sequence_components()
        return self._cache.get('unbalance_factor_i', 0.0)
    
    # QML-callable slots for convenience
    @Slot(float)
    def setVoltageA(self, value):
        self.voltageA = value
    
    @Slot(float)
    def setVoltageB(self, value):
        self.voltageB = value
    
    @Slot(float)
    def setVoltageC(self, value):
        self.voltageC = value
    
    @Slot(float)
    def setVoltageAngleA(self, value):
        self.voltageAngleA = value
    
    @Slot(float)
    def setVoltageAngleB(self, value):
        self.voltageAngleB = value
    
    @Slot(float)
    def setVoltageAngleC(self, value):
        self.voltageAngleC = value
    
    @Slot(float)
    def setCurrentA(self, value):
        self.currentA = value
    
    @Slot(float)
    def setCurrentB(self, value):
        self.currentB = value
    
    @Slot(float)
    def setCurrentC(self, value):
        self.currentC = value
    
    @Slot(float)
    def setCurrentAngleA(self, value):
        self.currentAngleA = value
    
    @Slot(float)
    def setCurrentAngleB(self, value):
        self.currentAngleB = value
    
    @Slot(float)
    def setCurrentAngleC(self, value):
        self.currentAngleC = value
    
    @Slot()
    def resetToBalanced(self):
        """Reset to balanced system with default values"""
        self._voltageA = 230.0
        self._voltageB = 230.0
        self._voltageC = 230.0
        self._voltageAngleA = 0.0
        self._voltageAngleB = -120.0
        self._voltageAngleC = 120.0
        self._currentA = 100.0
        self._currentB = 100.0
        self._currentC = 100.0
        self._currentAngleA = -30.0
        self._currentAngleB = -150.0
        self._currentAngleC = 90.0
        self._calculate_sequence_components()
        self.dataChanged.emit()
    
    @Slot()
    def createUnbalancedExample(self):
        """Create an unbalanced system example"""
        self._voltageA = 230.0
        self._voltageB = 215.0
        self._voltageC = 245.0
        self._voltageAngleA = 0.0
        self._voltageAngleB = -115.0
        self._voltageAngleC = 125.0
        self._currentA = 100.0
        self._currentB = 85.0
        self._currentC = 110.0
        self._currentAngleA = -30.0
        self._currentAngleB = -145.0
        self._currentAngleC = 95.0
        self._calculate_sequence_components()
        self.dataChanged.emit()
    
    @Slot(str)
    def createFaultExample(self, fault_type):
        """Create a fault example"""
        # Start with balanced system
        self.resetToBalanced()
        
        if fault_type == "Single Line-to-Ground":
            # Phase A to ground fault
            self._voltageA = 50.0  # Voltage on faulted phase drops
            self._currentA = 500.0  # Current on faulted phase increases
            self._currentAngleA = -10.0  # More resistive
        elif fault_type == "Line-to-Line":
            # Phase B to C fault
            self._voltageB = 180.0
            self._voltageC = 180.0
            self._voltageAngleB = -150.0
            self._voltageAngleC = 150.0
            self._currentB = 400.0
            self._currentC = 400.0
            self._currentAngleB = -150.0
            self._currentAngleC = 30.0
        elif fault_type == "Double Line-to-Ground":
            # Phase B and C to ground
            self._voltageB = 40.0
            self._voltageC = 40.0
            self._currentB = 450.0
            self._currentC = 450.0
        elif fault_type == "Three-Phase":
            # Three-phase fault (balanced)
            self._voltageA = 80.0
            self._voltageB = 80.0
            self._voltageC = 80.0
            self._currentA = 300.0
            self._currentB = 300.0
            self._currentC = 300.0
        
        self._calculate_sequence_components()
        self.dataChanged.emit()
    
    @Slot()
    def exportReport(self):
        """Export sequence component analysis to PDF"""
        try:
            # Create timestamp for filename
            from datetime import datetime
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get save location using FileSaver
            pdf_file = self._file_saver.get_save_filepath("pdf", f"sequence_component_report_{timestamp}")
            if not pdf_file:
                self.exportComplete.emit(False, "PDF export canceled")
                return False
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Determine system status, dominant issue and recommendation
            system_status = ""
            dominant_issue = ""
            recommendation = ""
            
            # Calculate unbalance factors (just in case cache is not updated)
            self._calculate_sequence_components()
            v_unbalance = self._cache.get('unbalance_factor_v', 0)
            i_unbalance = self._cache.get('unbalance_factor_i', 0)
            
            # Voltage magnitudes 
            v_pos_mag = self._cache.get('v_pos_mag', 0)
            v_neg_mag = self._cache.get('v_neg_mag', 0)
            v_zero_mag = self._cache.get('v_zero_mag', 0)
            
            # Determine system status
            if v_unbalance <= 1.0 and i_unbalance <= 5.0:
                system_status = "Balanced System"
            elif v_unbalance <= 2.0 and i_unbalance <= 10.0:
                system_status = "Minor Unbalance"
            elif v_zero_mag / (v_pos_mag if v_pos_mag > 0 else 1) > 0.05:
                system_status = "Ground Fault Likely"
            else:
                system_status = "Significant Unbalance"
            
            # Determine dominant issue
            if v_zero_mag / (v_pos_mag if v_pos_mag > 0 else 1) > 0.05:
                dominant_issue = "Ground Fault (Zero Sequence)"
                recommendation = "Check for ground faults"
            elif v_neg_mag / (v_pos_mag if v_pos_mag > 0 else 1) > 0.05:
                dominant_issue = "Phase-Phase Unbalance (Negative Sequence)"
                recommendation = "Redistribute single-phase loads"
            else:
                dominant_issue = "Minor Phase Imbalance"
                recommendation = "Monitor for changes"
            
            # Determine fault type (if available)
            fault_type = "Custom"
            if v_unbalance <= 1.0 and i_unbalance <= 5.0:
                fault_type = "Balanced System"
            elif v_zero_mag / (v_pos_mag if v_pos_mag > 0 else 1) > 0.2 and v_neg_mag / (v_pos_mag if v_pos_mag > 0 else 1) > 0.2:
                fault_type = "Single Line-to-Ground Fault"
            elif v_neg_mag / (v_pos_mag if v_pos_mag > 0 else 1) > 0.2 and v_zero_mag / (v_pos_mag if v_pos_mag > 0 else 1) < 0.05:
                fault_type = "Line-to-Line Fault"
            elif v_zero_mag / (v_pos_mag if v_pos_mag > 0 else 1) > 0.1 and v_neg_mag / (v_pos_mag if v_pos_mag > 0 else 1) > 0.1:
                fault_type = "Double Line-to-Ground Fault"
            
            # Prepare data for PDF
            data = {
                'voltage_a': self._voltageA,
                'voltage_b': self._voltageB,
                'voltage_c': self._voltageC,
                'voltage_angle_a': self._voltageAngleA,
                'voltage_angle_b': self._voltageAngleB,
                'voltage_angle_c': self._voltageAngleC,
                'current_a': self._currentA,
                'current_b': self._currentB,
                'current_c': self._currentC,
                'current_angle_a': self._currentAngleA,
                'current_angle_b': self._currentAngleB,
                'current_angle_c': self._currentAngleC,
                'v_pos_mag': self._cache.get('v_pos_mag', 0),
                'v_pos_ang': self._cache.get('v_pos_ang', 0),
                'v_neg_mag': self._cache.get('v_neg_mag', 0),
                'v_neg_ang': self._cache.get('v_neg_ang', 0),
                'v_zero_mag': self._cache.get('v_zero_mag', 0),
                'v_zero_ang': self._cache.get('v_zero_ang', 0),
                'i_pos_mag': self._cache.get('i_pos_mag', 0),
                'i_pos_ang': self._cache.get('i_pos_ang', 0),
                'i_neg_mag': self._cache.get('i_neg_mag', 0),
                'i_neg_ang': self._cache.get('i_neg_ang', 0),
                'i_zero_mag': self._cache.get('i_zero_mag', 0),
                'i_zero_ang': self._cache.get('i_zero_ang', 0),
                'v_unbalance': v_unbalance,
                'i_unbalance': i_unbalance,
                'system_status': system_status,
                'dominant_issue': dominant_issue,
                'recommendation': recommendation,
                'fault_type': fault_type
            }
            
            # Generate PDF
            from utils.pdf.pdf_generator_sequence import SequencePdfGenerator
            pdf_generator = SequencePdfGenerator()
            success = pdf_generator.generate_report(data, pdf_file)
            
            # Force garbage collection
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
            from services.logger_config import configure_logger
            logger = configure_logger("qmltest", component="sequence_calculator")
            error_msg = f"Error exporting report: {str(e)}"
            logger.error(error_msg)
            self.exportComplete.emit(False, error_msg)
            return False
