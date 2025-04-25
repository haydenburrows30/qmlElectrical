# SwitchboardManager

A Qt-based Python class for managing switchboard schedules, circuits, and related data. Designed for integration with QML GUIs.

## Features

- Manages switchboard metadata (name, location, voltage, phases, main rating, type).
- Maintains a list of circuits with properties such as destination, rating, poles, type, load, cable size, and more.
- Provides a QML-friendly model (`CircuitModel`) for circuit data.
- Calculates total load and utilization percent.
- Validates circuit data for overload and cable sizing.
- Supports adding, updating, and retrieving circuits.
- Exports switchboard schedule to CSV and JSON.
- Loads switchboard data from JSON (with or without file dialog).
- Emits signals for property and data changes for QML binding.

## Calculations

### 1. Total Load

The total load is the sum of all circuit loads:

```math
\text{Total Load (kW)} = \sum_{i=1}^{N} \text{load}_i
```

### 2. Utilization Percent

The utilization percent is calculated as the ratio of the total load current to the main breaker rating:

- For three-phase boards:
  ```math
  I_{\text{total}} = \frac{\text{Total Load (kW)} \times 1000}{V \times 1.73 \times \text{PF}}
  ```
- For single-phase boards:
  ```math
  I_{\text{total}} = \frac{\text{Total Load (kW)} \times 1000}{V \times \text{PF}}
  ```
- Utilization percent:
  ```math
  \text{Utilization (\%)} = \frac{I_{\text{total}}}{\text{Main Rating (A)}} \times 100
  ```
  Where \( V \) is the voltage (V), and PF (power factor) is assumed to be 0.8.

### 3. Circuit Validation

#### Overload Check

The maximum allowable load for a breaker is:

```math
\text{max\_load\_kW} = \text{rating}_A \times V \times \text{PF} \times \text{phase\_factor} / 1000
```
- For three-phase: phase_factor = 1.73, PF = 0.8
- For single-phase: phase_factor = 1, PF = 0.8

A circuit is "Overloaded" if:

```math
\text{load} > 0.8 \times \text{max\_load\_kW}
```

#### Cable Size Check

The cable size is checked against the breaker rating using simplified thresholds (see code for details).

## Circuit Data Structure

Each circuit is represented by the following fields:

- `number`: Circuit number (string)
- `destination`: Load destination (string)
- `rating`: Breaker rating (int, A)
- `poles`: Number of poles (string)
- `type`: Circuit type (string)
- `load`: Load (float, kW)
- `cableSize`: Cable size (string, e.g., "2.5mm²")
- `cableCores`: Number of cable cores (string)
- `length`: Cable length (float, m)
- `status`: Status string (e.g., "OK", "Overloaded", "Cable too small")
- `notes`: Notes (string)

## Properties

- `name`: Switchboard name (str)
- `location`: Location (str)
- `voltage`: Voltage (str, e.g., "400V")
- `phases`: Phases (str, e.g., "3Ø + N")
- `mainRating`: Main breaker rating (int, A)
- `type`: Switchboard type (str)
- `totalLoad`: Total load of all circuits (float, kW)
- `utilizationPercent`: Utilization percent of main breaker (%)
- `circuitModel`: QML-accessible model of circuits (`QObject`)
- `circuitCount`: Number of circuits (int)

## Methods and Slots

- `addCircuit(circuit_data: dict) -> bool`: Add a new circuit.
- `updateCircuit(index: int, circuit_data: dict) -> bool`: Update an existing circuit.
- `getCircuit(index: int) -> dict`: Get circuit data by index.
- `getCircuitAt(index: int) -> dict`: Get circuit data for QML display.
- `exportCSV() -> str`: Export switchboard schedule to CSV.
- `saveToJSON() -> str`: Save switchboard data to JSON.
- `loadFromJSON(filepath: str) -> str`: Load switchboard data from JSON file.
- `loadFromJSONWithDialog() -> str`: Load switchboard data from JSON using a file dialog.

## Usage Example

Designed for use with PySide6 and QML, but can be used standalone in Python. All signals are emitted to keep QML interfaces in sync with data changes. CSV and JSON export/import use the `FileSaver` service for file dialogs and saving.

## Notes

- Designed for use with PySide6 and QML, but can be used standalone in Python.
- All signals are emitted to keep QML interfaces in sync with data changes.
- CSV and JSON export/import use the `FileSaver` service for file dialogs and saving.