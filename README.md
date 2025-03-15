# Electrical Calculator

A comprehensive electrical engineering calculator suite built with Python and QML that provides tools for cable sizing, voltage drop calculations, fault current analysis, and more.

## Features

### Core Calculations
- Cable sizing and selection
- Voltage drop analysis 
- Fault current calculations
- Power factor correction
- Load diversity analysis
- Phase balancing

https://github.com/user-attachments/assets/9ee3eb73-768c-4548-9c1c-ed7e54e14f74

![Image](https://github.com/user-attachments/assets/344f6725-d1f3-4d2c-80be-b3ae8c69b64b)

![Image](https://github.com/user-attachments/assets/f14193c9-bb32-4ed7-8e2a-3737d09fbb80)

![Image](https://github.com/user-attachments/assets/78289c45-4dae-4b97-8e61-c341a3de903c)

![Image](https://github.com/user-attachments/assets/c29e6749-ead1-4cb7-8332-aab87a47f8ed)

![Image](https://github.com/user-attachments/assets/63c39487-3109-4e64-9ebe-c13e941e69c6)

![Image](https://github.com/user-attachments/assets/000c387f-f8dd-4732-879c-021c3430657a)

![Image](https://github.com/user-attachments/assets/79e2eec1-9ea1-4451-a5d9-e47eecc2302d)

![Image](https://github.com/user-attachments/assets/68ec1a52-4fd0-4e80-bd2a-2b5375aecb41)

## Getting Started

### Prerequisites
- Python 3.8 or later
- Qt 6.0 or later
- PySide6
- See `requirements.txt` for full dependencies

### Basic Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/electrical-calculator.git
cd electrical-calculator
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Generate resources:
```bash
pyside6-rcc resources.qrc -o data/rc_resources.py
```

4. Run the application:
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
python build_scripts/windows_build.py
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
python build_scripts/cross_build.py
```

The script will automatically:
- Download Python 3.8.10 for Windows
- Set up Wine environment
- Install Python in Wine
- Install dependencies in Wine Python
- Build the Windows executable

```bash
pip install -r build_requirements.txt
python build_scripts/windows_build.py
```

## Development

### Project Structure
```
electrical-calculator/
├── components/     # Reusable QML components
├── pages/         # Main application pages
├── data/          # Data files and resources
├── icons/         # Application icons
├── docs/          # Documentation
└── build_scripts/ # Build automation scripts
```

### Contributing
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License
This project is licensed under the MIT License - see the `LICENSE` file for details.

## Acknowledgments
- Qt Company for the Qt framework
- Contributors and maintainers
- Community feedback and support
