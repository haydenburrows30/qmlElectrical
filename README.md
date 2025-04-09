# Electrical Calculator

A comprehensive electrical engineering calculator suite built with Python and QML that provides tools for cable sizing, voltage drop calculations, vector and phase visualisation, basic electrical calculations and more.

## Features

### Core Calculations
- Cable sizing and selection
- Voltage drop analysis
- Vector and phase visualisations
- Basic electrical calculations

![Image](https://github.com/user-attachments/assets/05602b1e-7efb-4121-9570-d0f214855710)
![Image](https://github.com/user-attachments/assets/d7e5c702-ed8e-47ea-98f3-62b8fbe2faf0)
![Image](https://github.com/user-attachments/assets/a59f2e46-1c77-402b-8ef7-f4e9b468f8f7)
![Image](https://github.com/user-attachments/assets/55df32f7-eb97-4b5a-adcb-7b953f03f7e3)
![Image](https://github.com/user-attachments/assets/2800a40b-3aab-44ba-bc8d-65af5d492782)
![Image](https://github.com/user-attachments/assets/39c85fdb-5829-4b61-9c09-a9daf8dd1aaf)



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
├── qml/components/    # Reusable QML components
├── qml/pages/         # Main application pages
├── data/          # Data files and resources
├── icons/         # Application icons
├── docs/          # Documentation
└── scripts/       # Build automation scripts
```

## License
This project is licensed under the MIT License - see the `LICENSE` file for details.