from PySide6.QtCore import QObject, Signal, Slot, Property

import csv
import math

class CableData:
    def __init__(self):
        self.cable_types = {}

    def load_csv(self, csv_file):
        self.cable_types.clear()
        with open(csv_file, newline='', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            for row in reader:
                cable_type = row['Cable Type']
                resistance = float(row['Resistance'])
                reactance = float(row['Reactance'])
                self.cable_types[cable_type] = (resistance, reactance)

    def get_cable_types(self):
        return list(self.cable_types.keys())

    def get_resistance_reactance(self, cable_type):
        return self.cable_types.get(cable_type, (0.0, 0.0))

class VoltageDropCalculator:
    def __init__(self, cable_data, cable_type="", power=0.0, voltage=415.0, current=0.0, length=0.0, starting_voltage=0.0,
                    evaluation_threshold=0.0, power_factor=0.8, phase_type="Three Phase"):
        """
        Constructor
        :param current: Current in A
        :param length: length in m (changed to km in calculation)
        :param starting_voltage: voltage to calculate percentage drop in %
        :param evaluation_threshold: voltage percentage threshold in %
        :param power_factor: power factor in unitless
        :param phase_type: single or three phase
        :param resistance: resistance from csv in ohms/km
        :param reactance: reactance from csv in ohms/km
        :param cable_type: name of cable
        :param cable_data: resistance and reactance of cable_type
        """     
        
        self.cable_data = cable_data
        self.cable_type = cable_type
        self.power = power
        self.voltage = voltage
        self.resistance, self.reactance = self.cable_data.get_resistance_reactance(cable_type)
        self.current = current
        self.length = length / 1000  # Convert meters to km
        self.starting_voltage = starting_voltage
        self.evaluation_threshold = evaluation_threshold
        self.voltage_drop = 0.0
        self.percentage_drop = 0.0
        self.pass_fail = "Pass"
        self.power_factor = power_factor
        self.phase_type = phase_type
        self.calculate()
    
    def calculate(self):
        self.resistance, self.reactance = self.cable_data.get_resistance_reactance(self.cable_type)

        # if self.current == 0 and self.power > 0:
        #     if self.voltage > 0 and self.power_factor > 0:
        #         if self.phase_type == "Three-Phase":
        #             self.current = (self.power * 1000) / (1.732 * self.voltage * self.power_factor)
        #         else:  # Single-Phase
        #             self.current = (self.power * 1000) / (self.voltage * self.power_factor)
        # elif self.current > 0:
        #     self.power = 0  # If user enters current, ignore power

        # print(self.current)

        angle = math.acos(self.power_factor)

        voltage_drop_factor = 2 if self.phase_type == "Single Phase" else math.sqrt(3)
        self.voltage_drop = voltage_drop_factor * self.current * (self.resistance * math.cos(angle) + self.reactance * math.sin(angle)) * self.length

        if self.starting_voltage > 0:
            self.percentage_drop = (self.voltage_drop / self.starting_voltage) * 100
        else:
            self.percentage_drop = 0.0

        if self.evaluation_threshold == 0:
            self.pass_fail = ""
        elif self.percentage_drop > self.evaluation_threshold:
            self.pass_fail = "Fail"
        else: self.pass_fail = "Pass"

class VoltageDropModel(QObject):
    voltageDropChanged = Signal()
    csvLoaded = Signal()
    chartDataChanged = Signal()

    def __init__(self, csv_file="cable_data.csv"):
        super().__init__()
        self.cable_data = CableData()
        self.calculator = VoltageDropCalculator(self.cable_data)
        self.chart_data = []

        if csv_file:
            self.load_csv_file(csv_file)

    @Slot(str)
    def load_csv_file(self, file_path):
        if file_path:
            self.cable_data.load_csv(file_path)
            self.csvLoaded.emit()

            # Automatically select the first cable type and trigger calculation
            cable_types = self.cable_data.get_cable_types()
            if cable_types:
                self.cable_type = cable_types[0]

    # Cable Type Property

    @Property('QStringList', notify=csvLoaded)
    def cable_types(self):
        return self.cable_data.get_cable_types()

    @Property(str, notify=voltageDropChanged)
    def cable_type(self):
        return self.calculator.cable_type

    @cable_type.setter
    def cable_type(self, value):
        if self.calculator.cable_type != value:
            self.calculator.cable_type = value
            self.calculator.calculate()
            self.voltageDropChanged.emit()

    # Current Property
    @Property(float, notify=voltageDropChanged)
    def current(self):
        return self.calculator.current

    @current.setter
    def current(self, value):
        self.calculator.current = value
        self.calculator.power = 0  # Reset power if current is manually entered
        self.calculator.calculate()
        self.voltageDropChanged.emit()

    # Length Property
    @Property(float, notify=voltageDropChanged)
    def length(self):
        return self.calculator.length * 1000  # Convert km to meters

    @length.setter
    def length(self, value):
        self.calculator.length = value / 1000  # Convert meters to km
        self.calculator.calculate()
        self.voltageDropChanged.emit()

    # Starting Voltage Property
    @Property(float, notify=voltageDropChanged)
    def starting_voltage(self):
        return self.calculator.starting_voltage

    @starting_voltage.setter
    def starting_voltage(self, value):
        self.calculator.starting_voltage = value
        self.calculator.calculate()
        self.voltageDropChanged.emit()

    # Evaluation Threshold Property
    @Property(float, notify=voltageDropChanged)
    def evaluation_threshold(self):
        return self.calculator.evaluation_threshold

    @evaluation_threshold.setter
    def evaluation_threshold(self, value):
        self.calculator.evaluation_threshold = value
        self.calculator.calculate()
        self.voltageDropChanged.emit()

    # Voltage Drop Property
    @Property(float, notify=voltageDropChanged)
    def voltage_drop(self):
        return self.calculator.voltage_drop

    # Percentage Drop Property
    @Property(float, notify=voltageDropChanged)
    def percentage_drop(self):
        return self.calculator.percentage_drop

    # Pass/Fail Property
    @Property(str, notify=voltageDropChanged)
    def pass_fail(self):
        return self.calculator.pass_fail
    
     # Power Factor Property
    @Property(float, notify=voltageDropChanged)
    def power_factor(self):
        return self.calculator.power_factor

    @power_factor.setter
    def power_factor(self, value):
        self.calculator.power_factor = value
        self.calculator.calculate()
        self.voltageDropChanged.emit()

    # Phase Type Property
    @Property(str, notify=voltageDropChanged)
    def phase_type(self):
        return self.calculator.phase_type

    @phase_type.setter
    def phase_type(self, value):
        if value in ["Single Phase", "Three Phase"]:
            self.calculator.phase_type = value
            self.calculator.calculate()
            self.voltageDropChanged.emit()

    @Property(float, notify=voltageDropChanged)
    def power(self):
        return self.calculator.power

    @power.setter
    def power(self, value):
        self.calculator.power = value
        self.calculator.current = 0  # Reset current if power is manually entered
        self.calculator.calculate()
        self.voltageDropChanged.emit()

    @Slot()
    def update_chart(self):
        """Calculate voltage drop for all cable types and update chart data."""
        self.chart_data.clear()
        for cable_type in self.cable_data.get_cable_types():
            resistance, reactance = self.cable_data.get_resistance_reactance(cable_type)
            self.calculator.cable_type = cable_type
            self.calculator.resistance = resistance
            self.calculator.reactance = reactance
            self.calculator.calculate()
            self.chart_data.append({"cable": cable_type, "percentage_drop": self.calculator.percentage_drop})
        self.chartDataChanged.emit()

    @Property("QVariantList", notify=chartDataChanged)
    def chart_data_qml(self):
        return self.chart_data