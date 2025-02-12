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