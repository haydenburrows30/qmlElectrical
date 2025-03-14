from PySide6.QtCore import *
from PySide6.QtCharts import *

import numpy as np

class SeriesRLCChart(QObject):
    chartDataChanged = Signal()
    resonantFreqChanged = Signal(float)
    axisRangeChanged = Signal()  # Add new signal
    formattedDataChanged = Signal(list)  # Add new signal
    grabRequested = Signal(str, float)  # Change signal definition to include scale

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
        self._axis_y_max = None  # Change to None for initial state check
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

    @Slot(float, float)
    def setFrequencyRange(self, start, end):
        """Set frequency range with separate start and end values"""
        if start >= 0 and end > start:
            self._axis_x_min = float(start)  # Update X axis minimum
            self._axis_x_max = float(end)    # Update X axis maximum
            self.axisRangeChanged.emit()     # Emit signal for axis change

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
            self._axis_y_max = max_y * 1.1
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
                f_start = max(1, 0)
                f_end = self._resonant_freq * 3
                
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
                    
                    # Always update Y axis scale
                    self._axis_y_max = max_gain * 1.1
                    self._axis_y_min = 0
                    
                    # Create resonant line points
                    self._resonant_line = [
                        {"x": float(self._resonant_freq), "y": float(0)},
                        {"x": float(self._resonant_freq), "y": float(max_gain * 1.2)}
                    ]
                    
                    self.formattedDataChanged.emit([self._formatted_points, self._resonant_line])
                    self.chartDataChanged.emit()
                    self.axisRangeChanged.emit()  # Ensure axis range is updated
                    
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
        self._axis_x_min = 0
        self._axis_x_max = 100
        self._axis_y_min = 0
        max_y = max(point[1] for point in self._chart_data) if self._chart_data else 1
        self._axis_y_max = max_y * 1.1
        self.axisRangeChanged.emit()

    @Slot()
    def resetValues(self):
        """Reset all values to defaults"""
        self._resistance = 10.0
        self._inductance = 0.1
        self._capacitance = 101.3e-6
        self.generateChartData()
        self.resetZoom()  # Call resetZoom after generating new data

    @Property(list, notify=chartDataChanged)
    def chartData(self):
        return self._chart_data

    @Property(float, notify=resonantFreqChanged)
    def resonantFreq(self):
        return self._resonant_freq

    @Slot(str, float)
    def saveChart(self, filepath, scale=2.0):
        """Save chart as image with optional scale factor"""
        try:
            # Convert QUrl to local file path
            if isinstance(filepath, QUrl):
                filepath = filepath.toLocalFile()
            elif filepath.startswith('file:///'):
                filepath = QUrl(filepath).toLocalFile()
            
            print(f"Saving chart to: {filepath} with scale {scale}")
            self.grabRequested.emit(filepath, scale)
            return True
        except Exception as e:
            print(f"Error saving chart: {e}")
            return False