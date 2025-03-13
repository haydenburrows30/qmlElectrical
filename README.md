# qmlTableView

- Dynamic creation of table rows
- Addition and deletion of rows
- Dropdown and textfield inside cells
- Voltage drop calculation based on resistance and reactance of cable type

Icons used in the program: https://www.figma.com/community/file/944228750903853832

![Image](https://github.com/user-attachments/assets/7ec5ebcb-ec7c-4063-8a1f-71dc462468f9)
![Image](https://github.com/user-attachments/assets/c943cdc3-2fa0-4552-92a5-d06178f0fb15)
![Image](https://github.com/user-attachments/assets/947751dc-5eb7-489b-a081-1d3925c594d1)
![Image](https://github.com/user-attachments/assets/cc69bb5f-4784-4c11-be48-f34b132f1684)


# Installation

```
pip install -r requirements.txt

pip install git+https://github.com/engineerjoe440/ElectricPy.git
```

```
pyside6-rcc resources.qrc -o data/rc_resources.py
```

## Building for Windows

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

## Cross-Platform Building

### Building Windows Executable from Linux
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