import os
import sys
import subprocess
import urllib.request

def download_file(url: str, filename: str) -> bool:
    """Download a file from URL."""
    if not os.path.exists(filename):
        print(f"Downloading {filename}...")
        try:
            urllib.request.urlretrieve(url, filename)
        except Exception as e:
            print(f"Failed to download {filename}: {e}")
            return False
    return True

def download_python():
    """Download Python Windows installer."""
    url = "https://www.python.org/ftp/python/3.8.10/python-3.8.10.exe"  # Changed to .exe from archive
    exe_file = "python-3.8.10.exe"
    
    if not os.path.exists(exe_file):
        print(f"Downloading {url}...")
        try:
            urllib.request.urlretrieve(url, exe_file)
        except Exception as e:
            print(f"Failed to download Python: {e}")
            return False
    return True

def setup_wine():
    """Setup Wine environment for Windows builds"""
    # Ensure Wine is installed
    if subprocess.call(['which', 'wine']) != 0:
        print("Wine is not installed. Please install wine:")
        print("sudo apt install wine64")
        return False
    
    # Download Python installer
    if not download_python():
        return False
    
    # Setup Python in Wine
    WINE_PYTHON = "~/wine/drive_c/python38/python.exe"
    if not os.path.exists(os.path.expanduser(WINE_PYTHON)):
        print("Setting up Python in Wine environment...")
        # Install Python
        subprocess.run([
            'wine',
            'python-3.8.10.exe',
            '/quiet', 
            'InstallAllUsers=1',
            'TargetDir=C:\\python38',
            'Include_test=0',
            'PrependPath=1'
        ], check=True)
        
        print("Upgrading pip...")
        # Upgrade pip first
        subprocess.run([
            'wine',
            'c:\\python38\\python.exe',
            '-m',
            'pip',
            'install',
            '--upgrade',
            'pip'
        ], check=True)
        
        print("Installing dependencies...")
        # Install basic packages first
        base_packages = [
            'wheel',
            'setuptools'
        ]
        
        for package in base_packages:
            subprocess.run([
                'wine',
                'c:\\python38\\python.exe',
                '-m',
                'pip',
                'install',
                '--upgrade',
                package
            ], check=True)
        
        # Download and install PySide6 wheel
        pyside_wheel = "PySide6-6.4.0-cp38-abi3-win_amd64.whl"
        pyside_url = f"https://download.qt.io/official_releases/QtForPython/pyside6/PySide6-6.4.0-cp38/{pyside_wheel}"
        
        if download_file(pyside_url, pyside_wheel):
            subprocess.run([
                'wine',
                'c:\\python38\\python.exe',
                '-m',
                'pip',
                'install',
                pyside_wheel
            ], check=True)
        
        # Install remaining packages
        packages = [
            'pyinstaller==5.7.0',
            'pillow==9.3.0'
        ]
        
        for package in packages:
            print(f"Installing {package}...")
            result = subprocess.run([
                'wine',
                'c:\\python38\\python.exe',
                '-m',
                'pip',
                'install',
                '--no-cache-dir',
                package
            ], check=True)

    return True

def build_windows():
    """Build Windows executable using Wine"""
    if not setup_wine():
        return
    
    print("Building Windows executable...")
    subprocess.run([
        'wine', 
        'c:\\python38\\python.exe', 
        'build_scripts/windows_build.py'
    ])

if __name__ == '__main__':
    build_windows()
