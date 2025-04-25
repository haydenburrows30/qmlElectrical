# NetworkCabinetCalculator

A Qt-based Python class for configuring and managing DC-M1 network cabinet layouts and properties. Designed for integration with QML GUIs.

## Features

- Manages all configuration parameters for a DC-M1 network cabinet, including ways, cable sizes, fuse ratings, conductor types, and more.
- Supports both main and service panels, including cable sizes, lengths, and connection counts.
- Handles site and project metadata (site name, number, customer, project, designer, revision, etc.).
- Supports up to 5 revision entries with descriptions and tracking.
- Provides QML properties and signals for all configuration fields.
- Exports cabinet configuration to PDF (with optional diagram image).
- Saves and loads configuration to/from JSON files.
- Emits signals for all property changes for QML binding.

## Calculations

The NetworkCabinetCalculator primarily manages configuration data, but the following calculations are relevant:

### 1. Total Cable Length

The total cable length for each way is tracked and can be summed:

```math
\text{Total Cable Length} = \sum_{i=1}^{N} \text{cable\_length}_i
```

### 2. Connection Count

The total number of connections is tracked for each way and for the service panel:

```math
\text{Total Connections} = \sum_{i=1}^{N} \text{connection\_count}_i + \text{servicePanelConnectionCount}
```

### 3. Configuration Validation

- Ensures all required fields (cable size, conductor type, fuse rating, etc.) are set for each way.
- Validates that the number of active ways and revision entries are within allowed limits.

### 4. Revision Tracking

- Maintains up to 5 revision entries, each with number, description, designer, date, and checked by.

## Main Properties

- `activeWays`: Number of active ways (int, 1–4)
- `cableSizes`: List of main cable sizes (list of str)
- `showStreetlightingPanel`, `showServicePanel`, `showDropperPlates`: Show/hide panels (bool)
- `wayTypes`: List of way types (list of int, 0=630A, 1=2x160A, 2=1x160A+cover)
- `fuseRatings`: List of fuse ratings (list of str)
- `serviceCableSizes`: List of service cable sizes (list of str)
- `conductorTypes`, `serviceConductorTypes`: List of conductor types (list of str)
- `connectionCounts`: List of connection counts (list of int)
- `cableLengths`: List of cable lengths (list of float)
- `servicePanelLength`: Service panel cable length (float)
- `servicePanelCableSize`, `servicePanelConductorType`: Service panel cable/conductor (str)
- `servicePanelConnectionCount`: Service panel connection count (int)
- `siteName`, `siteNumber`: Site metadata (str)
- `sources`, `destinations`, `notes`, `phases`: Lists for each way (list of str)
- `generalNotes`: General notes (str)
- Header/footer: `customerName`, `customerEmail`, `projectName`, `orn`, `designer`, `revisionNumber`, `revisionDescription`, `checkedBy`
- Revision management: `revisionCount` (int), `revisions` (list of dict)

## Methods and Slots

- `resetToDefaults()`: Reset all properties to default values.
- `setCableSize(index: int, size: str)`: Set cable size at index.
- `setServiceCableSize(index: int, size: str)`: Set service cable size at index.
- `setWayType(index: int, way_type: int)`: Set way type at index.
- `setConductorType(index: int, conductor_type: str)`: Set main conductor type at index.
- `setServiceConductorType(index: int, conductor_type: str)`: Set service conductor type at index.
- `setConnectionCount(index: int, count: int)`: Set connection count at index.
- `setCableLength(index: int, length: float)`: Set cable length at index.
- `setSource(index: int, source: str)`, `setDestination(index: int, destination: str)`, `setNotes(index: int, notes: str)`, `setPhase(index: int, phase: str)`: Set text fields for each way.
- `setRevisionProperty(index: int, property_name: str, value: str)`: Set a property on a specific revision.
- `getRevisionProperty(index: int, property_name: str) -> str`: Get a property from a specific revision.
- `exportToPdf(diagram_image=None)`: Export configuration to PDF (optionally with diagram).
- `saveConfig(file_path: str)`: Save configuration to JSON.
- `loadConfig(file_path: str)`: Load configuration from JSON.

## Usage Example

To use the NetworkCabinetCalculator in a QML application, bind its properties and signals to QML elements. For example:

```qml
NetworkCabinetCalculator {
    id: cabinetCalculator
    activeWays: 4
    cableSizes: ["185mm²", "185mm²", "185mm²", "185mm²"]
    onConfigChanged: console.log("Configuration updated")
}
```

## Notes

- Designed for use with PySide6 and QML, but can be used standalone in Python.
- All signals are emitted to keep QML interfaces in sync with data changes.
- PDF and JSON export/import use the `FileSaver` service for file dialogs and saving.