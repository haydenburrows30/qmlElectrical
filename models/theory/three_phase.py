from PySide6.QtCore import Slot, Signal, Property, QObject, QPointF
from PySide6.QtCharts import QXYSeries
import numpy as np
import matplotlib
# Set non-interactive backend before importing pyplot
matplotlib.use('Agg')  # Use Agg backend which doesn't require a display
import matplotlib.pyplot as plt
import os
import tempfile
from datetime import datetime
from services.file_saver import FileSaver
from services.logger_config import configure_logger

logger = configure_logger("qmltest", component="three_phase")

class ThreePhaseSineWaveModel(QObject):
    """Three-phase sine wave generator and calculator.

    This class generates and manages three-phase electrical waveforms with configurable
    frequency, amplitude, and phase angles. It provides real-time calculations of RMS
    and peak values, with optimized caching for performance.

    Signals:
        dataChanged: Emitted when any waveform parameters are updated
        pdfExportStatusChanged: Emitted when PDF export status changes

    Properties:
        frequency (float): Wave frequency in Hz
        amplitudeA/B/C (float): Peak amplitude for each phase
        phaseAngleA/B/C (float): Phase angles in degrees
    """

    dataChanged = Signal()
    pdfExportStatusChanged = Signal(bool, str)

    def __init__(self):
        """Initialize the three-phase sine wave model with default values."""
        super().__init__()
        self._frequency = 50
        self._amplitudeA = 325.27  # 230V RMS
        self._amplitudeB = 325.27
        self._amplitudeC = 325.27
        
        # Voltage phase angles
        self._phase_angle_a = 0
        self._phase_angle_b = -120
        self._phase_angle_c = 120
        
        # Current values
        self._currentA = 100.0
        self._currentB = 100.0
        self._currentC = 100.0
        
        # Current phase angles (all 30° lag)
        self._current_angle_a = 30.0
        self._current_angle_b = -90.0  # -120° + 30°
        self._current_angle_c = 150.0  # 120° + 30°
        
        self._y_scale = 1.0
        self._x_scale = 1.0
        self._sample_rate = 1000
        self._phase_shift = 120  # Phase shift for three-phase
        self._y_values_a = []; self._y_values_b = []; self._y_values_c = []
        self._rms_a = 0.0; self._rms_b = 0.0; self._rms_c = 0.0
        self._peak_a = 0.0; self._peak_b = 0.0; self._peak_c = 0.0
        self._rms_ab = 0.0; self._rms_bc = 0.0; self._rms_ca = 0.0
        self._cache = {}
        self._cache_key = None
        self._time_period = 1.0  # 1 second to show 50 cycles of 50Hz
        self._apparent_power = 0.0
        self._reactive_power = 0.0
        self.update_wave()

        # Initialize FileSaver
        self._file_saver = FileSaver()
        
        # Connect file saver signal to our pdfExportStatusChanged signal
        self._file_saver.saveStatusChanged.connect(self.pdfExportStatusChanged)
        
    @Slot(QXYSeries,QXYSeries,QXYSeries)
    def fill_series(self, seriesA,seriesB,seriesC):
        """Fill QXYSeries with calculated wave data for plotting.
        
        Args:
            seriesA: Series for phase A
            seriesB: Series for phase B
            seriesC: Series for phase C
        """
        seriesA.clear();seriesB.clear();seriesC.clear()

        pointsA,pointsB,pointsC = [],[],[]
        
        # Scale x-axis to milliseconds
        time_points = np.linspace(0, 1000, len(self._y_values_a))  # 0 to 1000ms
        
        for i in range(len(self._y_values_a)):
            yA,yB,yC = self._y_values_a[i],self._y_values_b[i],self._y_values_c[i]
            x = time_points[i]  # Use time in milliseconds for x-axis

            pointsA.append(QPointF(x, yA))
            pointsB.append(QPointF(x, yB))
            pointsC.append(QPointF(x, yC))

        seriesA.replace(pointsA)
        seriesB.replace(pointsB)
        seriesC.replace(pointsC)
    
    def _get_cache_key(self) -> tuple:
        """Generate a unique cache key based on current wave parameters.
        
        Returns:
            tuple: Collection of parameters that affect wave calculation
        """
        return (
            self._frequency,
            self._amplitudeA,
            self._amplitudeB,
            self._amplitudeC,
            self._phase_angle_a,
            self._phase_angle_b,
            self._phase_angle_c,
            self._x_scale,
            self._y_scale,
            self._sample_rate
        )

    def _calculate_waves_vectorized(self, t: np.ndarray) -> tuple:
        """Calculate all three phase waves using vectorized operations.
        
        Args:
            t: Time array for wave calculation
            
        Returns:
            tuple: Three numpy arrays containing wave values for each phase
        """
        angles = np.array([self._phase_angle_a, self._phase_angle_b, self._phase_angle_c])
        amplitudes = np.array([self._amplitudeA, self._amplitudeB, self._amplitudeC])
        
        # Calculate angular frequency (ω = 2πf)
        omega = 2 * np.pi * self._frequency
        
        # Broadcasting to calculate all phases at once
        # Use time-based calculation instead of direct phase
        phase_terms = omega * t[:, np.newaxis] + np.radians(angles)
        waves = self._y_scale * (amplitudes * np.sin(phase_terms))
        
        return waves[:, 0], waves[:, 1], waves[:, 2]

    def update_wave(self):
        """Update wave calculations if parameters have changed.
        
        Performs vectorized calculations of wave values and updates all
        derived measurements (RMS, peak values, etc.). Uses caching to
        avoid recalculation when parameters haven't changed.
        """
        cache_key = self._get_cache_key()
        
        # Return cached values if parameters haven't changed
        if cache_key == self._cache_key and self._cache:
            return
            
        # Create time array based on actual time period
        t = np.linspace(0, self._time_period, self._sample_rate)
        y_a, y_b, y_c = self._calculate_waves_vectorized(t)
        
        # Apply downsampling if needed
        max_points = 10000
        if len(y_a) > max_points:
            indices = np.linspace(0, len(y_a) - 1, max_points, dtype=int)
            y_a = y_a[indices]
            y_b = y_b[indices]
            y_c = y_c[indices]
        
        # Calculate RMS and peak values using vectorized operations
        y_values = np.vstack((y_a, y_b, y_c))
        rms_values = np.sqrt(np.mean(np.square(y_values), axis=1))
        peak_values = np.max(np.abs(y_values), axis=1)
        
        # Calculate line-to-line RMS values
        rms_ab = np.sqrt(np.mean(np.square(y_a - y_b)))
        rms_bc = np.sqrt(np.mean(np.square(y_b - y_c)))
        rms_ca = np.sqrt(np.mean(np.square(y_c - y_a)))
        
        # Update cache
        self._cache = {
            'y_values': (y_a.tolist(), y_b.tolist(), y_c.tolist()),
            'rms_values': rms_values,
            'peak_values': peak_values,
            'line_rms': (rms_ab, rms_bc, rms_ca)
        }
        self._cache_key = cache_key
        
        # Update instance variables
        self._y_values_a, self._y_values_b, self._y_values_c = self._cache['y_values']
        self._rms_a, self._rms_b, self._rms_c = self._cache['rms_values']
        self._peak_a, self._peak_b, self._peak_c = self._cache['peak_values']
        self._rms_ab, self._rms_bc, self._rms_ca = self._cache['line_rms']
        
        # Update cache with new properties
        self._cache.update({
            'positive_seq': self.positiveSeq,
            'negative_seq': self.negativeSeq,
            'zero_seq': self.zeroSeq,
            'active_power': self.activePower,
            'thd': self.thd
        })
        
        self.dataChanged.emit()
    
    @Property(list, notify=dataChanged)
    def yValuesA(self):
        return self._y_values_a
    
    @Property(list, notify=dataChanged)
    def yValuesB(self):
        return self._y_values_b
    
    @Property(list, notify=dataChanged)
    def yValuesC(self):
        return self._y_values_c

    @Property(float, notify=dataChanged)
    def rmsA(self):
        return self._rms_a
    
    @Property(float, notify=dataChanged)
    def rmsB(self):
        return self._rms_b
    
    @Property(float, notify=dataChanged)
    def rmsC(self):
        return self._rms_c
    
    @Property(float, notify=dataChanged)
    def peakA(self):
        return self._peak_a
    
    @Property(float, notify=dataChanged)
    def peakB(self):
        return self._peak_b
    
    @Property(float, notify=dataChanged)
    def peakC(self):
        return self._peak_c

    @Property(float, notify=dataChanged)
    def rmsAB(self):
        return self._rms_ab

    @Property(float, notify=dataChanged)
    def rmsBC(self):
        return self._rms_bc

    @Property(float, notify=dataChanged)
    def rmsCA(self):
        return self._rms_ca

    @Property(float, notify=dataChanged)
    def phaseAngleA(self):
        return self._phase_angle_a

    @Property(float, notify=dataChanged)
    def phaseAngleB(self):
        return self._phase_angle_b

    @Property(float, notify=dataChanged)
    def phaseAngleC(self):
        return self._phase_angle_c

    @Property(float, notify=dataChanged)
    def positiveSeq(self):
        """Calculate positive sequence component (a = 1∠120°)"""
        a = complex(-0.5, 0.866)  # 1∠120°
        # Convert voltages to phasors with their respective angles
        va = self._rms_a * np.exp(1j * np.radians(self._phase_angle_a))
        vb = self._rms_b * np.exp(1j * np.radians(self._phase_angle_b))
        vc = self._rms_c * np.exp(1j * np.radians(self._phase_angle_c))
        # Calculate positive sequence: (Va + a*Vb + a²*Vc)/3
        return abs((va + a * vb + (a**2) * vc) / 3)

    @Property(float, notify=dataChanged)
    def negativeSeq(self):
        """Calculate negative sequence component (a² = 1∠240°)"""
        a = complex(-0.5, 0.866)  # 1∠120°
        # Convert voltages to phasors with their respective angles
        va = self._rms_a * np.exp(1j * np.radians(self._phase_angle_a))
        vb = self._rms_b * np.exp(1j * np.radians(self._phase_angle_b))
        vc = self._rms_c * np.exp(1j * np.radians(self._phase_angle_c))
        # Calculate negative sequence: (Va + a²Vb + aVc)/3
        return abs((va + (a**2) * vb + a * vc) / 3)

    @Property(float, notify=dataChanged)
    def zeroSeq(self):
        """Calculate zero sequence component
        For balanced three-phase systems, should be zero.
        For unbalanced systems, represents the average of the three phases."""
        # Convert to phasors with proper angles
        va = self._rms_a * np.exp(1j * np.radians(self._phase_angle_a))
        vb = self._rms_b * np.exp(1j * np.radians(self._phase_angle_b))
        vc = self._rms_c * np.exp(1j * np.radians(self._phase_angle_c))
        
        # Zero sequence is the average of the three phasors
        v0 = (va + vb + vc) / 3
        return abs(v0)

    @Property(float, notify=dataChanged)
    def activePower(self):
        """Calculate total active power (P = VI cos(φ)) in kW
        φ is the angle between voltage and current"""
        # For three-phase, P = √3 * VL * IL * cos(φ) for balanced systems
        # For unbalanced, sum individual phase powers
        power_a = self._rms_a * self._currentA * np.cos(np.radians(self._current_angle_a - self._phase_angle_a))
        power_b = self._rms_b * self._currentB * np.cos(np.radians(self._current_angle_b - self._phase_angle_b))
        power_c = self._rms_c * self._currentC * np.cos(np.radians(self._current_angle_c - self._phase_angle_c))
        return (power_a + power_b + power_c) / 1000.0  # Convert to kW

    @Property(float, notify=dataChanged)
    def reactivePower(self):
        """Calculate total reactive power (Q = VI sin(φ)) in kVAR
        φ is the angle between voltage and current"""
        # For three-phase, Q = √3 * VL * IL * sin(φ) for balanced systems
        # For unbalanced, sum individual phase reactive powers
        power_a = self._rms_a * self._currentA * np.sin(np.radians(self._current_angle_a - self._phase_angle_a))
        power_b = self._rms_b * self._currentB * np.sin(np.radians(self._current_angle_b - self._phase_angle_b))
        power_c = self._rms_c * self._currentC * np.sin(np.radians(self._current_angle_c - self._phase_angle_c))
        return (power_a + power_b + power_c) / 1000.0  # Convert to kVAR

    @Property(float, notify=dataChanged)
    def apparentPower(self):
        """Calculate total apparent power (S = VI) in kVA"""
        # For three-phase, S = √3 * VL * IL for balanced systems
        # For unbalanced, S = √(P² + Q²)
        power_a = self._rms_a * self._currentA
        power_b = self._rms_b * self._currentB
        power_c = self._rms_c * self._currentC
        return (power_a + power_b + power_c) / 1000.0  # Convert to kVA

    @Property(float, notify=dataChanged)
    def thd(self):
        """Calculate Total Harmonic Distortion (simplified)"""
        # For this demo, return a calculated value based on frequency
        return max(0.1, min(5.0, self._frequency / 50.0))

    @Property(float, notify=dataChanged)
    def powerFactorA(self):
        """Calculate power factor for phase A using angle difference"""
        return abs(np.cos(np.radians(self._current_angle_a - self._phase_angle_a)))

    @Property(float, notify=dataChanged)
    def powerFactorB(self):
        """Calculate power factor for phase B using angle difference"""
        return abs(np.cos(np.radians(self._current_angle_b - self._phase_angle_b)))

    @Property(float, notify=dataChanged)
    def powerFactorC(self):
        """Calculate power factor for phase C using angle difference"""
        return abs(np.cos(np.radians(self._current_angle_c - self._phase_angle_c)))

    @Property(float, notify=dataChanged)
    def averagePowerFactor(self):
        """Calculate average power factor"""
        return (self.powerFactorA + self.powerFactorB + self.powerFactorC) / 3.0

    @Slot(float)
    def setFrequency(self, freq):
        if abs(self._frequency - freq) > 1:  # Ignore tiny changes
            self._frequency = freq
            self._cache_key = None  # Invalidate cache
            self.update_wave()
    
    @Slot(float)
    def setAmplitudeA(self, amp):
        if abs(self._amplitudeA - amp) > 1:  # Ignore tiny changes
            self._amplitudeA = amp
            self._cache_key = None  # Invalidate cache
            self.update_wave()
    @Slot(float)
    def setAmplitudeB(self, amp):
        if abs(self._amplitudeB - amp) > 1:  # Ignore tiny changes
            self._amplitudeB = amp
            self._cache_key = None  # Invalidate cache
            self.update_wave()
    @Slot(float)
    def setAmplitudeC(self, amp):
        if abs(self._amplitudeC - amp) > 1:  # Ignore tiny changes
            self._amplitudeC = amp
            self._cache_key = None  # Invalidate cache
            self.update_wave()

    @Slot(float)
    def setPhaseAngleA(self, angle):
        if abs(self._phase_angle_a - angle) > 1:  # Ignore tiny changes
            self._phase_angle_a = angle
            self._cache_key = None  # Invalidate cache
            self.update_wave()
            self.dataChanged.emit()

    @Slot(float)
    def setPhaseAngleB(self, angle):
        if abs(self._phase_angle_b - angle) > 1:  # Ignore tiny changes
            self._phase_angle_b = angle
            self._cache_key = None  # Invalidate cache
            self.update_wave()
            self.dataChanged.emit()

    @Slot(float)
    def setPhaseAngleC(self, angle):
        if abs(self._phase_angle_c - angle) > 1:  # Ignore tiny changes
            self._phase_angle_c = angle
            self._cache_key = None  # Invalidate cache
            self.update_wave()
            self.dataChanged.emit()

    @Slot(float)
    def setCurrentAngleA(self, angle):
        if self._current_angle_a != angle:
            self._current_angle_a = angle
            self._cache_key = None
            self.update_wave()

    @Slot(float)
    def setCurrentAngleB(self, angle):
        if self._current_angle_b != angle:
            self._current_angle_b = angle
            self._cache_key = None
            self.update_wave()

    @Slot(float)
    def setCurrentAngleC(self, angle):
        if self._current_angle_c != angle:
            self._current_angle_c = angle
            self._cache_key = None
            self.update_wave()

    @Property(float, notify=dataChanged)
    def currentA(self):
        return self._currentA

    @Property(float, notify=dataChanged)
    def currentB(self):
        return self._currentB

    @Property(float, notify=dataChanged)
    def currentC(self):
        return self._currentC

    @Property(float, notify=dataChanged)
    def currentAngleA(self):
        return self._current_angle_a

    @Property(float, notify=dataChanged)
    def currentAngleB(self):
        return self._current_angle_b

    @Property(float, notify=dataChanged)
    def currentAngleC(self):
        return self._current_angle_c

    @Property(float, notify=dataChanged)
    def positiveSeqCurrent(self):
        """Calculate positive sequence component for current"""
        a = complex(-0.5, 0.866)  # 1∠120°
        ia = self._currentA * np.exp(1j * np.radians(self._current_angle_a))
        ib = self._currentB * np.exp(1j * np.radians(self._current_angle_b))
        ic = self._currentC * np.exp(1j * np.radians(self._current_angle_c))
        # Positive sequence: (Ia + a*Ib + a²*Ic)/3
        return abs((ia + a * ib + (a**2) * ic) / 3)

    @Property(float, notify=dataChanged)
    def negativeSeqCurrent(self):
        """Calculate negative sequence component for current"""
        a = complex(-0.5, 0.866)  # 1∠120°
        ia = self._currentA * np.exp(1j * np.radians(self._current_angle_a))
        ib = self._currentB * np.exp(1j * np.radians(self._current_angle_b))
        ic = self._currentC * np.exp(1j * np.radians(self._current_angle_c))
        # Negative sequence: (Ia + a²*Ib + a*Ic)/3
        return abs((ia + (a**2) * ib + a * ic) / 3)

    @Property(float, notify=dataChanged)
    def zeroSeqCurrent(self):
        """Calculate zero sequence component for current"""
        ia = self._currentA * np.exp(1j * np.radians(self._current_angle_a))
        ib = self._currentB * np.exp(1j * np.radians(self._current_angle_b))
        ic = self._currentC * np.exp(1j * np.radians(self._current_angle_c))
        return abs((ia + ib + ic) / 3)

    @Slot()
    def reset(self):
        """Reset all values to defaults."""
        # Set default values
        self._frequency = 50
        self._amplitudeA = 325.27  # 230V RMS
        self._amplitudeB = 325.27
        self._amplitudeC = 325.27
        
        # Reset voltage phase angles
        self._phase_angle_a = 0
        self._phase_angle_b = -120
        self._phase_angle_c = 120
        
        # Reset current magnitudes
        self._currentA = 100
        self._currentB = 100
        self._currentC = 100
        
        # Reset current phase angles (all 30° lag)
        self._current_angle_a = 30.0
        self._current_angle_b = -90.0  # -120° + 30°
        self._current_angle_c = 150.0  # 120° + 30°
        
        # Reset other properties
        self._cache_key = None
        self._y_scale = 1.0
        self._x_scale = 1.0
        self._sample_rate = 1000
        
        # Force update all values
        self.update_wave()
        # Emit change signal after all values are updated
        self.dataChanged.emit()

    @Slot(float, result=list)
    def calculate_values_at(self, t_ms):
        """Calculate voltage values for all phases at a specific time point."""
        # Convert milliseconds to seconds
        t = float(t_ms) / 1000.0
        
        # Calculate angular frequency
        omega = 2 * np.pi * self._frequency
        
        # Calculate values for each phase and convert to native Python floats
        phase_a = float(self._amplitudeA * np.sin(omega * t + np.radians(self._phase_angle_a)))
        phase_b = float(self._amplitudeB * np.sin(omega * t + np.radians(self._phase_angle_b)))
        phase_c = float(self._amplitudeC * np.sin(omega * t + np.radians(self._phase_angle_c)))
        
        return [phase_a, phase_b, phase_c]

    @Slot(float, float, result=list)
    def get_data_range(self, start_ms, end_ms):
        """Get wave data for a specific time range in milliseconds."""
        num_points = 1000
        # Ensure proper float conversion
        start_s = float(start_ms) / 1000.0
        end_s = float(end_ms) / 1000.0
        
        # Generate time points with precise spacing
        t = np.linspace(start_s, end_s, num_points)
        omega = 2 * np.pi * self._frequency
        
        # Calculate waves
        phase_a = self._amplitudeA * np.sin(omega * t + np.radians(self._phase_angle_a))
        phase_b = self._amplitudeB * np.sin(omega * t + np.radians(self._phase_angle_b))
        phase_c = self._amplitudeC * np.sin(omega * t + np.radians(self._phase_angle_c))
        
        # Convert time back to milliseconds for QML
        time_ms = t * 1000.0
        
        # Convert all numpy arrays to Python lists
        return [time_ms.tolist(), phase_a.tolist(), phase_b.tolist(), phase_c.tolist()]

    @Slot()
    def exportToPdf(self):
        """Export three-phase analysis results to PDF"""
        try:
            # Create a timestamp for the filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get save location using FileSaver
            pdf_file = self._file_saver.get_save_filepath("pdf", f"three_phase_report_{timestamp}")
            if not pdf_file:
                self.pdfExportStatusChanged.emit(False, "PDF export canceled")
                return False
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Create temporary directory for chart images
            temp_dir = tempfile.mkdtemp()
            waveform_chart_path = os.path.join(temp_dir, "waveform_chart.png")
            phasor_chart_path = os.path.join(temp_dir, "phasor_chart.png")
            
            # Generate matplotlib charts
            self._generate_waveform_chart(waveform_chart_path)
            self._generate_phasor_chart(phasor_chart_path)
            
            # Calculate voltage and current unbalance
            voltage_unbalance = (self.negativeSeq / self.positiveSeq * 100) if self.positiveSeq > 0 else 0
            current_unbalance = (self.negativeSeqCurrent / self.positiveSeqCurrent * 100) if self.positiveSeqCurrent > 0 else 0
            
            # Prepare data for PDF generator
            data = {
                'frequency': self._frequency,
                'three_wire': True,  # Assumed to be a three-wire system
                'rms_a': self._rms_a,
                'rms_b': self._rms_b,
                'rms_c': self._rms_c,
                'peak_a': self._peak_a,
                'peak_b': self._peak_b,
                'peak_c': self._peak_c,
                'current_a': self._currentA,
                'current_b': self._currentB,
                'current_c': self._currentC,
                'phase_angle_a': self._phase_angle_a,
                'phase_angle_b': self._phase_angle_b,
                'phase_angle_c': self._phase_angle_c,
                'current_angle_a': self._current_angle_a,
                'current_angle_b': self._current_angle_b,
                'current_angle_c': self._current_angle_c,
                'rms_ab': self._rms_ab,
                'rms_bc': self._rms_bc,
                'rms_ca': self._rms_ca,
                'positive_seq': self.positiveSeq,
                'negative_seq': self.negativeSeq,
                'zero_seq': self.zeroSeq,
                'positive_seq_current': self.positiveSeqCurrent,
                'negative_seq_current': self.negativeSeqCurrent,
                'zero_seq_current': self.zeroSeqCurrent,
                'voltage_unbalance': voltage_unbalance,
                'current_unbalance': current_unbalance,
                'active_power': self.activePower,
                'reactive_power': self.reactivePower,
                'apparent_power': self.apparentPower,
                'power_factor_a': self.powerFactorA,
                'power_factor_b': self.powerFactorB,
                'power_factor_c': self.powerFactorC,
                'avg_power_factor': self.averagePowerFactor,
                'thd': self.thd * 100,  # Convert to percentage
                'waveform_chart_path': waveform_chart_path if os.path.exists(waveform_chart_path) else None,
                'phasor_chart_path': phasor_chart_path if os.path.exists(phasor_chart_path) else None
            }
            
            # Generate PDF using the specialized ThreePhasePdfGenerator
            from utils.pdf.pdf_generator_three_phase import ThreePhasePdfGenerator
            pdf_generator = ThreePhasePdfGenerator()
            success = pdf_generator.generate_report(data, pdf_file)
            
            # Clean up temporary files
            try:
                if os.path.exists(waveform_chart_path):
                    os.unlink(waveform_chart_path)
                if os.path.exists(phasor_chart_path):
                    os.unlink(phasor_chart_path)
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
            error_msg = f"Error exporting three-phase report: {str(e)}"
            logger.error(error_msg)
            # Send error to QML
            self.pdfExportStatusChanged.emit(False, error_msg)
            return False
    
    def _generate_waveform_chart(self, filepath):
        """Generate a waveform chart using matplotlib and save to file
        
        Args:
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create figure
            plt.figure(figsize=(10, 6))
            
            # Generate time array for one full cycle at current frequency
            omega = 2 * np.pi * self._frequency
            t = np.linspace(0, 1/self._frequency, 1000)
            
            # Calculate waveforms
            wave_a = self._amplitudeA * np.sin(omega * t + np.radians(self._phase_angle_a))
            wave_b = self._amplitudeB * np.sin(omega * t + np.radians(self._phase_angle_b))
            wave_c = self._amplitudeC * np.sin(omega * t + np.radians(self._phase_angle_c))
            
            # Plot waveforms
            plt.plot(t * 1000, wave_a, 'r-', linewidth=2, label=f'Phase A: {self._phase_angle_a}°')
            plt.plot(t * 1000, wave_b, 'g-', linewidth=2, label=f'Phase B: {self._phase_angle_b}°')
            plt.plot(t * 1000, wave_c, 'b-', linewidth=2, label=f'Phase C: {self._phase_angle_c}°')
            
            # Set labels and title
            plt.title('Three-Phase Voltage Waveforms')
            plt.xlabel('Time (ms)')
            plt.ylabel('Voltage (V)')
            plt.grid(True)
            plt.legend()
            
            # Add system info
            plt.figtext(0.5, 0.01, 
                      f"Frequency: {self._frequency} Hz | RMS Values: A={self._rms_a:.1f}V, B={self._rms_b:.1f}V, C={self._rms_c:.1f}V", 
                      ha="center", fontsize=9, bbox={"facecolor":"lightblue", "alpha":0.2, "pad":5})
            
            # Save the figure
            plt.tight_layout(rect=[0, 0.03, 1, 0.97])
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            import gc
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating waveform chart: {e}")
            plt.close('all')  # Make sure to close figures on error
            return False
    
    def _generate_phasor_chart(self, filepath):
        """Generate a phasor diagram using matplotlib and save to file
        
        Args:
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create figure
            plt.figure(figsize=(8, 8))
            ax = plt.subplot(111, projection='polar')
            
            # Convert angles from degrees to radians
            angle_a_rad = np.radians(self._phase_angle_a)
            angle_b_rad = np.radians(self._phase_angle_b)
            angle_c_rad = np.radians(self._phase_angle_c)
            
            current_angle_a_rad = np.radians(self._current_angle_a)
            current_angle_b_rad = np.radians(self._current_angle_b)
            current_angle_c_rad = np.radians(self._current_angle_c)
            
            # Normalize magnitudes for better visualization
            v_mag = max(self._rms_a, self._rms_b, self._rms_c)
            i_mag = max(self._currentA, self._currentB, self._currentC)
            
            v_scale = 1.0
            i_scale = 0.7 * v_mag / i_mag if i_mag > 0 else 0.5  # Scale current to 70% of voltage magnitude
            
            # Plot voltage phasors using manual arrow drawing to ensure they start from center
            # For voltage phasors
            voltage_a = ax.arrow(0, 0, angle_a_rad, self._rms_a * v_scale, alpha=1, width=0.02, 
                               edgecolor='r', facecolor='r', lw=2, zorder=5, 
                               length_includes_head=True)
            voltage_b = ax.arrow(0, 0, angle_b_rad, self._rms_b * v_scale, alpha=1, width=0.02, 
                               edgecolor='g', facecolor='g', lw=2, zorder=5, 
                               length_includes_head=True)
            voltage_c = ax.arrow(0, 0, angle_c_rad, self._rms_c * v_scale, alpha=1, width=0.02, 
                               edgecolor='b', facecolor='b', lw=2, zorder=5, 
                               length_includes_head=True)
            
            # For current phasors (with lighter alpha to differentiate)
            current_a = ax.arrow(0, 0, current_angle_a_rad, self._currentA * i_scale, alpha=0.7, width=0.02, 
                                edgecolor='r', facecolor='r', lw=1, zorder=4, linestyle='--', 
                                length_includes_head=True)
            current_b = ax.arrow(0, 0, current_angle_b_rad, self._currentB * i_scale, alpha=0.7, width=0.02, 
                                edgecolor='g', facecolor='g', lw=1, zorder=4, linestyle='--', 
                                length_includes_head=True)
            current_c = ax.arrow(0, 0, current_angle_c_rad, self._currentC * i_scale, alpha=0.7, width=0.02, 
                                edgecolor='b', facecolor='b', lw=1, zorder=4, linestyle='--', 
                                length_includes_head=True)
            
            # Create a custom legend
            from matplotlib.patches import Patch
            v_a_legend = Patch(facecolor='r', edgecolor='r', label=f'Va: {self._rms_a:.1f}V ∠{self._phase_angle_a}°')
            v_b_legend = Patch(facecolor='g', edgecolor='g', label=f'Vb: {self._rms_b:.1f}V ∠{self._phase_angle_b}°')
            v_c_legend = Patch(facecolor='b', edgecolor='b', label=f'Vc: {self._rms_c:.1f}V ∠{self._phase_angle_c}°')
            
            i_a_legend = Patch(facecolor='r', edgecolor='r', alpha=0.5, label=f'Ia: {self._currentA:.1f}A ∠{self._current_angle_a}°')
            i_b_legend = Patch(facecolor='g', edgecolor='g', alpha=0.5, label=f'Ib: {self._currentB:.1f}A ∠{self._current_angle_b}°')
            i_c_legend = Patch(facecolor='b', edgecolor='b', alpha=0.5, label=f'Ic: {self._currentC:.1f}A ∠{self._current_angle_c}°')
            
            # Customize the plot
            ax.set_title('Voltage and Current Phasors')
            ax.set_theta_zero_location('E')  # 0 degrees at the right
            ax.set_theta_direction(-1)  # Clockwise rotation
            ax.grid(True)
            
            # Set the radius limit to ensure all phasors are visible
            max_radius = max(
                self._rms_a * v_scale, 
                self._rms_b * v_scale, 
                self._rms_c * v_scale,
                self._currentA * i_scale,
                self._currentB * i_scale,
                self._currentC * i_scale
            )
            ax.set_rlim(0, max_radius * 1.2)  # Add 20% margin
            
            # Add custom legend
            ax.legend(handles=[v_a_legend, v_b_legend, v_c_legend, i_a_legend, i_b_legend, i_c_legend],
                    loc='lower center', bbox_to_anchor=(0.5, -0.15), ncol=3)
            
            # Save the figure
            plt.tight_layout()
            plt.savefig(filepath, dpi=150, bbox_inches='tight')
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            import gc
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating phasor chart: {e}")
            plt.close('all')  # Make sure to close figures on error
            return False