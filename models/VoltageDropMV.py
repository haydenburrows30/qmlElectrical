from PySide6.QtCore import Slot, Signal, Property, QObject, QAbstractTableModel, Qt
import pandas as pd
import numpy as np
import math
import os

class VoltageDropTableModel(QAbstractTableModel):
    def __init__(self, parent=None):
        super().__init__(parent)
        self._data = []
        self._headers = [
            'Size', 
            'Material', 
            'Cores', 
            'mV/A/m', 
            'Rating', 
            'V-Drop', 
            'Drop %', 
            'Status'
        ]
        
    def rowCount(self, parent=None):
        return len(self._data)
        
    def columnCount(self, parent=None):
        return len(self._headers)
        
    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
            
        if role == Qt.DisplayRole:
            value = self._data[index.row()][index.column()]
            if isinstance(value, float):
                if index.column() == 6:  # Drop % column
                    return f"{value:.1f}%"
                return f"{value:.1f}"
            return str(value)
            
        if role == Qt.BackgroundRole and index.column() == 7:
            status = self._data[index.row()][6]  # Drop %
            if status > 5:
                return Qt.red
            return Qt.green
            
    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if orientation == Qt.Horizontal and role == Qt.DisplayRole:
            return self._headers[section]
        return None

    def update_data(self, data):
        self.beginResetModel()
        self._data = data
        self.endResetModel()

class VoltageDropMVCalculator(QObject):
    """
    Voltage drop calculator using mV/A/m method according to AS/NZS 3008.
    
    Features:
    - Load cable data from CSV
    - Calculate voltage drop using mV/A/m values
    - Support for different installation methods
    - Temperature correction factors
    - Grouping factors
    """
    
    dataChanged = Signal()
    voltageDropCalculated = Signal(float)
    cablesChanged = Signal()  # Add signal for cables list
    methodsChanged = Signal()  # Add signal for installation methods
    tableDataChanged = Signal()
    conductorChanged = Signal()
    coreTypeChanged = Signal()
    voltageOptionsChanged = Signal()  # Add new signal
    selectedVoltageChanged = Signal()  # Add new signal
    diversityFactorChanged = Signal()  # Add new signal
    totalLoadChanged = Signal(float)  # Add new signal
    currentChanged = Signal(float)  # Add new signal
    saveSuccess = Signal(bool)
    saveStatusChanged = Signal(bool, str)  # Add new signal with status and message
    numberOfHousesChanged = Signal(int)  # Add new signal
    admdEnabledChanged = Signal(bool)    # Add new signal

    def __init__(self):
        super().__init__()
        self._cable_data = None
        self._current = 0.0
        self._length = 0.0
        self._selected_cable = None
        self._voltage_drop = 0.0
        self._temperature = 25  # Default temp in °C
        self._installation_method = "D1 - Underground direct buried"
        self._grouping_factor = 1.0
        self._available_cables = []  # Add property storage
        self._installation_methods = [
            "A1 - Enclosed in thermal insulation",
            "A2 - Enclosed in wall/ceiling",
            "B1 - Enclosed in conduit in wall",
            "B2 - Enclosed in trunking/conduit",
            "C - Clipped direct",
            "D1 - Underground direct buried",
            "D2 - Underground in conduit",
            "E - Free air",
            "F - Cable tray/ladder/cleated",
            "G - Spaced from surface"
        ]
        self._conductor_material = "Al"
        self._core_type = "3C+E"
        self._conductor_types = ["Cu", "Al"]
        self._core_configurations = ["1C+E", "3C+E"]
        
        # Load separate CSV files for different configurations
        self._cable_data_cu_1c = None
        self._cable_data_cu_3c = None
        self._cable_data_al_1c = None
        self._cable_data_al_3c = None
        self._load_all_cable_data()
        self._table_model = VoltageDropTableModel()
        self._load_cable_data()
        self._voltage_options = ["230V", "415V"]
        self._selected_voltage = "415V"
        self._voltage = 415.0
        self._diversity_factor = 1.0
        self._diversity_factors = None
        self._load_diversity_factors()
        self._num_houses = 1
        self._total_kva = 0.0
        self._admd_enabled = False
        self._admd_factor = 1.5  # ADMD factor for neutral calculations
        self._calculation_results = []  # Store calculation history

    def _load_all_cable_data(self):
        """Load all cable data variants."""
        try:
            self._cable_data_cu_1c = pd.read_csv("data/cable_data_cu_1c.csv")
            self._cable_data_cu_3c = pd.read_csv("data/cable_data_cu_3c.csv")
            self._cable_data_al_1c = pd.read_csv("data/cable_data_al_1c.csv")
            self._cable_data_al_3c = pd.read_csv("data/cable_data_al_3c.csv")
            self._update_current_cable_data()
        except Exception as e:
            print(f"Error loading cable data: {e}")

    def _update_current_cable_data(self):
        """Update active cable data based on current selections."""
        if self._conductor_material == "Cu":
            if self._core_type == "1C+E":
                self._cable_data = self._cable_data_cu_1c
            else:
                self._cable_data = self._cable_data_cu_3c
        else:  # Aluminum
            if self._core_type == "1C+E":
                self._cable_data = self._cable_data_al_1c
            else:
                self._cable_data = self._cable_data_al_3c

        self._available_cables = self._cable_data['size'].tolist()
        self.cablesChanged.emit()
        
        # Update selected cable if needed
        if self._available_cables:
            self._selected_cable = self._cable_data.iloc[0]
            self._calculate_voltage_drop()

    def _load_cable_data(self):
        """Load cable data from CSV file containing mV/A/m values."""
        try:
            self._cable_data = pd.read_csv("data/cable_data_mv.csv")
            self._available_cables = self._cable_data['size'].tolist()
            # Select first cable as default
            if self._available_cables:
                self._selected_cable = self._cable_data.iloc[0]
                # print(f"Selected default cable: {self._selected_cable['size']}")
            self.cablesChanged.emit()
        except Exception as e:
            print(f"Error loading cable data: {e}")
            self._cable_data = pd.DataFrame()
            self._available_cables = []

    def _load_diversity_factors(self):
        """Load diversity factors from CSV file."""
        try:
            df = pd.read_csv("data/diversity_factor.csv")
            # Rename columns to match expected names
            df.columns = ['houses', 'factor']
            self._diversity_factors = df
            # print("Loaded diversity factors:", self._diversity_factors)
        except Exception as e:
            print(f"Error loading diversity factors: {e}")
            self._diversity_factors = pd.DataFrame({'houses': [1], 'factor': [1.0]})

    def _get_diversity_factor(self, num_houses):
        """Get diversity factor based on number of houses."""
        try:
            if self._diversity_factors is None:
                return 1.0

            df = self._diversity_factors
            print(f"Looking up diversity factor for {num_houses} houses")
            
            # Find exact match first
            exact_match = df[df['houses'] == num_houses]
            if not exact_match.empty:
                factor = float(exact_match.iloc[0]['factor'])
                print(f"Found exact match: {factor}")
                return factor

            # If no exact match, interpolate
            if num_houses <= df['houses'].min():
                factor = float(df.iloc[0]['factor'])
            elif num_houses >= df['houses'].max():
                factor = float(df.iloc[-1]['factor'])
            else:
                # Find surrounding values
                idx = df['houses'].searchsorted(num_houses)
                h1, h2 = df['houses'].iloc[idx-1:idx+1]
                f1, f2 = df['factor'].iloc[idx-1:idx+1]
                
                # Linear interpolation
                factor = f1 + (f2 - f1) * (num_houses - h1) / (h2 - h1)

            print(f"Calculated diversity factor: {factor}")
            self._diversity_factor = factor
            self.diversityFactorChanged.emit()
            return factor

        except Exception as e:
            print(f"Error calculating diversity factor: {e}")
            return 1.0

    @Property(float, notify=totalLoadChanged)
    def totalKva(self):
        """Get total KVA value."""
        return self._total_kva

    @Property(float, notify=currentChanged)
    def current(self):
        """Get the current value in amperes."""
        return self._current

    @Slot(float)
    def setCurrent(self, current):
        """Set the operating current."""
        if self._current != current:
            self._current = current
            self.currentChanged.emit(current)
            self._calculate_voltage_drop()
    
    @Slot(float)
    def setLength(self, length):
        """Set the cable length in meters."""
        self._length = length
        self._calculate_voltage_drop()
    
    @Slot(str)
    def selectCable(self, cable_size):
        """Select cable size and get corresponding mV/A/m value."""
        if self._cable_data is not None:
            try:
                cable_data = self._cable_data[self._cable_data['size'] == float(cable_size)]
                if not cable_data.empty:
                    self._selected_cable = cable_data.iloc[0]
                    print(f"Selected cable: {cable_size}, mV/A/m: {self._selected_cable['mv_per_am']}")
                    self._calculate_voltage_drop()
                else:
                    print(f"Cable size {cable_size} not found in data")
            except ValueError:
                print(f"Invalid cable size format: {cable_size}")

    @Slot(float)
    def setTemperature(self, temp):
        """Set operating temperature and apply correction factor."""
        self._temperature = temp
        self._calculate_voltage_drop()
    
    @Slot(str)
    def setInstallationMethod(self, method):
        """Set installation method and apply corresponding factor."""
        self._installation_method = method
        self._calculate_voltage_drop()
    
    @Slot(float)
    def setGroupingFactor(self, factor):
        """Set grouping factor for multiple circuits."""
        self._grouping_factor = factor
        self._calculate_voltage_drop()
    
    @Slot(str)
    def setConductorMaterial(self, material):
        """Set conductor material (Cu/Al)."""
        if material in self._conductor_types and material != self._conductor_material:
            self._conductor_material = material
            self._update_current_cable_data()
            self.conductorChanged.emit()

    @Slot(str)
    def setCoreType(self, core_type):
        """Set core configuration (1C+E/3C+E)."""
        if core_type in self._core_configurations and core_type != self._core_type:
            self._core_type = core_type
            self._update_current_cable_data()
            self.coreTypeChanged.emit()

    @Slot(float)
    def setTotalKVA(self, total_kva):
        """Set total kVA and recalculate current with diversity.
        
        Applies diversity factor to number of houses rather than kVA:
        total_adjusted = kva_per_house * num_houses * diversity_factor
        """
        if total_kva > 0:
            self._total_kva = total_kva
            kva_per_house = total_kva / self._num_houses if self._num_houses > 0 else total_kva
            diversity_factor = self._get_diversity_factor(self._num_houses)
            
            # Apply diversity to number of houses instead of total kVA
            adjusted_kva = kva_per_house * self._num_houses * diversity_factor
            
            print(f"KVA per house: {kva_per_house:.2f}, Houses: {self._num_houses}, "
                  f"Diversity: {diversity_factor}, Adjusted: {adjusted_kva:.2f}")
            
            current = (adjusted_kva * 1000) / (self._voltage * math.sqrt(3))
            self.setCurrent(current)

    @Slot(int)
    def setNumberOfHouses(self, num_houses):
        """Set number of houses and update diversity factor."""
        if num_houses > 0 and self._num_houses != num_houses:
            self._num_houses = num_houses
            self._diversity_factor = self._get_diversity_factor(num_houses)
            print(f"Updated houses to {num_houses}, diversity factor: {self._diversity_factor}")
            self.numberOfHousesChanged.emit(num_houses)  # Emit signal
            self.diversityFactorChanged.emit()
            # Recalculate if we have a total kVA value
            if self._total_kva > 0:
                self.setTotalKVA(self._total_kva)

    @Slot(float)
    def setDiversityFactor(self, factor):
        """Set diversity factor for multiple houses."""
        if 0 < factor <= 1:
            self._diversity_factor = factor
            self.dataChanged.emit()

    @Slot(str)
    def setSelectedVoltage(self, voltage_option):
        """Set system voltage (230V or 415V)."""
        if voltage_option in self._voltage_options and voltage_option != self._selected_voltage:
            self._selected_voltage = voltage_option
            self._voltage = 230.0 if voltage_option == "230V" else 415.0
            self._calculate_voltage_drop()
            self.selectedVoltageChanged.emit()
            self.dataChanged.emit()

    @Slot(bool)
    def setADMDEnabled(self, enabled):
        """Enable/disable ADMD factor."""
        if self._admd_enabled != enabled:
            self._admd_enabled = enabled
            self._calculate_voltage_drop()
            self.admdEnabledChanged.emit(enabled)  # Emit signal
            print(f"ADMD {'enabled' if enabled else 'disabled'}")

    @Property(bool, notify=admdEnabledChanged)  # Update property decorator
    def admdEnabled(self):
        """Get ADMD enabled state."""
        return self._admd_enabled

    @Property('QVariantList', notify=voltageOptionsChanged)
    def voltageOptions(self):
        """Get available voltage options."""
        return self._voltage_options

    @Property(str, notify=selectedVoltageChanged)
    def selectedVoltage(self):
        """Get currently selected voltage option."""
        return self._selected_voltage

    @Property(float, notify=diversityFactorChanged)
    def diversityFactor(self):
        """Get current diversity factor."""
        return self._diversity_factor

    @Property(int, notify=numberOfHousesChanged)  # Update property decorator
    def numberOfHouses(self):
        """Get current number of houses."""
        return self._num_houses

    @Slot(float, int)
    def calculateTotalLoad(self, kva_per_house: float, num_houses: int):
        """Calculate total load and current based on per-house KVA with diversity."""
        try:
            # Calculate raw total kVA
            raw_total_kva = kva_per_house * num_houses
            
            # Get diversity factor and calculate adjusted kVA
            diversity_factor = self._get_diversity_factor(num_houses)
            adjusted_kva = raw_total_kva * diversity_factor
            
            print(f"Raw total: {raw_total_kva:.2f} kVA")
            print(f"Diversity factor: {diversity_factor}")
            print(f"Adjusted total: {adjusted_kva:.2f} kVA")
            
            # Store values
            self._num_houses = num_houses
            self._total_kva = adjusted_kva
            
            # Emit signal for QML binding
            self.totalLoadChanged.emit(adjusted_kva)
            
            # Calculate current based on voltage selection and adjusted kVA
            if self._voltage == 230.0:  # Single phase
                current = (adjusted_kva * 1000) / self._voltage  # P = VI
                print(f"Single phase current: {current:.1f}A")
            else:  # Three phase (415V)
                current = (adjusted_kva * 1000) / (self._voltage * math.sqrt(3))  # P = √3 × VI
                print(f"Three phase current: {current:.1f}A")
            
            self.setCurrent(current)
            return adjusted_kva
            
        except Exception as e:
            print(f"Error calculating total load: {e}")
            return 0.0

    @Slot()
    def reset(self):
        """Reset calculator to default values."""
        # Reset core valuess
        self._current = 0.0
        self._length = 0.0
        self._temperature = 25
        self._installation_method = "D1 - Underground direct buried"
        self._grouping_factor = 1.0
        self._conductor_material = "Al"
        self._core_type = "3C+E"
        self._selected_voltage = "415V"
        self._voltage = 415.0
        self._num_houses = 1
        self._total_kva = 0.0
        self._admd_enabled = False
        self._voltage_drop = 0.0
        
        # Clear table data
        if self._table_model:
            self._table_model.update_data([])
        
        # Emit all signals
        self.dataChanged.emit()
        self.currentChanged.emit(self._current)
        self.conductorChanged.emit()
        self.coreTypeChanged.emit()
        self.selectedVoltageChanged.emit()
        self.totalLoadChanged.emit(self._total_kva)
        self.voltageDropCalculated.emit(self._voltage_drop)
        self.tableDataChanged.emit()

    @Slot()
    def saveCurrentCalculation(self):
        """Save current calculation results."""
        try:
            if self._selected_cable is None or self._voltage_drop == 0:
                self.saveStatusChanged.emit(False, "No calculation to save")
                return

            timestamp = pd.Timestamp.now().strftime("%Y-%m-%d %H:%M:%S")
            result = {
                'timestamp': timestamp,
                'voltage_system': self._selected_voltage,
                'kva_per_house': self._total_kva / self._num_houses if self._num_houses > 0 else self._total_kva,
                'num_houses': self._num_houses,
                'diversity_factor': self._diversity_factor,
                'total_kva': self._total_kva,
                'current': self._current,
                'cable_size': float(self._selected_cable['size'].iloc[0]) if isinstance(self._selected_cable['size'], pd.Series) else float(self._selected_cable['size']),
                'conductor': self._conductor_material,
                'core_type': self._core_type,
                'length': self._length,
                'voltage_drop': self._voltage_drop,
                'drop_percent': (self._voltage_drop / self._voltage) * 100,
                'admd_enabled': self._admd_enabled
            }
            
            # Ensure the directory exists
            os.makedirs('results', exist_ok=True)
            
            # Save to CSV in results directory
            filepath = 'results/calculations_history.csv'
            df = pd.DataFrame([result])
            file_exists = os.path.isfile(filepath)
            df.to_csv(filepath, mode='a', header=not file_exists, index=False)
            
            success_msg = f"Calculation saved to {filepath}"
            print(success_msg)
            self.saveStatusChanged.emit(True, success_msg)
            
        except Exception as e:
            error_msg = f"Error saving calculation: {e}"
            print(error_msg)
            self.saveStatusChanged.emit(False, error_msg)

    def _calculate_voltage_drop(self):
        """Calculate voltage drop using mV/A/m method."""
        try:
            if self._current <= 0 or self._length <= 0:
                return

            # Apply ADMD factor if enabled and using 415V
            admd_multiplier = self._admd_factor if (self._admd_enabled and self._voltage > 230) else 1.0
            # print(f"ADMD multiplier: {admd_multiplier}, enabled: {self._admd_enabled}, voltage: {self._voltage}")

            table_data = []
            for _, cable in self._cable_data.iterrows():
                mv_per_am = float(cable['mv_per_am'])
                
                # Calculate voltage drop
                v_drop = (
                    self._current * 
                    self._length * 
                    mv_per_am * 
                    self._get_temperature_factor() * 
                    self._get_installation_factor() * 
                    self._grouping_factor * 
                    admd_multiplier /  # Apply ADMD factor
                    1000.0
                )
                
                drop_percent = (v_drop / self._voltage) * 100  # Calculate percentage
                
                # Determine status based on AS/NZS 3008.1.1
                status = "OK"
                if drop_percent > 7.0:
                    status = "SEVERE"
                elif drop_percent > 5.0:
                    status = "WARNING"
                elif drop_percent > 2.0:
                    status = "SUBMAIN"
                
                table_data.append([
                    float(cable['size']),
                    self._conductor_material,
                    self._core_type,
                    mv_per_am,
                    cable['max_current'],
                    v_drop,
                    drop_percent,
                    status
                ])
            
            self._table_model.update_data(table_data)
            self.tableDataChanged.emit()
            
            # Update single cable calculation if selected
            if self._selected_cable is not None:
                self._voltage_drop = (
                    self._current * 
                    self._length * 
                    float(self._selected_cable['mv_per_am']) * 
                    self._get_temperature_factor() * 
                    self._get_installation_factor() * 
                    self._grouping_factor *
                    admd_multiplier /
                    1000.0
                )
                self.voltageDropCalculated.emit(self._voltage_drop)
            
        except Exception as e:
            print(f"Error calculating voltage drops: {e}")

    def _get_temperature_factor(self):
        """Get temperature correction factor."""
        base_temp = 75  # °C
        return 1 + 0.004 * (self._temperature - base_temp)
    
    def _get_installation_factor(self):
        """Get installation method factor with material consideration."""
        base_factors = {
            "A1 - Enclosed in thermal insulation": 1.25,
            "A2 - Enclosed in wall/ceiling": 1.15,
            "B1 - Enclosed in conduit in wall": 1.1,
            "B2 - Enclosed in trunking/conduit": 1.1,
            "C - Clipped direct": 1.0,
            "D1 - Underground direct buried": 1.1,
            "D2 - Underground in conduit": 1.15,
            "E - Free air": 0.95,
            "F - Cable tray/ladder/cleated": 0.95,
            "G - Spaced from surface": 0.90
        }
        
        factor = base_factors.get(self._installation_method, 1.0)
        
        # Apply material-specific adjustments
        if self._conductor_material == "Al":
            factor *= 1.6  # Aluminum has higher resistance

        # Apply core configuration adjustments
        if self._core_type == "3C+E":
            factor *= 1.05  # Three-core cables have slightly higher impedance
            
        return factor
    
    @Property(float, notify=voltageDropCalculated)
    def voltageDrop(self):
        """Get calculated voltage drop in volts."""
        return self._voltage_drop
    
    @Property('QVariantList', notify=cablesChanged)  # Change return type and add notify
    def availableCables(self):
        """Get list of available cable sizes."""
        return self._available_cables
    
    @Property('QVariantList', notify=methodsChanged)  # Change return type and add notify
    def installationMethods(self):
        """Get list of available installation methods."""
        return self._installation_methods

    @Property('QVariantList', notify=conductorChanged)
    def conductorTypes(self):
        return self._conductor_types

    @Property('QVariantList', notify=coreTypeChanged)
    def coreConfigurations(self):
        return self._core_configurations

    @Property(str, notify=conductorChanged)
    def conductorMaterial(self):
        return self._conductor_material

    @Property(str, notify=coreTypeChanged)
    def coreType(self):
        return self._core_type

    @Property(QObject, notify=tableDataChanged)
    def tableModel(self):
        return self._table_model
