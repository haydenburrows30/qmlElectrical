class MenuItems:
    basic = [
        {"name": "Ohm's Law", "source": "pages/calculators/OhmsLaw.qml"},
        {"name": "Single Phase Power", "source": "pages/calculators/SinglePhasePower.qml"},
        {"name": "Three Phase Power", "source": "pages/calculators/ThreePhasePower.qml"}
    ]
    
    protection = [
        {"name": "Cable Short Circuit Current", "source": "pages/calculators/CableShortCircuitCurrent.qml"},
        {"name": "Overload Current", "source": "pages/calculators/OverloadCurrent.qml"},
        {"name": "CT Example", "source": "pages/calculators/CTExample.qml"}
    ]
    
    cable = [
        {"name": "Cable Resistance", "source": "pages/calculators/CableResistance.qml"},
        {"name": "Cable CSA", "source": "pages/calculators/CableCsa.qml"},
        {"name": "Cable Volt Drop", "source": "pages/calculators/CableVoltDrop.qml"}
    ]
    
    theory = [
        {"name": "Harmonics", "source": "pages/calculators/Harmonics.qml"},
        {"name": "Power Factor", "source": "pages/calculators/PowerFactor.qml"},
        {"name": "Transformer Calculations", "source": "pages/calculators/TransformerCalculations.qml"}
    ]
    
    renewables = [
        {"name": "PV Calculations", "source": "pages/calculators/PVCalculations.qml"}
    ]
    
    @classmethod
    def get_all_calculators(cls):
        """Return all calculator items as a flat list"""
        all_calculators = []
        all_calculators.extend(cls.basic)
        all_calculators.extend(cls.protection)
        all_calculators.extend(cls.cable)
        all_calculators.extend(cls.theory)
        all_calculators.extend(cls.renewables)
        return all_calculators