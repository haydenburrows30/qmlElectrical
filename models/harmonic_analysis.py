from PySide6.QtCore import QObject, Property, Signal, Slot, QPointF
import numpy as np
import math
import csv
import os
from datetime import datetime

class HarmonicAnalysisCalculator(QObject):
    """Calculator for harmonic analysis and THD calculation"""

    fundamentalChanged = Signal()
    harmonicsChanged = Signal()
    calculationsComplete = Signal()
    thdChanged = Signal()
    crestFactorChanged = Signal()  # Add new signal
    formFactorChanged = Signal()   # Add form factor signal
    waveformChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._fundamental = 100.0  # Fundamental amplitude
        self._fundamentalMagnitude = 100.0
        self._fundamentalAngle = 0.0
        self._harmonics = [0.0] * 15  # Up to 15th harmonic
        self._harmonics_dict = {1: (100.0, 0.0)}  # Dict to store harmonic orders and their values
        self._thd = 0.0
        self._cf = 0.0
        self._ff = 1.11  # Form factor (default sine wave value)
        self._individual_distortion = [100.0, 0.0, 0.0, 0.0, 0.0, 0.0]  # For display harmonics [1,3,5,7,11,13]
        self._harmonic_phases = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]  # Phases for display harmonics
        self._waveform_points = []
        self._waveform = []
        self._fundamental_wave = []  # Store fundamental waveform
        self._spectrum_points = []
        self._spectrum = []
        
        self._calculate()

    def _calculate(self):
        try:
            # Update harmonics array from dictionary input
            harmonics = [0.0] * 15  # Reset array
            phases = [0.0] * 15     # Reset phases array
            
            # Map harmonic orders to correct indices
            for order, (magnitude, phase) in self._harmonics_dict.items():
                if 1 <= order < len(harmonics):
                    harmonics[order-1] = magnitude
                    phases[order-1] = phase
            
            self._harmonics = harmonics
            
            # Calculate THD using only actual harmonics (excluding fundamental)
            if self._fundamental > 0:
                harmonics_sum = sum(h * h for h in harmonics[1:])
                self._thd = math.sqrt(harmonics_sum) / self._fundamental * 100.0
            
            # Calculate individual distortion for display harmonics [1,3,5,7,11,13]
            display_orders = [1, 3, 5, 7, 11, 13]
            self._individual_distortion = [
                (harmonics[order-1] / self._fundamental * 100.0) 
                for order in display_orders
            ]
            
            # Store phases for display harmonics
            self._harmonic_phases = [
                phases[order-1] for order in display_orders
            ]
            
            # Generate waveform - fixing the calculation error
            t = np.linspace(0, 2*np.pi, 500)
            wave = np.zeros_like(t)
            
            # Store fundamental separately
            self._fundamental_wave = (self._fundamental * np.sin(t + np.radians(phases[0]))).tolist()
            
            # Build total waveform with phase angles - FIX: iterate properly through harmonics
            for i, (amplitude, phase_deg) in enumerate(zip(harmonics, phases)):
                if amplitude > 0:
                    phase_rad = np.radians(phase_deg)
                    wave += amplitude * np.sin((i + 1) * t + phase_rad)
            
            self._waveform = wave.tolist()
            
            # Calculate crest factor
            if wave.size:
                rms = np.sqrt(np.mean(wave**2))
                if rms > 0:
                    self._cf = np.max(np.abs(wave)) / rms
                    
                    # Calculate form factor
                    average_rectified = np.mean(np.abs(wave))
                    if average_rectified > 0:
                        self._ff = rms / average_rectified
            
            # Generate QPointF ready data for more efficient plotting
            self._waveform_points = self._generate_points_array(t, wave)
            self._fundamental_points = self._generate_points_array(t, self._fundamental_wave)
            
            self.batchUpdate()
            
        except Exception as e:
            print(f"Calculation error: {e}")
            import traceback
            traceback.print_exc()  # Print full stack trace for debugging
    
    def _generate_points_array(self, x_values, y_values):
        """Convert numpy arrays to a list of QPointF for efficient plotting"""
        if isinstance(y_values, list):
            y_values = np.array(y_values)
        
        # Map x values from radians to degrees for display
        x_degrees = np.degrees(x_values)
        
        # Create list of QPointF objects
        return [QPointF(float(x), float(y)) for x, y in zip(x_degrees, y_values)]

    def batchUpdate(self):
        """Emit all signals at once to reduce update frequency"""
        self.harmonicsChanged.emit()
        self.waveformChanged.emit()
        self.crestFactorChanged.emit()
        self.formFactorChanged.emit()
        self.calculationsComplete.emit()

    # Properties and setters...
    @Property(float, notify=fundamentalChanged)
    def fundamental(self):
        return self._fundamental
    
    @fundamental.setter
    def fundamental(self, value):
        if value >= 0:
            self._fundamental = value
            self.fundamentalChanged.emit()
            self._calculate()

    @Property(list, notify=calculationsComplete)
    def harmonics(self):
        return self._harmonics
    
    @Property(float, notify=calculationsComplete)
    def thd(self):
        return self._thd

    @Property(float, notify=crestFactorChanged)
    def crestFactor(self):
        """Get Crest Factor."""
        return self._cf

    @Property(float, notify=formFactorChanged)
    def formFactor(self):
        """Get Form Factor."""
        return self._ff

    @Property(list, notify=calculationsComplete)
    def individualDistortion(self):
        return self._individual_distortion

    @Property(list, notify=calculationsComplete)
    def harmonicPhases(self):
        """Get phase angles for display harmonics."""
        return self._harmonic_phases

    @Property(list, notify=calculationsComplete)
    def waveformPoints(self):
        return self._waveform_points

    @Property(list)
    def waveform(self):
        """Get time-domain waveform points."""
        return self._waveform
        
    @Property(list)
    def fundamentalWaveform(self):
        """Get fundamental component waveform."""
        return self._fundamental_wave

    @Property(list)
    def spectrum(self):
        """Get frequency spectrum points."""
        return self._spectrum

    @Property(list)
    def fundamentalPoints(self):
        """Get fundamental waveform points as QPointF objects for efficient plotting"""
        return self._fundamental_points

    @Slot()
    def resetHarmonics(self):
        """Reset harmonics to default values (pure fundamental)."""
        self._harmonics_dict = {1: (100.0, 0.0)}  # Only fundamental at 100%
        self._calculate()

    @Slot()
    def exportData(self):
        """Export harmonic data to CSV file."""
        try:
            # Create directory if it doesn't exist
            export_dir = os.path.expanduser("~/Documents/harmonics_export")
            os.makedirs(export_dir, exist_ok=True)
            
            # Generate filename with timestamp
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{export_dir}/harmonics_data_{timestamp}.csv"
            
            with open(filename, 'w', newline='') as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(['Harmonic Order', 'Magnitude (%)', 'Phase (degrees)'])
                
                # Write data for display harmonics
                display_orders = [1, 3, 5, 7, 11, 13]
                for i, order in enumerate(display_orders):
                    writer.writerow([order, 
                                     self._individual_distortion[i], 
                                     self._harmonic_phases[i]])
                
                # Add additional results
                writer.writerow([])
                writer.writerow(['Analysis Results', ''])
                writer.writerow(['THD', f"{self._thd:.2f}%"])
                writer.writerow(['Crest Factor', f"{self._cf:.2f}"])
                writer.writerow(['Form Factor', f"{self._ff:.2f}"])
            
            print(f"Data exported to {filename}")
            return True
        except Exception as e:
            print(f"Export error: {e}")
            return False

    @Slot(float)
    def setFundamental(self, value):
        self.fundamental = value

    @Slot(int, float)
    def setHarmonic(self, index, amplitude):
        """Set the amplitude of a specific harmonic"""
        if 0 <= index < len(self._harmonics):
            self._harmonics[index] = amplitude
            self.harmonicsChanged.emit()
            self._calculate()

    @Slot(int, float, float)
    def setHarmonic(self, order, magnitude, angle=0):
        """Set magnitude and angle for a harmonic order."""
        if order > 0 and order <= len(self._harmonics):
            self._harmonics_dict[order] = (magnitude, angle)
            print(f"Setting harmonic {order} to magnitude {magnitude}, angle {angle}")  # Debug print
            self._calculate()

    @Slot(list)
    def setAllHarmonics(self, harmonics):
        """Set all harmonic amplitudes at once"""
        if len(harmonics) <= len(self._harmonics):
            self._harmonics = harmonics + [0.0] * (len(self._harmonics) - len(harmonics))
            self.harmonicsChanged.emit()
            self._calculate()

    @Slot('QVariant', list)
    def fillSeries(self, series, points):
        """Efficiently fill a QXYSeries with points using replace method"""
        if series and points:
            try:
                series.replace(points)
                return True
            except Exception as e:
                print(f"Error filling series: {e}")
                return False
        return False

    @Slot('QVariant')
    def fillWaveformSeries(self, series):
        """Efficiently fill a waveform series with calculated points"""
        return self.fillSeries(series, self._waveform_points)
        
    @Slot('QVariant')
    def fillFundamentalSeries(self, series):
        """Efficiently fill a fundamental series with calculated points"""
        return self.fillSeries(series, self._fundamental_points)

    @Slot(int)
    def prepareSpectrumPoint(self, index):
        """Get a QPointF for a spectrum point (for phase angle series)"""
        if 0 <= index < len(self._harmonic_phases):
            return QPointF(index + 0.5, self._harmonic_phases[index])
        return QPointF(0, 0)
