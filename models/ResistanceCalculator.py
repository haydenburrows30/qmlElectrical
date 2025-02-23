import math

class ResistanceCalculator:
    def __init__(self, voltage=415.0, length=0.0, power=0.0, cable_resistance=0.00, reactance=0.00, power_factor=0.9, lots=10, base_current=0.0):
        """
        Constructor
        :param resistance: resistance from csv in ohms/km
        :param reactance: reactance from csv in ohms/km
        :param voltage: voltage to calculate percentage drop in %
        :param length: length in m (changed to km in calculation)
        :param power: power in kva
        :param power_factor: power factor in unitless
        :param evaluation_threshold: voltage percentage threshold in %
        """ 
                
        self.voltage = voltage
        self.length = length / 1000
        self.cable_resistance = cable_resistance
        self.reactance = reactance
        self.power = power * lots
        self.power_factor = power_factor
        self.base_current = base_current

    def calculate_voltage_drop(self):
        self.current = ((self.power * 1000) / (1.732 * self.voltage * self.power_factor)) + self.base_current
        
        angle = math.acos(self.power_factor)
        voltage_drop_factor = math.sqrt(3)  # Assuming three-phase system
        voltage_drop = voltage_drop_factor * self.current * (self.cable_resistance * math.cos(angle) + self.reactance * math.sin(angle)) * self.length
        return voltage_drop
