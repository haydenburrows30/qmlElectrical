# Force matplotlib to use Qt backend
import matplotlib
matplotlib.use('Qt5Agg')

from PySide6.QtCore import Slot, Signal, Property, QObject
from PySide6.QtCore import *
from PySide6.QtCharts import *
from PySide6.QtWidgets import QVBoxLayout, QWidget, QApplication
from PySide6.QtQuick import QQuickPaintedItem
from PySide6.QtGui import QPainter, QPen, QColor
from PySide6.QtCore import Qt

# Matplotlib imports after backend selection
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg, NavigationToolbar2QT
from matplotlib.figure import Figure
import matplotlib.pyplot as plt

import numpy as np
import math
import electricpy as ep
from electricpy import conversions
from electricpy.visu import SeriesRLC
from electricpy.visu import phasorplot

class ResonantFreq(QObject):
    '''
    natfreq(C, L, Hz=True)
    C (float) - Capacitance Value in Farads.
    L (float) - Inductance in Henries.
    Hz (bool, optional) - Control argument to set return value in either Hz or rad/sec; default=True.
    '''

    resonantFreq = Signal(float)

    def __init__(self):
        super().__init__()
        self._capacitance = 0.0
        self._inductance = 0.0
        self._frequency = 0.0

    @Slot(float)
    def setCapacitance(self, capacitance):
        #uF
        self._capacitance = capacitance * 10E-6
        self.calculateFreq()

    @Slot(float)
    def setInductance(self, inductance):
        #mH
        self._inductance = inductance * 10E-3
        self.calculateFreq()

    def calculateFreq(self):
        if self._capacitance != 0 and self._inductance != 0:
            self._frequency =  ep.natfreq(self._capacitance, self._inductance, Hz=True)
            self.resonantFreq.emit(self._frequency)

    @Property(float, notify=resonantFreq)
    def frequency(self):
        return self._frequency

class ConversionCalculator(QObject):
    conversionResult = Signal(float)

    def __init__(self):
        super().__init__()
        self._input_value = 0.0
        self._conversion_type = ""
        self._result = 0.0  # Add this line

    @Slot(float)
    def setInputValue(self, value):
        self._input_value = value
        self.calculateConversion()

    @Slot(str)
    def setConversionType(self, conversion_type):
        self._conversion_type = conversion_type
        self.calculateConversion()

    def calculateConversion(self):
        if self._conversion_type == "watts_to_dbmw":
            if self._input_value > 0:
                self._result = ep.conversions.watts_to_dbmw(self._input_value)
            else:
                self._result = float('-inf')  # Handle divide by zero
        elif self._conversion_type == "dbmw_to_watts":
            self._result = ep.conversions.dbmw_to_watts(self._input_value)
        elif self._conversion_type == "rad_to_hz":
            self._result = ep.conversions.hertz(self._input_value)
        elif self._conversion_type == "hp_to_watts":
            self._result = self._input_value * 745.7  # 1 HP = 745.7 Watts
        elif self._conversion_type == "rpm_to_hz":
            self._result = self._input_value / 60  # 1 RPM = 1/60 Hz
        elif self._conversion_type == "radians_to_hz":
            self._result = self._input_value / (2 * math.pi)  # 1 radian/sec = 1/(2*pi) Hz
        elif self._conversion_type == "hz_to_rpm":
            self._result = self._input_value * 60  # 1 Hz = 60 RPM
        elif self._conversion_type == "watts_to_hp":
            self._result = self._input_value / 745.7  # 1 Watt = 1/745.7 HP
        # Add more conversions as needed
        else:
            self._result = 0.0

        self.conversionResult.emit(self._result)

    @Property(float, notify=conversionResult)
    def result(self):
        return self._result  # Change this line

class SeriesRLCChart(QObject):
    chartDataChanged = Signal()
    resonantFreqChanged = Signal(float)
    axisRangeChanged = Signal()  # Add new signal
    formattedDataChanged = Signal(list)  # Add new signal

    def __init__(self):
        super().__init__()
        # Set default values for 50Hz resonance:
        # f = 1/(2π√(LC))
        # For 50Hz with L = 0.1H, we need C = 1/(4π²f²L) ≈ 101.3µF
        self._resistance = 10.0     # 10 Ω for a clear peak
        self._inductance = 0.1      # 0.1 H (henries)
        self._capacitance = 101.3e-6  # 101.3 µF - will resonate at 50 Hz
        self._frequency_range = (0, 100)  # Adjust range to better show 50Hz
        self._chart_data = []
        self._resonant_freq = 0.0
        self._axis_x_min = 0
        self._axis_x_max = 100
        self._axis_y_min = 0
        self._axis_y_max = 1
        self._formatted_points = []
        self.generateChartData()

    @Slot(float)
    def setResistance(self, resistance):
        self._resistance = resistance
        self.generateChartData()

    @Slot(float)
    def setInductance(self, inductance):
        self._inductance = inductance
        self.generateChartData()

    @Slot(float)
    def setCapacitance(self, capacitance):
        self._capacitance = capacitance
        self.generateChartData()

    @Slot(float, float)  # Change to accept two float values
    def setFrequencyRange(self, start, end):
        """Set frequency range with separate start and end values"""
        if start >= 0 and end > start:
            self._frequency_range = (float(start), float(end))
            self.generateChartData()

    @Property(float, notify=axisRangeChanged)
    def axisXMin(self):
        return self._axis_x_min

    @Property(float, notify=axisRangeChanged)
    def axisXMax(self):
        return self._axis_x_max

    @Property(float, notify=axisRangeChanged)
    def axisYMin(self):
        return self._axis_y_min

    @Property(float, notify=axisRangeChanged)
    def axisYMax(self):
        return self._axis_y_max

    def updateAxisRanges(self):
        """Update axis ranges based on data and resonant frequency"""
        if self._chart_data:
            max_y = max(point[1] for point in self._chart_data)
            self._axis_y_max = max_y * 1.1  # Add 10% margin
            self._axis_y_min = 0
            
            # Center around resonant frequency
            self._axis_x_min = max(0, self._resonant_freq * 0.5)
            self._axis_x_max = self._resonant_freq * 1.5
            
            self.axisRangeChanged.emit()

    @Slot(QXYSeries)
    def fill_series(self, series):
        """Fill series with points using QPointF and replace"""
        points = []
        for point in self._formatted_points:
            points.append(QPointF(point['x'], point['y']))
        series.replace(points)

    def generateChartData(self):
        if self._resistance > 0 and self._inductance > 0 and self._capacitance > 0:
            try:
                # Calculate resonant frequency
                self._resonant_freq = 1.0 / (2.0 * np.pi * np.sqrt(self._inductance * self._capacitance))
                self.resonantFreqChanged.emit(self._resonant_freq)

                # Create frequency points with extra density around resonance
                f_start = max(1, self._frequency_range[0])
                f_end = self._frequency_range[1]
                
                # Create three ranges of points: before, around, and after resonance
                f1 = np.linspace(f_start, self._resonant_freq * 0.9, 200)
                f2 = np.linspace(self._resonant_freq * 0.9, self._resonant_freq * 1.1, 600)
                f3 = np.linspace(self._resonant_freq * 1.1, f_end, 200)
                
                frequencies = np.concatenate([f1, f2, f3])
                omega = 2 * np.pi * frequencies
                
                # Calculate impedance components and gain
                z_r = np.full_like(omega, self._resistance)
                z_l = omega * self._inductance
                z_c = 1 / (omega * self._capacitance)
                z_total = np.sqrt(z_r**2 + (z_l - z_c)**2)
                gain = 1 / z_total
                
                # Create data points
                valid_points = []
                for f, g in zip(frequencies, gain):
                    if not (np.isnan(g) or np.isinf(g)):
                        valid_points.append([float(f), float(g)])

                if valid_points:
                    self._chart_data = valid_points
                    self._formatted_points = [{"x": p[0], "y": p[1]} for p in valid_points]
                    max_gain = max(p[1] for p in valid_points)
                    
                    # Create resonant line points
                    self._resonant_line = [
                        {"x": float(self._resonant_freq), "y": float(0)},
                        {"x": float(self._resonant_freq), "y": float(max_gain * 1.2)}
                    ]
                    
                    self.updateAxisRanges()
                    self.formattedDataChanged.emit([self._formatted_points, self._resonant_line])
                    self.chartDataChanged.emit()
                    
            except Exception as e:
                print(f"Error generating chart data: {e}")

    @Slot(float)  # Change to accept single argument
    def zoomX(self, factor):
        """Zoom X axis by factor"""
        center = (self._axis_x_min + self._axis_x_max) / 2
        current_range = self._axis_x_max - self._axis_x_min
        new_range = current_range * factor
        self._axis_x_min = center - new_range / 2
        self._axis_x_max = center + new_range / 2
        self.axisRangeChanged.emit()

    @Slot(float)
    def panX(self, factor):
        """Pan X axis by factor of current range"""
        current_range = self._axis_x_max - self._axis_x_min
        delta = current_range * factor
        self._axis_x_min += delta
        self._axis_x_max += delta
        self.axisRangeChanged.emit()

    @Slot()
    def resetZoom(self):
        """Reset to default zoom level"""
        self._axis_x_min = self._frequency_range[0]
        self._axis_x_max = self._frequency_range[1]
        self.updateAxisRanges()

    @Property(list, notify=chartDataChanged)
    def chartData(self):
        return self._chart_data

    @Property(float, notify=resonantFreqChanged)
    def resonantFreq(self):
        return self._resonant_freq

class PhasorPlot(QQuickPaintedItem):
    magnitudeChanged = Signal()
    angleChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._magnitude = 1.0
        self._angle = 0.0
        # Enable antialiasing
        self.setAntialiasing(True)

    def paint(self, painter: QPainter):
        # Clear background
        painter.fillRect(self.boundingRect(), QColor('white'))
        
        # Calculate center point (origin of the phasor)
        center_x = self.width() / 2
        center_y = self.height() / 2
        
        # Calculate scale (use 80% of the smallest dimension)
        scale = min(self.width(), self.height()) * 0.4
        
        # Calculate end point of phasor
        angle_rad = np.deg2rad(self._angle)
        end_x = center_x + scale * self._magnitude * np.cos(angle_rad)
        end_y = center_y - scale * self._magnitude * np.sin(angle_rad)
        
        # Draw reference circle
        painter.setPen(QPen(QColor('lightgray'), 1))
        painter.drawEllipse(center_x - scale, center_y - scale, scale * 2, scale * 2)
        
        # Draw axes
        painter.setPen(QPen(QColor('gray'), 1))
        painter.drawLine(center_x - scale, center_y, center_x + scale, center_y)  # X-axis
        painter.drawLine(center_x, center_y - scale, center_x, center_y + scale)  # Y-axis
        
        # Draw phasor
        painter.setPen(QPen(QColor('red'), 2))
        painter.drawLine(center_x, center_y, end_x, end_y)
        
        # Draw end point
        painter.setPen(QPen(QColor('red'), 4))
        painter.drawPoint(end_x, end_y)
        
        # Draw magnitude and angle text
        painter.setPen(QPen(QColor('black'), 1))
        painter.drawText(10, 20, f"Magnitude: {self._magnitude:.2f}")
        painter.drawText(10, 40, f"Angle: {self._angle:.1f}°")

    @Property(float, notify=magnitudeChanged)
    def magnitude(self):
        return self._magnitude

    @magnitude.setter
    def magnitude(self, value):
        if self._magnitude != value:
            self._magnitude = value
            self.magnitudeChanged.emit()
            self.update()

    @Property(float, notify=angleChanged)
    def angle(self):
        return self._angle

    @angle.setter
    def angle(self, value):
        if self._angle != value:
            self._angle = value
            self.angleChanged.emit()
            self.update()

    @Slot(float)
    def setMagnitude(self, magnitude):
        self.magnitude = magnitude

    @Slot(float)
    def setAngle(self, angle):
        self.angle = angle