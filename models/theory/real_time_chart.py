from PySide6.QtCore import QObject, Signal, Property, Slot, QDateTime
import numpy as np
import os
from services.file_saver import FileSaver
from datetime import datetime

class WaveType:
    SINE = 0
    SQUARE = 1
    SAWTOOTH = 2
    TRIANGLE = 3

class RealTimeChart(QObject):
    # Add new notify signals
    dataUpdated = Signal(float, float, float, float)
    resetChart = Signal()
    runningChanged = Signal(bool)
    frequencyChanged = Signal(int, float)
    amplitudeChanged = Signal(int, float)
    offsetChanged = Signal(int, float)
    phaseChanged = Signal(int, float)
    # Add list change signals
    frequenciesChanged = Signal('QVariantList')
    amplitudesChanged = Signal('QVariantList')
    offsetsChanged = Signal('QVariantList')
    phasesChanged = Signal('QVariantList')
    saveStatusChanged = Signal(bool, str)
    # Add wave type signals
    waveTypeChanged = Signal(int, int)
    waveTypesChanged = Signal('QVariantList')

    # Add root path as class variable
    ROOT_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    def __init__(self):
        super().__init__()
        self._start_time = QDateTime.currentDateTime().toMSecsSinceEpoch() / 1000.0
        self._pause_time = 0  # Store time when paused
        self._elapsed_time = 0  # Track total elapsed time
        self._frequency = 0.5  # Base frequency for waves
        self._is_running = False  # Start in inactive state until page is active
        self._is_active = False  # Track if component is active/visible
        self._wave_types = [WaveType.SINE] * 3  # Wave types for A, B, C
        self._frequencies = [0.5, 0.7, 0.9]  # Individual frequencies
        self._amplitudes = [50.0, 50.0, 50.0]  # Individual amplitudes
        self._offsets = [150.0, 150.0, 150.0]  # Individual vertical offsets
        self._phases = [0.0, 0.0, 0.0]  # Phase shifts

        self._file_saver = FileSaver()
         # Connect file saver signal to our saveStatusChanged signal
        self._file_saver.saveStatusChanged.connect(self.saveStatusChanged)

    # Add property to expose file_saver to QML
    @Property(QObject)
    def fileSaver(self):
        return self._file_saver

    # Add property to expose wave types
    @Property('QVariantList', notify=waveTypesChanged)
    def waveTypes(self):
        return self._wave_types

    @Property(bool, notify=runningChanged)
    def isRunning(self):
        return self._is_running

    @Property('QVariantList', notify=frequenciesChanged)
    def frequencies(self):
        return self._frequencies

    @Property('QVariantList', notify=amplitudesChanged)
    def amplitudes(self):
        return self._amplitudes

    @Property('QVariantList', notify=offsetsChanged)
    def offsets(self):
        return self._offsets

    @Property('QVariantList', notify=phasesChanged)
    def phases(self):
        return self._phases

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

    def _generate_wave(self, t, wave_type, index):
        t = t + self._phases[index]  # Apply phase shift
        freq = self._frequencies[index]
        amp = self._amplitudes[index]
        offset = self._offsets[index]

        if wave_type == WaveType.SINE:
            return offset + amp * np.sin(t * freq)
        elif wave_type == WaveType.SQUARE:
            return offset + amp * np.sign(np.sin(t * freq))
        elif wave_type == WaveType.SAWTOOTH:
            # Corrected sawtooth formula
            return offset + amp * (2 * (t * freq - np.floor(t * freq)) - 1)
        else:  # TRIANGLE
            return offset + 2 * amp * abs((t * freq % 2) - 1) - amp

    @Slot(int, int)
    def setWaveType(self, series_index, wave_type):
        if 0 <= series_index < 3:
            self._wave_types[series_index] = wave_type
            # Emit signals for the specific wave type and the list
            self.waveTypeChanged.emit(series_index, wave_type)
            self.waveTypesChanged.emit(self._wave_types)

    @Slot(int, float)
    def setFrequency(self, index, value):
        if 0 <= index < 3:
            self._frequencies[index] = value
            self.frequencyChanged.emit(index, value)
            self.frequenciesChanged.emit(self._frequencies)

    @Slot(int, float)
    def setAmplitude(self, index, value):
        if 0 <= index < 3:
            self._amplitudes[index] = value
            self.amplitudeChanged.emit(index, value)
            self.amplitudesChanged.emit(self._amplitudes)

    @Slot(int, float)
    def setOffset(self, index, value):
        if 0 <= index < 3:
            self._offsets[index] = value
            self.offsetChanged.emit(index, value)
            self.offsetsChanged.emit(self._offsets)

    @Slot(int, float)
    def setPhase(self, index, value):
        if 0 <= index < 3:
            self._phases[index] = value
            self.phaseChanged.emit(index, value)
            self.phasesChanged.emit(self._phases)

    @Slot(result=bool)
    def saveConfiguration(self):
        """Save current configuration to a JSON file using FileSaver"""
        # Create a timestamp for the filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

        json_filepath = self._file_saver.get_save_filepath("json", f"realtime_{timestamp}")
        if not json_filepath:
            self.saveStatusChanged.emit(False, "JSON save canceled")
            return ""
        
        config = {
            'wave_types': self._wave_types,
            'frequencies': self._frequencies,
            'amplitudes': self._amplitudes,
            'offsets': self._offsets,
            'phases': self._phases
        }
        
        # Use FileSaver to save the configuration
        return self._file_saver.save_json(json_filepath, config, "wave_configuration")
    

    @Slot(result=bool)
    def loadConfiguration(self):
        """Load configuration from JSON file using FileSaver"""
        try:
            config = self._file_saver.load_json_with_dialog()
            
            if not config:
                self.saveStatusChanged.emit(False, "Failed to load configuration")
                return False
                
            # Update configuration values - ensure type conversion for numeric values
            self._wave_types = [int(wt) for wt in config.get('wave_types', [WaveType.SINE] * 3)]
            self._frequencies = [float(f) for f in config.get('frequencies', [0.5, 0.7, 0.9])]
            self._amplitudes = [float(a) for a in config.get('amplitudes', [50.0, 50.0, 50.0])]
            self._offsets = [float(o) for o in config.get('offsets', [150.0, 150.0, 150.0])]
            self._phases = [float(p) for p in config.get('phases', [0.0, 0.0, 0.0])]
            
            # Emit all necessary signals
            self.waveTypesChanged.emit(self._wave_types)
            self.frequenciesChanged.emit(self._frequencies)
            self.amplitudesChanged.emit(self._amplitudes)
            self.offsetsChanged.emit(self._offsets)
            self.phasesChanged.emit(self._phases)
            
            # Individual signals for each parameter to ensure all UI elements update
            for i in range(3):
                self.waveTypeChanged.emit(i, self._wave_types[i])
                self.frequencyChanged.emit(i, self._frequencies[i])
                self.amplitudeChanged.emit(i, self._amplitudes[i])
                self.offsetChanged.emit(i, self._offsets[i])
                self.phaseChanged.emit(i, self._phases[i])
            
            # Reset the chart
            self.resetChart.emit()
            
            # Signal successful loading
            self.saveStatusChanged.emit(True, "Configuration loaded successfully")
            return True
        except Exception as e:
            error_msg = f"Error loading configuration: {e}"
            print(error_msg)
            self.saveStatusChanged.emit(False, error_msg)
            return False

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
            value_a = self._generate_wave(relative_time, self._wave_types[0], 0)
            value_b = self._generate_wave(relative_time, self._wave_types[1], 1)
            value_c = self._generate_wave(relative_time, self._wave_types[2], 2)
            
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
            value_a = self._generate_wave(x_value, self._wave_types[0], 0)
            value_b = self._generate_wave(x_value, self._wave_types[1], 1)
            value_c = self._generate_wave(x_value, self._wave_types[2], 2)
            
            # Return list of dictionaries with values and colors
            return [
                {"value": float(value_a), "color": "#ff0000"},  # Red
                {"value": float(value_b), "color": "#00cc00"},  # Green
                {"value": float(value_c), "color": "#0000ff"}   # Blue
            ]
        except Exception as e:
            print(f"Error getting values: {e}")
            return []
