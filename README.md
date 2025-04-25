# Electrical Calculator

A comprehensive electrical engineering calculator suite built with Python and QML that provides tools for cable sizing, voltage drop calculations, vector and phase visualisation, basic electrical calculations and more.

This application was developed in Linux, but checks were made in Windows (bare metal).

The goal for this application is:

- Learn Python, QML & SQL
- Make a nice looking application without going overboard
- Able to run from Linux & Windows (runs much better in Linux)
- Package it for usage in Windows & Linux (.exe & .pkg)

Maybe I will port backend to C++ at a later date, but will mean learning C++. I'm sure this will speed up the application immensely using Qt framework. This was what drew me to QML as I can develop the frontend and replace the backend if necessary.  I have tried to decouple QML from Python as much as I can and just let QML display visuals.

## Features

### Core Calculations
- Cable sizing and selection
- Voltage drop analysis
- Vector and phase visualisations
- Basic electrical calculations

![Image](https://github.com/user-attachments/assets/857b621f-27da-4ad1-b36b-dfe8c9cc05e4)
![Image](https://github.com/user-attachments/assets/1f5ff68a-f3c8-4837-97db-bd3b9b2aa37f)
![Image](https://github.com/user-attachments/assets/e7a5ce45-a5d3-4e9e-b1b9-0734e8d3b352)
![Image](https://github.com/user-attachments/assets/a09813e2-0783-4222-b283-362717a21894)
![Image](https://github.com/user-attachments/assets/21a0b445-ecd2-4efb-bd03-57c7c6fb5ac1)

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