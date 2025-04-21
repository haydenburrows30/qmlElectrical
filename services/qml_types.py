from PySide6.QtCore import QUrl
from PySide6.QtQml import qmlRegisterSingletonType, qmlRegisterType

import os

from models.voltdrop.voltage_drop_orion import VoltageDropCalculator
from models.theory.real_time_chart import RealTimeChart
from models.basic.calculator import ConversionCalculator, PowerCalculator, ImpedanceCalculator, ChargingCalculator, KwFromCurrentCalculator
from models.theory.transformer_calculator import TransformerCalculator
from models.cable.voltage_drop_calculator import VoltageDropCalc
from models.theory.motor_calculator import MotorCalculator
from models.basic.power_factor_correction import PowerFactorCorrectionCalculator
from models.cable.cable_ampacity import CableAmpacityCalculator
from models.protection.protection_relay import ProtectionRelayCalculator
from models.theory.harmonic_analysis import HarmonicAnalysisCalculator
from models.theory.instrument_transformer import InstrumentTransformerCalculator
from models.protection.discrimination_analyzer import DiscriminationAnalyzer
from models.cable.charging_calculator import ChargingCalculator
from models.protection.battery_calculator import BatteryCalculator
from models.theory.machine_calculator import MachineCalculator
from models.protection.earthing_calculator import EarthingCalculator
from models.cable.transmission_calculator import TransmissionLineCalculator
from models.protection.delta_transformer import DeltaTransformerCalculator
from models.cable.switchboard_manager import SwitchboardManager
from models.grid_wind.wind_turbine_calculator import WindTurbineCalculator
from models.protection.transformer_line_calculator import TransformerLineCalculator
from models.protection.fault_current_calculator import FaultCurrentCalculator
from models.protection.ref_rgf_calculator import RefRgfCalculator
from models.basic.voltage_divider_calculator import VoltageDividerCalculator
from models.basic.ohms_law_calculator import OhmsLawCalculator
from utils.series_helper import SeriesHelper
from models.theory.three_phase import ThreePhaseSineWaveModel
from models.theory.rlc import RLCChart
from models.protection.overcurrent_calculator import OvercurrentProtectionCalculator
from models.protection.solkor_rf_calculator import SolkorRfCalculator
from models.protection.vr32_cl7_calculator import VR32CL7Calculator
from models.voltdrop.results_manager import ResultsManager
from utils.logger import QLogManager
from models.theory.transformer_naming import TransformerNamingGuide
from models.basic.base_impedance_calculator import BaseImpedanceCalculator
from models.basic.per_unit_impedance_calculator import PerUnitImpedanceCalculator
from models.cable.network_cabinet_calculator import NetworkCabinetCalculator

def register_qml_types(engine, current_dir):
    """Register all QML types and singletons."""
    
    # Register Style singleton
    style_url = QUrl.fromLocalFile(os.path.join(current_dir, "qml", "components","style", "Style.qml"))
    menu_items_url = QUrl.fromLocalFile(os.path.join(current_dir, "qml", "components","menus", "MenuItems.qml"))
    engine.addImportPath(os.path.join(current_dir, "qml"))
    qmlRegisterSingletonType(style_url, "Style", 1, 0, "Style")
    qmlRegisterSingletonType(menu_items_url, "MenuItems", 1, 0, "MenuItems")

    # Register common utility types
    qmlRegisterType(ResultsManager, "App.Models", 1, 0, "ResultsManager")
    qmlRegisterType(QLogManager, "Logger", 1, 0, "LogManager")

    # All types are now QObject subclasses
    return [
        (ChargingCalculator, "Charging", 1, 0, "ChargingCalculator"),
        (PowerCalculator, "PCalculator", 1, 0, "PowerCalculator"),
        (ImpedanceCalculator, "Impedance", 1, 0, "ImpedanceCalculator"),
        (TransformerCalculator, "Transformer", 1, 0, "TransformerCalculator"),
        (MotorCalculator, "MotorStarting", 1, 0, "MotorStartingCalculator"),
        (PowerFactorCorrectionCalculator, "PFCorrection", 1, 0, "PowerFactorCorrectionCalculator"),
        (CableAmpacityCalculator, "CableAmpacity", 1, 0, "AmpacityCalculator"),
        (ProtectionRelayCalculator, "ProtectionRelay", 1, 0, "ProtectionRelayCalculator"),
        (HarmonicAnalysisCalculator, "HarmonicAnalysis", 1, 0, "HarmonicAnalysisCalculator"),
        (InstrumentTransformerCalculator, "InstrumentTransformer", 1, 0, "InstrumentTransformerCalculator"),
        (DiscriminationAnalyzer, "DiscriminationAnalyzer", 1, 0, "DiscriminationAnalyzer"),
        (VoltageDropCalculator, "VDrop", 1, 0, "VoltageDropCalculator"),
        (RealTimeChart, "RealTime", 1, 0, "RealTimeChart"),
        (ThreePhaseSineWaveModel, "Sine", 1, 0, "ThreePhaseSineWaveModel"),
        (VoltageDropCalc, "VoltageDrop", 1, 0, "VoltageDropCalc"),
        (BatteryCalculator, "Battery", 1, 0, "BatteryCalculator"),
        (ConversionCalculator, "Conversion", 1, 0, "ConversionCalculator"),
        (MachineCalculator, "Machine", 1, 0, "MachineCalculator"),
        (EarthingCalculator, "Earthing", 1, 0, "EarthingCalculator"),
        (TransmissionLineCalculator, "Transmission", 1, 0, "TransmissionLineCalculator"),
        (DeltaTransformerCalculator, "DeltaTransformer", 1, 0, "DeltaTransformerCalculator"),
        (SeriesHelper, "SeriesHelper", 1, 0, "SeriesHelper"),
        (RefRgfCalculator, "RefRgf", 1, 0, "RefRgfCalculator"),
        (KwFromCurrentCalculator, "KwFromCurrent", 1, 0, "KwFromCurrentCalculator"),
        (SwitchboardManager, "Switchboard", 1, 0, "SwitchboardManager"),
        (WindTurbineCalculator, "WindTurbine", 1, 0, "WindTurbineCalculator"),
        (OhmsLawCalculator, "OhmsLaw", 1, 0, "OhmsLawCalculator"),
        (TransformerLineCalculator, "TransformerLine", 1, 0, "TransformerLineCalculator"),
        (FaultCurrentCalculator, "FaultCurrent", 1, 0, "FaultCurrentCalculator"),
        (VoltageDividerCalculator, "VoltDivider", 1, 0, "VoltageDividerCalculator"),
        (RLCChart, "RLC", 1, 0, "RLCChart"),
        (SolkorRfCalculator, "SolkorRfCalculator", 1, 0, "SolkorRfCalculator"),
        (VR32CL7Calculator, "VR32CL7Calculator", 1, 0, "VR32CL7Calculator"),
        (OvercurrentProtectionCalculator, "OvercurrentProtectionCalculator", 1, 0, "OvercurrentProtectionCalculator"),
        (TransformerNamingGuide, "TransformerNamingGuide", 1, 0, "TransformerNamingGuide"),
        (BaseImpedanceCalculator, "BaseImpedanceCalculator", 1, 0, "BaseImpedanceCalculator"),
        (PerUnitImpedanceCalculator, "PerUnitImpedance", 1, 0, "PerUnitImpedanceCalculator"),
        (NetworkCabinetCalculator, "NetworkCabinetCalculator", 1, 0, "NetworkCabinetCalculator"),
    ]
