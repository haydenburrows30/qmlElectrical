from PySide6.QtCore import QObject, Signal, Slot, Property, QAbstractListModel, QModelIndex, Qt
import os
import csv
import json
from dataclasses import dataclass
from typing import List, Dict, Any, Optional
import datetime

@dataclass
class Circuit:
    number: str
    destination: str
    rating: int
    poles: str
    type: str
    load: float
    cableSize: str
    cableCores: str
    length: float
    status: str = "OK"
    notes: str = ""
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any], number: str) -> 'Circuit':
        return cls(
            number=number,
            destination=data.get('destination', ''),
            rating=data.get('rating', 0),
            poles=data.get('poles', ''),
            type=data.get('type', ''),
            load=data.get('load', 0.0),
            cableSize=data.get('cableSize', ''),
            cableCores=data.get('cableCores', ''),
            length=data.get('length', 0.0),
            status=data.get('status', 'OK'),
            notes=data.get('notes', '')
        )
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'number': self.number,
            'destination': self.destination,
            'rating': self.rating,
            'poles': self.poles,
            'type': self.type,
            'load': self.load,
            'cableSize': self.cableSize,
            'cableCores': self.cableCores,
            'length': self.length,
            'status': self.status,
            'notes': self.notes
        }

class CircuitModel(QAbstractListModel):
    NumberRole = Qt.UserRole + 1
    DestinationRole = Qt.UserRole + 2
    RatingRole = Qt.UserRole + 3
    PolesRole = Qt.UserRole + 4
    TypeRole = Qt.UserRole + 5
    LoadRole = Qt.UserRole + 6
    CableSizeRole = Qt.UserRole + 7
    CableCoresRole = Qt.UserRole + 8
    LengthRole = Qt.UserRole + 9
    StatusRole = Qt.UserRole + 10
    NotesRole = Qt.UserRole + 11

    def __init__(self, parent=None):
        super().__init__(parent)
        self._circuits: List[Circuit] = []
    
    def roleNames(self):
        return {
            self.NumberRole: b'number',
            self.DestinationRole: b'destination',
            self.RatingRole: b'rating',
            self.PolesRole: b'poles',
            self.TypeRole: b'type',
            self.LoadRole: b'load',
            self.CableSizeRole: b'cableSize',
            self.CableCoresRole: b'cableCores',
            self.LengthRole: b'length',
            self.StatusRole: b'status',
            self.NotesRole: b'notes'
        }
    
    def rowCount(self, parent=QModelIndex()):
        return len(self._circuits)
    
    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or index.row() >= len(self._circuits):
            return None
            
        circuit = self._circuits[index.row()]
        
        if role == self.NumberRole:
            return circuit.number
        elif role == self.DestinationRole:
            return circuit.destination
        elif role == self.RatingRole:
            return circuit.rating
        elif role == self.PolesRole:
            return circuit.poles
        elif role == self.TypeRole:
            return circuit.type
        elif role == self.LoadRole:
            return circuit.load
        elif role == self.CableSizeRole:
            return circuit.cableSize
        elif role == self.CableCoresRole:
            return circuit.cableCores
        elif role == self.LengthRole:
            return circuit.length
        elif role == self.StatusRole:
            return circuit.status
        elif role == self.NotesRole:
            return circuit.notes
            
        return None

    def add_circuit(self, circuit: Circuit):
        """Add a new circuit to the model."""
        self.beginInsertRows(QModelIndex(), len(self._circuits), len(self._circuits))
        self._circuits.append(circuit)
        self.endInsertRows()
    
    def update_circuit(self, index: int, circuit: Circuit):
        """Update an existing circuit in the model."""
        if 0 <= index < len(self._circuits):
            self._circuits[index] = circuit
            modelIndex = self.index(index, 0)
            self.dataChanged.emit(modelIndex, modelIndex, [Qt.UserRole])
    
    def get_circuit(self, index: int) -> Optional[Circuit]:
        """Get a circuit by index."""
        if 0 <= index < len(self._circuits):
            return self._circuits[index]
        return None

    def get_all_circuits(self):
        """Get all circuits."""
        return self._circuits
        
    def clear_circuits(self):
        """Clear all circuits from the model."""
        if self._circuits:
            self.beginResetModel()
            self._circuits.clear()
            self.endResetModel()

class SwitchboardManager(QObject):
    nameChanged = Signal()
    locationChanged = Signal()
    voltageChanged = Signal()
    phasesChanged = Signal()
    mainRatingChanged = Signal()
    typeChanged = Signal()
    totalLoadChanged = Signal()
    utilizationPercentChanged = Signal()
    circuitsChanged = Signal()
    circuitCountChanged = Signal(int)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._name = "MSB-1"
        self._location = "Main Electrical Room"
        self._voltage = "400V"
        self._phases = "3Ø + N"
        self._main_rating = 100
        self._type = "Main Switchboard"
        self._circuit_model = CircuitModel()
        self._next_circuit_number = 1
        self._circuit_count = 0
        
    # Properties
    def get_name(self) -> str:
        return self._name
        
    @Slot(str)
    def setName(self, name: str):
        if self._name != name:
            self._name = name
            self.nameChanged.emit()
    
    def get_location(self) -> str:
        return self._location
        
    @Slot(str)
    def setLocation(self, location: str):
        if self._location != location:
            self._location = location
            self.locationChanged.emit()
    
    def get_voltage(self) -> str:
        return self._voltage
        
    @Slot(str)
    def setVoltage(self, voltage: str):
        if self._voltage != voltage:
            self._voltage = voltage
            self.voltageChanged.emit()
    
    def get_phases(self) -> str:
        return self._phases
        
    @Slot(str)
    def setPhases(self, phases: str):
        if self._phases != phases:
            self._phases = phases
            self.phasesChanged.emit()
    
    def get_main_rating(self) -> int:
        return self._main_rating
        
    @Slot(int)
    def setMainRating(self, rating: int):
        if self._main_rating != rating:
            self._main_rating = rating
            self.mainRatingChanged.emit()
            self.utilizationPercentChanged.emit()
    
    def get_type(self) -> str:
        return self._type
        
    @Slot(str)
    def setType(self, board_type: str):
        if self._type != board_type:
            self._type = board_type
            self.typeChanged.emit()
    
    def get_total_load(self) -> float:
        total = 0.0
        for circuit in self._circuit_model.get_all_circuits():
            total += circuit.load
        return total
    
    def get_utilization_percent(self) -> float:
        if self._main_rating == 0:
            return 0.0
        
        total_load = self.get_total_load()
        
        # Convert kW to amps based on voltage
        voltage = float(self._voltage.replace('V', '').replace('k', '000'))
        if 'Ø' in self._phases and '3' in self._phases:
            # Three-phase calculation
            current = (total_load * 1000) / (voltage * 1.73 * 0.8)  # Assuming PF of 0.8
        else:
            # Single-phase calculation
            current = (total_load * 1000) / (voltage * 0.8)  # Assuming PF of 0.8
            
        return (current / self._main_rating) * 100
    
    def get_circuit_count(self) -> int:
        return len(self._circuit_model._circuits)
        
    name = Property(str, get_name, setName, notify=nameChanged)
    location = Property(str, get_location, setLocation, notify=locationChanged)
    voltage = Property(str, get_voltage, setVoltage, notify=voltageChanged)
    phases = Property(str, get_phases, setPhases, notify=phasesChanged)
    mainRating = Property(int, get_main_rating, setMainRating, notify=mainRatingChanged)
    type = Property(str, get_type, setType, notify=typeChanged)
    totalLoad = Property(float, get_total_load, notify=totalLoadChanged)
    utilizationPercent = Property(float, get_utilization_percent, notify=utilizationPercentChanged)
    circuitModel = Property(QAbstractListModel, lambda self: self._circuit_model, constant=True)
    circuitCount = Property(int, get_circuit_count, notify=circuitCountChanged)

    # Methods
    @Slot(dict, result=bool)
    def addCircuit(self, circuit_data):
        print("Adding circuit:", circuit_data)
        circuit_number = f"{self._next_circuit_number:02d}"
        self._next_circuit_number += 1
        
        # Validate the circuit
        status = self._validate_circuit(circuit_data)
        circuit_data['status'] = status
        
        # Create circuit object
        circuit = Circuit.from_dict(circuit_data, circuit_number)
        
        # Add to model
        self._circuit_model.add_circuit(circuit)
        
        # Make sure the model updates are visible in QML
        self._circuit_model.layoutChanged.emit()
        
        # Emit signals in the right order
        print("Emitting signals: totalLoadChanged")
        self.totalLoadChanged.emit()
        print("Emitting signals: utilizationPercentChanged")
        self.utilizationPercentChanged.emit()
        print("Emitting signals: circuitsChanged")
        self.circuitsChanged.emit()
        self.circuitCountChanged.emit(len(self._circuit_model._circuits))
        
        # Make extra sure to notify QML about the updated count
        count = len(self._circuit_model._circuits)
        print(f"Emitting circuit count changed: {count}")
        self.circuitCountChanged.emit(count)
        
        return True

    @Slot(int, dict)
    def updateCircuit(self, index, circuit_data):
        existing = self._circuit_model.get_circuit(index)
        if existing:
            circuit_number = existing.number
            
            # Validate the circuit
            status = self._validate_circuit(circuit_data)
            circuit_data['status'] = status
            
            # Create updated circuit object
            updated_circuit = Circuit.from_dict(circuit_data, circuit_number)
            
            # Update in model
            self._circuit_model.update_circuit(index, updated_circuit)
            
            # Emit signals
            self.circuitsChanged.emit()
            self.totalLoadChanged.emit()
            self.utilizationPercentChanged.emit()
            self.circuitCountChanged.emit(len(self._circuit_model._circuits))
    
    @Slot(int, result=dict)
    def getCircuit(self, index):
        circuit = self._circuit_model.get_circuit(index)
        if circuit:
            return circuit.to_dict()
        return {}
    
    @Slot(int, result='QVariant')
    def getCircuitAt(self, index):
        """Get circuit data at specified index for QML display"""
        print(f"QML requesting circuit at index: {index}, total count: {len(self._circuit_model._circuits)}")
        
        try:
            if 0 <= index < len(self._circuit_model._circuits):
                circuit = self._circuit_model._circuits[index]
                result = {
                    'number': circuit.number,
                    'destination': circuit.destination,
                    'rating': circuit.rating,
                    'poles': circuit.poles,
                    'type': circuit.type,
                    'load': circuit.load,
                    'cableSize': circuit.cableSize,
                    'cableCores': circuit.cableCores,
                    'length': circuit.length,
                    'notes': circuit.notes,
                    'status': circuit.status
                }
                print(f"Returning circuit data for index {index}: {result['number']} - {result['destination']}")
                return result
        except Exception as e:
            print(f"Error retrieving circuit at index {index}: {e}")
            
        print(f"Invalid index {index} requested (out of bounds)")
        # Return dummy data for invalid indices to avoid QML errors
        return {
            'number': 'ERR',
            'destination': 'Error',
            'rating': 0,
            'poles': '-',
            'type': '-',
            'load': 0.0,
            'cableSize': '-',
            'cableCores': '-',
            'length': 0.0,
            'notes': '',
            'status': 'Error'
        }

    def _validate_circuit(self, circuit_data):
        # Check if load exceeds breaker rating
        load_kw = circuit_data.get('load', 0)
        rating_a = circuit_data.get('rating', 0)
        
        voltage = float(self._voltage.replace('V', '').replace('k', '000'))
        
        # Calculate the maximum load for this breaker
        if '3' in circuit_data.get('poles', ''):
            # Three-phase calculation
            max_load_kw = rating_a * voltage * 1.73 * 0.8 / 1000
        else:
            # Single-phase calculation
            max_load_kw = rating_a * voltage * 0.8 / 1000
        
        # Allow for 80% loading
        if load_kw > max_load_kw * 0.8:
            return "Overloaded"
        
        # Check cable size is appropriate
        cable_size_mm2 = float(circuit_data.get('cableSize', '1.5mm²').replace('mm²', ''))
        
        # Simplified cable sizing check (would need full ampacity tables for accuracy)
        if rating_a <= 10 and cable_size_mm2 < 1.5:
            return "Cable too small"
        elif rating_a <= 16 and cable_size_mm2 < 1.5:
            return "Cable too small"
        elif rating_a <= 20 and cable_size_mm2 < 2.5:
            return "Cable too small"
        elif rating_a <= 25 and cable_size_mm2 < 4:
            return "Cable too small"
        elif rating_a <= 32 and cable_size_mm2 < 6:
            return "Cable too small"
        elif rating_a <= 50 and cable_size_mm2 < 10:
            return "Cable too small"
        elif rating_a <= 63 and cable_size_mm2 < 16:
            return "Cable too small"
        elif rating_a <= 80 and cable_size_mm2 < 25:
            return "Cable too small"
        elif rating_a <= 100 and cable_size_mm2 < 35:
            return "Cable too small"
        elif rating_a <= 125 and cable_size_mm2 < 50:
            return "Cable too small"
        
        return "OK"
    
    @Slot(result=str)
    def exportCSV(self):
        """Export switchboard schedule to CSV"""
        try:
            directory = os.path.expanduser("~/Downloads")
            filename = f"{self._name}_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
            filepath = os.path.join(directory, filename)
            
            with open(filepath, 'w', newline='') as csvfile:
                writer = csv.writer(csvfile)
                
                # Write header
                writer.writerow(["Switchboard Schedule:", self._name])
                writer.writerow(["Location:", self._location])
                writer.writerow(["Voltage:", self._voltage])
                writer.writerow(["Phases:", self._phases])
                writer.writerow(["Main Rating:", f"{self._main_rating}A"])
                writer.writerow(["Type:", self._type])
                writer.writerow([])  # Empty row
                
                # Write circuit table headers
                writer.writerow([
                    "Circuit #", "Destination", "Rating (A)", "Poles", 
                    "Type", "Load (kW)", "Cable Size", "Cable Cores", 
                    "Length (m)", "Status", "Notes"
                ])
                
                # Write circuit data
                for circuit in self._circuit_model.get_all_circuits():
                    writer.writerow([
                        circuit.number,
                        circuit.destination,
                        circuit.rating,
                        circuit.poles,
                        circuit.type,
                        circuit.load,
                        circuit.cableSize,
                        circuit.cableCores,
                        circuit.length,
                        circuit.status,
                        circuit.notes
                    ])
            
            return f"Exported to {filepath}"
        except Exception as e:
            return f"Export failed: {str(e)}"
    
    @Slot(result=str)
    def exportPDF(self):
        """Export switchboard schedule to PDF"""
        # This would require a PDF generation library like ReportLab
        # For now, we'll return a message
        return "PDF export not implemented yet"
    
    @Slot(result=str)
    def printSchedule(self):
        """Print the switchboard schedule"""
        # This would require printer integration
        return "Print functionality not implemented yet"
    
    @Slot(result=str)
    def saveToJSON(self):
        """Save the switchboard data to JSON"""
        try:
            directory = os.path.expanduser("~/Documents")
            filename = f"{self._name}_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            filepath = os.path.join(directory, filename)
            
            data = {
                "name": self._name,
                "location": self._location,
                "voltage": self._voltage,
                "phases": self._phases,
                "mainRating": self._main_rating,
                "type": self._type,
                "circuits": [c.to_dict() for c in self._circuit_model.get_all_circuits()]
            }
            
            with open(filepath, 'w') as f:
                json.dump(data, f, indent=2)
                
            return f"Saved to {filepath}"
        except Exception as e:
            return f"Save failed: {str(e)}"
    
    @Slot(str, result=str)
    def loadFromJSON(self, filepath):
        """Load switchboard data from JSON"""
        try:
            with open(filepath, 'r') as f:
                data = json.load(f)
            
            self.setName(data.get('name', 'Unknown'))
            self.setLocation(data.get('location', ''))
            self.setVoltage(data.get('voltage', '400V'))
            self.setPhases(data.get('phases', '3Ø + N'))
            self.setMainRating(data.get('mainRating', 100))
            self.setType(data.get('type', 'Main Switchboard'))
            
            # Clear existing circuits without creating a new model instance
            self._circuit_model.clear_circuits()
            
            # Add circuits from JSON
            for circuit_data in data.get('circuits', []):
                circuit = Circuit.from_dict(circuit_data, circuit_data.get('number', '0'))
                self._circuit_model.add_circuit(circuit)
            
            # Update next circuit number
            if self._circuit_model._circuits:
                max_num = max(int(c.number) for c in self._circuit_model._circuits if c.number.isdigit())
                self._next_circuit_number = max_num + 1
            else:
                self._next_circuit_number = 1
            
            # Emit signals
            self.circuitsChanged.emit()
            self.totalLoadChanged.emit()
            self.utilizationPercentChanged.emit()
            self.circuitCountChanged.emit(len(self._circuit_model._circuits))
            
            return f"Loaded from {filepath}"
        except Exception as e:
            return f"Load failed: {str(e)}"
