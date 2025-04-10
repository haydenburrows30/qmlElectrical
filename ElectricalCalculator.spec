# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['Z:\\home\\hayden\\Documents\\qmltest\\main.py'],
    pathex=['.'],
    binaries=[],
    datas=[('Z:\\home\\hayden\\Documents\\qmltest\\qml', 'qml'), ('Z:\\home\\hayden\\Documents\\qmltest\\data', 'data'), ('Z:\\home\\hayden\\Documents\\qmltest\\icons', 'icons')],
    hiddenimports=['PySide6.QtQml', 'PySide6.QtQuick', 'PySide6.QtCore', 'PySide6.QtGui', 'PySide6.QtWidgets', 'PySide6.QtCharts'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='ElectricalCalculator',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=['vcruntime140.dll', 'python3*.dll', 'Qt*.dll'],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['icons\\app.ico'],
)
