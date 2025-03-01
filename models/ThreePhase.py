from PySide6.QtCore import Slot, Signal, Property, QObject

from PySide6.QtCore import *
from PySide6.QtCharts import *

import numpy as np

class ThreePhaseSineWaveModel(QObject):
    dataChanged = Signal()
    
    def __init__(self):
        super().__init__()
        self._frequency = 50
        self._amplitudeA = 330; self._amplitudeB = 330; self._amplitudeC = 330

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
        self.update_wave()
        
    @Slot(QXYSeries,QXYSeries,QXYSeries)
    def fill_series(self, seriesA,seriesB,seriesC):
        seriesA.clear();seriesB.clear();seriesC.clear()

        pointsA,pointsB,pointsC = [],[],[]

        for i in range(0,len(self._y_values_a)):
            yA,yB,yC = self._y_values_a[i],self._y_values_b[i],self._y_values_c[i]

            pointsA.append(QPointF(i, yA))
            pointsB.append(QPointF(i, yB))
            pointsC.append(QPointF(i, yC))

        seriesA.replace(pointsA)
        seriesB.replace(pointsB)
        seriesC.replace(pointsC)
    
    def update_wave(self):
        t = np.linspace(0, 2 * np.pi * self._x_scale, self._sample_rate)
        y_a = self._y_scale * self._amplitudeA * np.sin(self._frequency * t + np.radians(self._phase_angle_a))
        y_b = self._y_scale * self._amplitudeB * np.sin(self._frequency * t + np.radians(self._phase_angle_b))
        y_c = self._y_scale * self._amplitudeC * np.sin(self._frequency * t + np.radians(self._phase_angle_c))

        # Apply downsampling dynamically if the sample rate is too high
        max_points = 10000  # Limit the number of points plotted
        if len(y_a) > max_points:
            indices = np.linspace(0, len(y_a) - 1, max_points, dtype=int)
            self._y_values_a = y_a[indices].tolist()
            self._y_values_b = y_b[indices].tolist()
            self._y_values_c = y_c[indices].tolist()
        else:
            self._y_values_a = y_a.tolist()
            self._y_values_b = y_b.tolist()
            self._y_values_c = y_c.tolist()

        self._rms_a = np.sqrt(np.mean(np.square(self._y_values_a)))
        self._rms_b = np.sqrt(np.mean(np.square(self._y_values_b)))
        self._rms_c = np.sqrt(np.mean(np.square(self._y_values_c)))
        self._peak_a = abs(min(self._y_values_a)) + max(self._y_values_a)
        self._peak_b = abs(min(self._y_values_b)) + max(self._y_values_b)
        self._peak_c = abs(min(self._y_values_c)) + max(self._y_values_c)
        self._rms_ab = np.sqrt(np.mean(np.square(np.array(self._y_values_a) - np.array(self._y_values_b))))
        self._rms_bc = np.sqrt(np.mean(np.square(np.array(self._y_values_b) - np.array(self._y_values_c))))
        self._rms_ca = np.sqrt(np.mean(np.square(np.array(self._y_values_c) - np.array(self._y_values_a))))
       
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
            self.update_wave()
    
    @Slot(float)
    def setAmplitudeA(self, amp):
        if abs(self._amplitudeA - amp) > 1:  # Ignore tiny changes
            self._amplitudeA = amp
            self.update_wave()
    @Slot(float)
    def setAmplitudeB(self, amp):
        if abs(self._amplitudeB - amp) > 1:  # Ignore tiny changes
            self._amplitudeB = amp
            self.update_wave()
    @Slot(float)
    def setAmplitudeC(self, amp):
        if abs(self._amplitudeC - amp) > 1:  # Ignore tiny changes
            self._amplitudeC = amp
            self.update_wave()

    @Slot(float)
    def setPhaseAngleA(self, angle):
        if abs(self._phase_angle_a - angle) > 1:  # Ignore tiny changes
            self._phase_angle_a = angle
            self.update_wave()
            self.dataChanged.emit()

    @Slot(float)
    def setPhaseAngleB(self, angle):
        if abs(self._phase_angle_b - angle) > 1:  # Ignore tiny changes
            self._phase_angle_b = angle
            self.update_wave()
            self.dataChanged.emit()

    @Slot(float)
    def setPhaseAngleC(self, angle):
        if abs(self._phase_angle_c - angle) > 1:  # Ignore tiny changes
            self._phase_angle_c = angle
            self.update_wave()
            self.dataChanged.emit()