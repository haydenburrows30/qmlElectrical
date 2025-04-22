# Database Architecture Guide

This document explains how the database system works in the QML Test application and provides examples for common tasks like importing CSV data and adding new calculator tables.

## Database Architecture Overview

The application uses SQLite as its database engine with several Python modules working together to provide a complete database solution:

### Key Components

1. **DatabaseManager** (`services/database_manager.py`): 
   - Core singleton class that handles database initialization, connections, and schema management
   - Provides thread-safe connections to the database
   - Manages reference data and database versioning
   - Handles basic CRUD operations through methods like `fetch_one`, `fetch_all`, and `execute_query`

2. **Database Tools** (`services/database_tools.py`):
   - Utility class for maintenance operations like backup/restore, import/export, etc.
   - Provides table info, data export to CSV, and query execution tools
   - Used primarily for admin tasks and data management

3. **DataStore** (`services/data_store.py`):
   - In-memory cache with database persistence
   - Provides a Qt-friendly interface with signals for data changes
   - Serves as an application-friendly access point for services

4. **Config** (`services/config.py`):
   - Application configuration management
   - Uses DatabaseManager for persistent storage
   - Provides settings and configuration to the application

5. **Domain-specific Services**:
   - Services like `voltage_drop_service.py` that provide business logic
   - Use DatabaseManager to access and manipulate domain-specific data

### Database Initialization Flow

1. The database is automatically initialized when `DatabaseManager` is first instantiated
2. If the database file doesn't exist, a new one is created and populated with default data
3. If the database exists but has an older schema version, it's upgraded automatically
4. Reference data is loaded from embedded defaults or from CSV files if available

## Common Database Tasks

### Example 1: Importing Data from a CSV File

Let's say you have a CSV file with transformer data you want to import into the database.

**Step 1: Create the CSV file**

Create a CSV file in the `data` directory named `transformers.csv`:

```csv
kva,primary_voltage,secondary_voltage,impedance,type,weight_kg,length_mm,width_mm,height_mm
25,11000,415,4.5,Distribution,350,800,600,900
50,11000,415,4.5,Distribution,550,900,700,1000
100,11000,415,4.5,Distribution,750,1000,800,1200
200,11000,415,4.5,Distribution,1050,1200,900,1400
315,11000,415,4.5,Distribution,1350,1300,1000,1500
500,11000,415,4.5,Distribution,1650,1400,1100,1600
750,11000,415,4.5,Distribution,2100,1600,1200,1800
1000,11000,415,4.5,Distribution,2600,1800,1300,2000
```

**Step 2: Add a Table Schema to DatabaseManager**

Add the table creation code to the `_create_schema` method in `database_manager.py`:

```python
# Transformers table
cursor.execute('''
CREATE TABLE IF NOT EXISTS transformers (
    id INTEGER PRIMARY KEY,
    kva INTEGER NOT NULL,
    primary_voltage INTEGER NOT NULL,
    secondary_voltage INTEGER NOT NULL,
    impedance REAL NOT NULL,
    type TEXT NOT NULL,
    weight_kg INTEGER,
    length_mm INTEGER,
    width_mm INTEGER,
    height_mm INTEGER
)''')
```

**Step 3: Create a Data Loading Method**

Add a method to `database_manager.py` to load the transformer data:

```python
def _load_transformer_data(self):
    """Load transformer data from CSV if available, or use defaults."""
    cursor = self.connection.cursor()
    
    # Check if table is already populated
    cursor.execute("SELECT COUNT(*) FROM transformers")
    if cursor.fetchone()[0] > 0:
        return
    
    # Try to load from CSV
    project_root = os.path.abspath(os.path.join(os.path.dirname(self.db_path), '..'))
    csv_path = os.path.join(project_root, 'data', 'transformers.csv')
    
    if os.path.exists(csv_path):
        try:
            df = pd.read_csv(csv_path)
            for _, row in df.iterrows():
                cursor.execute(
                    """INSERT INTO transformers 
                    (kva, primary_voltage, secondary_voltage, impedance, type, 
                    weight_kg, length_mm, width_mm, height_mm)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    (row['kva'], row['primary_voltage'], row['secondary_voltage'], 
                    row['impedance'], row['type'], row['weight_kg'], 
                    row['length_mm'], row['width_mm'], row['height_mm'])
                )
            self.connection.commit()
            logger.info(f"Loaded transformer data from {csv_path}")
            return
        except Exception as e:
            logger.warning(f"Failed to load transformer data from CSV: {e}")
    
    # Use default values if CSV loading failed
    default_transformers = [
        (25, 11000, 415, 4.5, 'Distribution', 350, 800, 600, 900),
        (50, 11000, 415, 4.5, 'Distribution', 550, 900, 700, 1000),
        (100, 11000, 415, 4.5, 'Distribution', 750, 1000, 800, 1200)
    ]
    
    cursor.executemany("""
        INSERT INTO transformers 
        (kva, primary_voltage, secondary_voltage, impedance, type, 
        weight_kg, length_mm, width_mm, height_mm)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, default_transformers)
    
    self.connection.commit()
    logger.info("Loaded default transformer data")
```

**Step 4: Add the Loading Method to the Initialization Process**

Add a call to your loading method in the `_load_reference_data` method:

```python
def _load_reference_data(self):
    """Load all reference data into database."""
    logger.info("Loading reference data")
    
    # Load existing data...
    self._load_diversity_factors()
    self._load_fuse_sizes()
    # etc...
    
    # Add your new loader
    self._load_transformer_data()
    
    # Load default config values
    self._load_default_config()
    
    logger.info("Reference data loading complete")
```

**Step 5: Create a Service to Access the Data**

Create a new service file `transformer_service.py`:

```python
import logging
from services.database_manager import DatabaseManager

logger = logging.getLogger("qmltest.transformer")

class TransformerService:
    """Service for transformer-related operations."""
    
    def __init__(self, db_path=None):
        """Initialize with optional database path."""
        self.db_manager = DatabaseManager.get_instance(db_path)
    
    def get_all_transformers(self):
        """Get all transformer data."""
        try:
            return self.db_manager.fetch_all("SELECT * FROM transformers ORDER BY kva")
        except Exception as e:
            logger.error(f"Error getting transformers: {e}")
            return []
    
    def get_transformer_by_kva(self, kva):
        """Get transformer by kVA rating."""
        try:
            return self.db_manager.fetch_one(
                "SELECT * FROM transformers WHERE kva = ? LIMIT 1",
                (kva,)
            )
        except Exception as e:
            logger.error(f"Error getting transformer: {e}")
            return None
    
    def get_available_kva_ratings(self):
        """Get list of available kVA ratings."""
        try:
            results = self.db_manager.fetch_all(
                "SELECT kva FROM transformers ORDER BY kva"
            )
            return [row['kva'] for row in results]
        except Exception as e:
            logger.error(f"Error getting kVA ratings: {e}")
            return []
```

### Example 2: Creating a New Calculator with Database Support

Let's create a new calculator for fault current calculations that requires a new table.

**Step 1: Define Your Table in DatabaseManager**

Add the table to the `_create_schema` method in `database_manager.py`:

```python
# Fault current calculation history
cursor.execute('''
CREATE TABLE IF NOT EXISTS fault_calculations (
    id INTEGER PRIMARY KEY,
    timestamp TEXT NOT NULL,
    system_voltage REAL NOT NULL,
    transformer_kva REAL NOT NULL,
    transformer_impedance REAL NOT NULL,
    cable_length REAL NOT NULL,
    cable_size REAL NOT NULL,
    cable_impedance REAL NOT NULL,
    fault_current REAL NOT NULL,
    circuit_breaker TEXT,
    notes TEXT
)''')
```

**Step 2: Create a Service for the Calculator**

Create a new file `fault_current_service.py`:

```python
import math
import logging
from datetime import datetime
from services.database_manager import DatabaseManager

logger = logging.getLogger("qmltest.fault_current")

class FaultCurrentService:
    """Service for fault current calculations."""
    
    def __init__(self, db_path=None):
        """Initialize with optional database path."""
        self.db_manager = DatabaseManager.get_instance(db_path)
    
    def calculate_fault_current(self, system_voltage, transformer_kva, 
                               transformer_impedance, cable_length, 
                               cable_size, cable_impedance):
        """Calculate fault current."""
        try:
            # Simple calculation model (this would be more complex in reality)
            transformer_ohms = (system_voltage**2 * transformer_impedance/100) / (transformer_kva * 1000)
            cable_ohms = cable_impedance * cable_length / 1000  # assuming cable_impedance is in ohms/km
            total_impedance = math.sqrt(transformer_ohms**2 + cable_ohms**2)
            
            # Calculate fault current (I = V/Z)
            if total_impedance > 0:
                fault_current = system_voltage / (math.sqrt(3) * total_impedance)
            else:
                fault_current = 0
                
            return fault_current
        except Exception as e:
            logger.error(f"Error calculating fault current: {e}")
            return 0
    
    def save_calculation(self, system_voltage, transformer_kva, 
                        transformer_impedance, cable_length, 
                        cable_size, cable_impedance, fault_current,
                        circuit_breaker=None, notes=None):
        """Save calculation to history."""
        try:
            timestamp = datetime.now().isoformat()
            
            self.db_manager.execute_query(
                """
                INSERT INTO fault_calculations
                (timestamp, system_voltage, transformer_kva, transformer_impedance,
                cable_length, cable_size, cable_impedance, fault_current,
                circuit_breaker, notes)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (timestamp, system_voltage, transformer_kva, transformer_impedance,
                cable_length, cable_size, cable_impedance, fault_current,
                circuit_breaker, notes)
            )
            
            logger.info(f"Saved fault current calculation: {fault_current:.2f} A")
            return True
        except Exception as e:
            logger.error(f"Error saving calculation: {e}")
            return False
    
    def get_calculation_history(self, limit=100):
        """Get calculation history."""
        try:
            return self.db_manager.fetch_all(
                """
                SELECT * FROM fault_calculations 
                ORDER BY timestamp DESC
                LIMIT ?
                """,
                (limit,)
            )
        except Exception as e:
            logger.error(f"Error getting calculation history: {e}")
            return []
    
    def get_transformers_for_voltage(self, voltage):
        """Get transformers for a specific voltage."""
        try:
            return self.db_manager.fetch_all(
                """
                SELECT * FROM transformers 
                WHERE primary_voltage = ? OR secondary_voltage = ?
                ORDER BY kva
                """,
                (voltage, voltage)
            )
        except Exception as e:
            logger.error(f"Error getting transformers: {e}")
            return []
```

**Step 3: Use the Service in a QML Component**

Create a QML file for the calculator (`qml/pages/FaultCurrentCalculator.qml`):

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Page {
    title: "Fault Current Calculator"
    
    Component.onCompleted: {
        // Initialize with default values
        systemVoltageCombo.currentIndex = 1  // 415V
    }
    
    ScrollView {
        anchors.fill: parent
        contentWidth: parent.width
        
        ColumnLayout {
            width: parent.width
            spacing: 10
            
            GroupBox {
                title: "System Parameters"
                Layout.fillWidth: true
                
                ColumnLayout {
                    width: parent.width
                    
                    ComboBox {
                        id: systemVoltageCombo
                        Layout.fillWidth: true
                        model: ["230", "415", "11000", "33000"]
                        label: "System Voltage (V)"
                    }
                    
                    ComboBox {
                        id: transformerKvaCombo
                        Layout.fillWidth: true
                        model: ["25", "50", "100", "200", "315", "500", "750", "1000"]
                        label: "Transformer Size (kVA)"
                    }
                    
                    TextField {
                        id: transformerImpedanceField
                        Layout.fillWidth: true
                        placeholderText: "Enter transformer impedance (%)"
                        text: "4.5"
                        validator: DoubleValidator {bottom: 0.1; top: 20.0}
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                    }
                }
            }
            
            GroupBox {
                title: "Cable Parameters"
                Layout.fillWidth: true
                
                ColumnLayout {
                    width: parent.width
                    
                    TextField {
                        id: cableLengthField
                        Layout.fillWidth: true
                        placeholderText: "Enter cable length (m)"
                        text: "100"
                        validator: IntValidator {bottom: 1; top: 10000}
                        inputMethodHints: Qt.ImhDigitsOnly
                    }
                    
                    ComboBox {
                        id: cableSizeCombo
                        Layout.fillWidth: true
                        model: ["16", "25", "35", "50", "70", "95", "120", "150", "185", "240", "300"]
                        label: "Cable Size (mm²)"
                    }
                    
                    TextField {
                        id: cableImpedanceField
                        Layout.fillWidth: true
                        placeholderText: "Enter cable impedance (Ω/km)"
                        text: "0.45"
                        validator: DoubleValidator {bottom: 0.01; top: 10.0}
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                    }
                }
            }
            
            Button {
                text: "Calculate Fault Current"
                Layout.fillWidth: true
                onClicked: {
                    // Call the Python backend to calculate
                    const result = calculatorManager.calculateFaultCurrent(
                        parseFloat(systemVoltageCombo.currentText),
                        parseFloat(transformerKvaCombo.currentText),
                        parseFloat(transformerImpedanceField.text),
                        parseFloat(cableLengthField.text),
                        parseFloat(cableSizeCombo.currentText),
                        parseFloat(cableImpedanceField.text)
                    )
                    
                    resultField.text = result.toFixed(2) + " A"
                }
            }
            
            GroupBox {
                title: "Results"
                Layout.fillWidth: true
                
                ColumnLayout {
                    width: parent.width
                    
                    TextField {
                        id: resultField
                        Layout.fillWidth: true
                        readOnly: true
                        placeholderText: "Fault current will appear here"
                    }
                    
                    Button {
                        text: "Save Result"
                        Layout.fillWidth: true
                        enabled: resultField.text !== ""
                        onClicked: {
                            // Save the calculation in the database
                            calculatorManager.saveFaultCalculation(
                                parseFloat(systemVoltageCombo.currentText),
                                parseFloat(transformerKvaCombo.currentText),
                                parseFloat(transformerImpedanceField.text),
                                parseFloat(cableLengthField.text),
                                parseFloat(cableSizeCombo.currentText),
                                parseFloat(cableImpedanceField.text),
                                parseFloat(resultField.text.replace(" A", ""))
                            )
                        }
                    }
                }
            }
            
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }
}
```

**Step 4: Connect the Calculator to the Python Backend**

Create a new calculator manager class in your application's backend:

```python
class CalculatorManager(QObject):
    # Other calculator methods...
    
    @Slot(float, float, float, float, float, float, result=float)
    def calculateFaultCurrent(self, system_voltage, transformer_kva, 
                             transformer_impedance, cable_length, 
                             cable_size, cable_impedance):
        """Calculate and return the fault current."""
        service = FaultCurrentService()
        return service.calculate_fault_current(
            system_voltage, transformer_kva, transformer_impedance,
            cable_length, cable_size, cable_impedance
        )
    
    @Slot(float, float, float, float, float, float, float, result=bool)
    def saveFaultCalculation(self, system_voltage, transformer_kva, 
                            transformer_impedance, cable_length, 
                            cable_size, cable_impedance, fault_current):
        """Save the fault current calculation to history."""
        service = FaultCurrentService()
        return service.save_calculation(
            system_voltage, transformer_kva, transformer_impedance,
            cable_length, cable_size, cable_impedance, fault_current
        )
```

**Step 5: Create a Report View for Calculation History**

Create a QML file for viewing calculation history (`qml/pages/FaultCurrentHistory.qml`):

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Page {
    title: "Fault Current History"
    
    Component.onCompleted: {
        // Load calculation history on page load
        updateHistoryModel()
    }
    
    function updateHistoryModel() {
        const history = calculatorManager.getFaultCalculationHistory()
        historyModel.clear()
        
        for (let i = 0; i < history.length; i++) {
            historyModel.append({
                timestamp: history[i].timestamp,
                voltage: history[i].system_voltage + " V",
                transformer: history[i].transformer_kva + " kVA",
                current: history[i].fault_current.toFixed(2) + " A"
            })
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        
        ListView {
            id: historyListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            model: ListModel {
                id: historyModel
            }
            
            delegate: ItemDelegate {
                width: historyListView.width
                
                ColumnLayout {
                    width: parent.width
                    
                    Label {
                        text: timestamp
                        font.pointSize: 8
                        color: "gray"
                    }
                    
                    Label {
                        text: "System: " + voltage + " | Transformer: " + transformer
                        font.pointSize: 10
                    }
                    
                    Label {
                        text: "Fault Current: " + current
                        font.bold: true
                        font.pointSize: 12
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "lightgray"
                    }
                }
            }
        }
        
        Button {
            text: "Refresh"
            Layout.fillWidth: true
            onClicked: updateHistoryModel()
        }
    }
}
```

**Step 6: Add the Backend Method for History Retrieval**

```python
@Slot(result='QVariantList')
def getFaultCalculationHistory(self):
    """Get fault calculation history."""
    service = FaultCurrentService()
    history = service.get_calculation_history()
    
    result = []
    for item in history:
        result.append({
            'timestamp': item['timestamp'],
            'system_voltage': item['system_voltage'],
            'transformer_kva': item['transformer_kva'],
            'transformer_impedance': item['transformer_impedance'],
            'cable_length': item['cable_length'],
            'cable_size': item['cable_size'],
            'cable_impedance': item['cable_impedance'],
            'fault_current': item['fault_current']
        })
    
    return result
```

## Database Schema Reference

Below is the complete database schema for reference:

| Table Name | Description |
|------------|-------------|
| schema_version | Stores the current schema version number |
| config | Key-value store for application configuration |
| cable_data | Cable properties (size, material, ratings) |
| installation_methods | Cable installation methods and derating factors |
| temperature_factors | Temperature correction factors |
| cable_materials | Cable material properties |
| standards_reference | Electrical standards references |
| circuit_breakers | Circuit breaker specifications |
| protection_curves | Protection device time-current curves |
| diversity_factors | Load diversity factors by number of houses |
| fuse_sizes | Standard fuse sizes for cables |
| calculation_history | History of voltage drop calculations |
| settings | User application settings |
| transformers | Transformer specifications (added in Example 1) |
| fault_calculations | Fault current calculation history (added in Example 2) |

## Best Practices

1. **Use the DatabaseManager for all database operations**:
   - Always use the singleton instance (`DatabaseManager.get_instance()`)
   - Don't create direct connections to the database

2. **Create a service class for domain-specific functionality**:
   - Define calculator-specific services with high-level methods
   - Keep business logic separate from the database layer

3. **Define default data in the code**:
   - Always provide fallback default data in code
   - Use CSV files for ease of editing/updating reference data

4. **Handle exceptions gracefully**:
   - Always use try/except blocks for database operations
   - Log errors but don't crash the application

5. **Keep schema and data in sync**:
   - When adding tables, update the schema version
   - Run schema migrations when upgrading

6. **Use appropriate Qt types in QML interfaces**:
   - Use `QVariantList` and `QVariantMap` for data exchange with QML
   - Convert database records to JSON-compatible formats

7. **Use transactions for multi-step operations**:
   - Wrap multi-step operations in transactions
   - Commit only when all steps succeed
