from PySide6.QtCore import QObject, Signal, Property, Slot, QDateTime
import numpy as np

class RealTimeChart(QObject):
    dataUpdated = Signal(float, float, float, float)  # time, a, b, c
    resetChart = Signal()  # Add new signal for chart reset
    runningChanged = Signal(bool)  # New signal for running state

    def __init__(self):
        super().__init__()
        self._start_time = QDateTime.currentDateTime().toMSecsSinceEpoch() / 1000.0
        self._pause_time = 0  # Store time when paused
        self._elapsed_time = 0  # Track total elapsed time
        self._frequency = 0.5  # Base frequency for waves
        self._is_running = False  # Start in inactive state until page is active
        self._is_active = False  # Track if component is active/visible

    @Property(bool, notify=runningChanged)
    def isRunning(self):
        return self._is_running

    @Slot()
    def toggleRunning(self):
        self._is_running = not self._is_running
        current_time = QDateTime.currentDateTime().toMSecsSinceEpoch() / 1000.0
        
        if not self._is_running:
            # Store the elapsed time when pausing
            self._pause_time = current_time
        else:
            # Adjust start time to account for pause duration
            pause_duration = current_time - self._pause_time
            self._start_time += pause_duration
            
        self.runningChanged.emit(self._is_running)

    @Slot()
    def restart(self):
        self._start_time = QDateTime.currentDateTime().toMSecsSinceEpoch() / 1000.0
        self._pause_time = 0
        self._elapsed_time = 0
        self._is_running = True
        self.resetChart.emit()
        self.runningChanged.emit(self._is_running)
        
    @Slot(bool)
    def activate(self, active):
        """Activate or deactivate chart updates when page visibility changes"""
        self._is_active = active
        if active:
            # Reset the start time and chart when becoming active
            self._start_time = QDateTime.currentDateTime().toMSecsSinceEpoch() / 1000.0
            self._is_running = True
            self.resetChart.emit()
            self.runningChanged.emit(self._is_running)
        else:
            # Stop running when page is inactive
            self._is_running = False
            self.runningChanged.emit(self._is_running)

    @Slot()
    def update(self):
        if not self._is_running or not self._is_active:
            return False
        try:
            current_time = QDateTime.currentDateTime().toMSecsSinceEpoch() / 1000.0
            relative_time = current_time - self._start_time  # Time from start
            
            # Reset start time and emit reset signal at 30 seconds
            if relative_time > 30:
                self._start_time = current_time
                relative_time = 0
                self.resetChart.emit()  # Signal to clear the chart
            
            # Generate waves using relative time
            value_a = 150 + 50 * np.sin(relative_time * self._frequency)
            value_b = 150 + 50 * np.cos(relative_time * self._frequency * 1.4)
            value_c = 150 + 50 * np.sin(relative_time * self._frequency * 1.8)
            
            self.dataUpdated.emit(relative_time, value_a, value_b, value_c)
            return True
        except Exception as e:
            print(f"Error in update: {e}")
            return False

    @Slot(float, result='QVariantList')
    def getValuesAtTime(self, x_value):
        """Get interpolated values at given time point"""
        try:
            # Generate values at specific time point
            value_a = 150 + 50 * np.sin(x_value * self._frequency)
            value_b = 150 + 50 * np.cos(x_value * self._frequency * 1.4)
            value_c = 150 + 50 * np.sin(x_value * self._frequency * 1.8)
            
            # Return list of dictionaries with values and colors
            return [
                {"value": float(value_a), "color": "#ff0000"},  # Red
                {"value": float(value_b), "color": "#00cc00"},  # Green
                {"value": float(value_c), "color": "#0000ff"}   # Blue
            ]
        except Exception as e:
            print(f"Error getting values: {e}")
            return []
