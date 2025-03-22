# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['c:\\Users\\HBAdmin.INDLINE-L1032\\qmlTableView\\main.py'],
    pathex=['.'],
    binaries=[],
    datas=[('c:\\Users\\HBAdmin.INDLINE-L1032\\qmlTableView\\qml', 'qml'), ('c:\\Users\\HBAdmin.INDLINE-L1032\\qmlTableView\\resources', 'resources'), ('c:\\Users\\HBAdmin.INDLINE-L1032\\qmlTableView\\data', 'data')],
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
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['\icons\\app.ico'],
)
