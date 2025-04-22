import os
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
    url = "https://www.python.org/ftp/python/3.12.10/python-3.12.10-amd64.exe"  # Updated to Python 3.12.10
    exe_file = "python-3.12.10-amd64.exe"
    
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
    WINE_PYTHON = "~/wine/drive_c/python312/python.exe"
    if not os.path.exists(os.path.expanduser(WINE_PYTHON)):
        print("Setting up Python in Wine environment...")
        # Install Python
        subprocess.run([
            'wine',
            'python-3.12.10-amd64.exe',
            '/quiet', 
            'InstallAllUsers=1',
            'TargetDir=C:\\python312',
            'Include_test=0',
            'PrependPath=1'
        ], check=True)
        
        print("Upgrading pip...")
        # Upgrade pip first
        subprocess.run([
            'wine',
            'c:\\python312\\python.exe',
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
                'c:\\python312\\python.exe',
                '-m',
                'pip',
                'install',
                '--upgrade',
                package
            ], check=True)
        
        # Install PySide6 - Python 3.12 should have better support for newer PySide6 versions
        print("Installing PySide6...")
        try:
            subprocess.run([
                'wine',
                'c:\\python312\\python.exe',
                '-m',
                'pip',
                'install',
                'PySide6'
            ], check=True, timeout=300)
            print("Successfully installed PySide6")
        except Exception as e:
            print(f"Error installing PySide6: {e}")
            print("WARNING: Could not install PySide6. The build may fail.")
        
        # Install remaining packages
        packages = [
            'pyinstaller>=6.0.0',  # Updated PyInstaller for better Python 3.12 support
            'pillow>=10.0.0'       # Updated Pillow for compatibility
        ]
        
        for package in packages:
            print(f"Installing {package}...")
            result = subprocess.run([
                'wine',
                'c:\\python312\\python.exe',
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
    # Set environment variables to help with cross-platform build issues
    env = os.environ.copy()
    env['PYTHONNOUSERSITE'] = '1'  # Prevent loading user site packages
    env['PYINSTALLER_CONFIG_DIR'] = os.path.expanduser('~/.wine/drive_c/users/Public/pyinstaller')
    # Prevent PyInstaller from trying to strip binaries
    env['PYINSTALLER_NO_STRIP'] = '1'
    
    subprocess.run([
        'wine', 
        'c:\\python312\\python.exe',  # Updated Python path 
        'scripts/windows_build.py'
    ], env=env)

if __name__ == '__main__':
    build_windows()
