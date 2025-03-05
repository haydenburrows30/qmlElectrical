from PySide6.QtCore import Slot, Signal, Property, QObject

from PySide6.QtCore import *
from PySide6.QtCharts import *

import numpy as np

class ThreePhaseSineWaveModel(QObject):
    dataChanged = Signal()
    
    def __init__(self):
        super().__init__()
        self._frequency = 50
        self._amplitudeA = 230 * np.sqrt(2)
        self._amplitudeB = 230 * np.sqrt(2)
        self._amplitudeC = 230 * np.sqrt(2)

        self._y_scale = 1.0
        self._x_scale = 1.0
        self._sample_rate = 1000
        self._phase_shift = 120  # Phase shift for three-phase
        self._y_values_a = []; self._y_values_b = []; self._y_values_c = []
        self._rms_a = 0.0; self._rms_b = 0.0; self._rms_c = 0.0
        self._peak_a = 0.0; self._peak_b = 0.0; self._peak_c = 0.0
        self._rms_ab = 0.0; self._rms_bc = 0.0; self._rms_ca = 0.0
        self._phase_angle_a = 0.0
        self._phase_angle_b = 120.0
        self._phase_angle_c = 240.0
        self._cache = {}
        self._cache_key = None
        self._time_period = 1.0  # 1 second to show 50 cycles of 50Hz
        self.update_wave()
        
    @Slot(QXYSeries,QXYSeries,QXYSeries)
    def fill_series(self, seriesA,seriesB,seriesC):
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
    
    def _get_cache_key(self):
        """Generate a cache key based on current parameters"""
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

    def _calculate_waves_vectorized(self, t):
        """Vectorized calculation of all three phases at once"""
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

    @Slot()
    def reset(self):
        self._frequency = 50
        self._amplitudeA = 230 * np.sqrt(2)
        self._amplitudeB = 230 * np.sqrt(2)
        self._amplitudeC = 230 * np.sqrt(2)
        self._phase_angle_a = 0.0
        self._phase_angle_b = 120.0
        self._phase_angle_c = 240.0
        self.update_wave()
        self.dataChanged.emit()