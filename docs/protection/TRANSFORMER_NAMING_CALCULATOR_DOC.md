# Transformer Naming Calculator: Calculation Documentation

This document explains the logic and calculations performed by the Transformer Naming Calculator (`transformer_naming.py`) for generating standard names and descriptions for CTs (Current Transformers) and VTs (Voltage Transformers).

---

## 1. Naming Format Construction

- **CT Ratio:**  
  \[
  \text{CT Ratio} = \frac{I_{primary}}{I_{secondary}}
  \]
  Example: `100/5` (100A primary, 5A secondary)

- **VT Ratio:**  
  \[
  \text{VT Ratio} = \frac{V_{primary}}{V_{secondary}}
  \]
  Example: `11000/110` (11000V primary, 110V secondary)

- **Standard Formats:**  
  The calculator generates names in several industry formats:
  - **IEC:**  
    `{type} {ratio} {accuracy_class} {burden}VA {insulation}kV`
  - **ANSI:**  
    `{type}-{ratio}:{accuracy_class}:{thermal}` (CT)  
    `{type}-{ratio}:{accuracy_class}:{burden}` (VT)
  - **ABB:**  
    `CT-{ratio}-{accuracy_class}-{burden}VA-{insulation}kV-{installation}`
  - **Siemens:**  
    `{type} {ratio} {accuracy_class}/{application} {burden}VA {thermal}x`

---

## 2. Parameter Validation

- All input parameters (type, accuracy class, rated current/voltage, secondary rating, burden, insulation, application, installation, frequency, thermal rating) are validated against reference lists to ensure only valid combinations are used.

---

## 3. Description Generation

- For each part of the name, a description is generated:
  - **CT Example:**  
    - CT: Current Transformer  
    - 100/5: 100A primary, 5A secondary  
    - 0.5: Accuracy class (measurement error limit)  
    - 5P20: Protection class (5% accuracy, ALF=20)  
    - 15VA: Rated burden  
    - 12kV: Insulation level  
    - 1.2x: Thermal rating  
    - metering/protection/combined: Application  
    - indoor/outdoor: Installation  
    - 50Hz: Frequency

  - **VT Example:**  
    - VT: Voltage Transformer  
    - 11000/110: 11000V primary, 110V secondary  
    - 0.5: Accuracy class  
    - 100VA: Rated burden  
    - 12kV: Insulation level  
    - 1.2x: Thermal rating  
    - metering/protection/combined: Application  
    - indoor/outdoor: Installation  
    - 50Hz: Frequency

---

## 4. Error Handling

- If an invalid parameter is set, an error message is generated and signaled.

---

## 5. Slot Methods

- The calculator provides slot methods to get available options for each parameter, for use in UI dropdowns.

---

**For further details, see the code in `/models/theory/transformer_naming.py`.**
