from PySide6.QtCore import QUrl
from PySide6.QtQml import qmlRegisterSingletonType

import os

from models.voltdrop.voltage_drop_calculator import VoltageDropCalculator
from models.results_manager import ResultsManager
from models.real_time_chart import RealTimeChart
from models.calculator import ConversionCalculator, PowerCalculator, ImpedanceCalculator, ChargingCalculator, KwFromCurrentCalculator
from models.transformer_calculator import TransformerCalculator
from models.voltage_drop_calculator import VoltageDropCalc
from models.motor_calculator import MotorCalculator
from models.power_factor_correction import PowerFactorCorrectionCalculator
from models.cable_ampacity import CableAmpacityCalculator
from models.protection_relay import ProtectionRelayCalculator
from models.harmonic_analysis import HarmonicAnalysisCalculator
from models.instrument_transformer import InstrumentTransformerCalculator
from models.discrimination_analyzer import DiscriminationAnalyzer
from models.charging_calculator import ChargingCalculator
from models.battery_calculator import BatteryCalculator
from models.machine_calculator import MachineCalculator
from models.earthing_calculator import EarthingCalculator
from models.transmission_calculator import TransmissionLineCalculator
from models.delta_transformer import DeltaTransformerCalculator
from models.switchboard.switchboard_manager import SwitchboardManager
from models.wind_turbine_calculator import WindTurbineCalculator
from models.transformer_line_calculator import TransformerLineCalculator
from models.fault_current_calculator import FaultCurrentCalculator
from models.ref_rgf_calculator import RefRgfCalculator
from models.voltage_divider_calculator import VoltageDividerCalculator
from models.ohms_law_calculator import OhmsLawCalculator
from models.series_helper import SeriesHelper
from models.three_phase import ThreePhaseSineWaveModel
from models.rlc import RLCChart
from utils.AboutProgram import ConfigBridge
from models.solkor_rf_calculator import SolkorRfCalculator
from models.vr32_cl7_calculator import VR32CL7Calculator

def register_qml_types(engine, current_dir):
    """Register all QML types and singletons."""
    # Register Style singleton
    style_url = QUrl.fromLocalFile(os.path.join(current_dir, "qml", "components","style", "Style.qml"))
    engine.addImportPath(os.path.join(current_dir, "qml"))
    qmlRegisterSingletonType(style_url, "Style", 1, 0, "Style")

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
        (ResultsManager, "Results", 1, 0, "ResultsManager"),
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
        (ConfigBridge, "ConfigBridge", 1, 0, "ConfigBridge"),
        (SolkorRfCalculator, "SolkorRfCalculator", 1, 0, "SolkorRfCalculator"),
        (VR32CL7Calculator, "VR32CL7Calculator", 1, 0, "VR32CL7Calculator")
    ]
