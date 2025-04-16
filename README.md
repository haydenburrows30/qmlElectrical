# Electrical Calculator

A comprehensive electrical engineering calculator suite built with Python and QML that provides tools for cable sizing, voltage drop calculations, vector and phase visualisation, basic electrical calculations and more.

## Features

### Core Calculations
- Cable sizing and selection
- Voltage drop analysis
- Vector and phase visualisations
- Basic electrical calculations

![Image](https://github.com/user-attachments/assets/3c814874-440b-44fb-b459-e6107e67dc1d)

![Image](https://github.com/user-attachments/assets/2bc4fd8a-3abe-4170-8241-6631ea55d357)

![Image](https://github.com/user-attachments/assets/31c4d7aa-9ada-4c2f-ac91-ae205a1098f9)

![Image](https://github.com/user-attachments/assets/c7fd4e55-1122-4396-a960-bc04e94a3e1d)

![Image](https://github.com/user-attachments/assets/f9eea387-1188-4149-ba90-83e4fc86a225)

![Image](https://github.com/user-attachments/assets/282565db-707c-4cd7-b5ac-e7b29c5e712c)

## Getting Started

### Prerequisites
- Python 3.8 or later
- PySide6
- reportlab
- numpy

### Basic Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/electrical-calculator.git
cd electrical-calculator
```

2. Install virtual environment via virtualenv:

```bash
virtualenv venv
source venv/bin/activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Generate resources:
```bash
pyside6-rcc resources.qrc -o data/rc_resources.py
```

5. Run the application:
```bash
python main.py
```

## Building From Source

### Windows Build

1. Install build requirements:
```bash
pip install -r build_requirements.txt
```

2. Run the build script:
```bash
python scripts/windows_build.py
```

3. Create installer (requires NSIS):
- Install NSIS from https://nsis.sourceforge.io/
- Right-click installer/windows_installer.nsi and select "Compile NSIS Script"

The executable will be in the `dist` folder, and the installer will be created as `ElectricalCalculator_Setup.exe`.

### Build Requirements
- Python 3.8 or later
- PyInstaller
- PySide6
- NSIS (for creating installer)

### Cross-Platform Building

#### Building Windows Executable from Linux
1. Install Wine:
```bash
sudo apt install wine64
```

2. Run cross-platform build script:
```bash
python scripts/cross_build.py
```

The script will automatically:
- Download Python 3.12.10 for Windows
- Set up Wine environment
- Install Python in Wine
- Install dependencies in Wine Python
- Build the Windows executable

```bash
pip install -r build_requirements.txt
python scripts/windows_build.py
```

## Development

### Project Structure
```
electrical-calculator/
├── qml/components/         # Reusable QML components
├── qml/components/menus/   # Define all menus here
├── qml/pages/              # Main application pages
├── qml/calculators/        # Calculators
├── data/                   # Data files and resources
├── icons/                  # Application icons
├── docs/                   # Documentation
└── scripts/                # Build automation scripts
```

## License
This project is licensed under the MIT License - see the `LICENSE` file for details.

## To Do

- Change Qt.GraphicalEffects for HButton.qml to QtQuick.Effects