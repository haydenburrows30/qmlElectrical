# Overcurrent Protection Notes

## Curve Selection

- **Add IEC/ANSI Curve Selection**
- Option to choose between IEC and ANSI curves
- Include different curve characteristics:
  - Normal Inverse
  - Very Inverse
  - Extremely Inverse
- Add time multiplier settings

---

## Enhanced Protection Coordination

- Ability to plot time-current curves
- Consider upstream/downstream device coordination
- Add protection grading time settings

---

## Secondary Injection Test Points

- Calculate test points for relay testing
- Include pickup and timing test values
- Consider CT saturation effects

---

## Thermal Capacity Verification

- Add cable thermal withstand calculations
- Check if protection clears fault before thermal damage
- Add temperature rise calculations

---

## Additional Protection Features

- Cold load pickup settings
- Inrush restraint settings
- High-set instantaneous protection (50H)
- Load encroachment blocking

---

## Enhanced Transformer Protection

- Add differential protection settings (87T)
- Include transformer inrush current calculations
- Add restricted earth fault protection (64REF)

---

# Ground Fault Current Calculation and Transformer Configuration

You've identified an important issue: **the ground fault current showing 0 is likely related to the transformer's HV delta configuration**. In a delta configuration, there's no direct connection between the transformer winding and ground on the delta side, which affects how ground faults are calculated.

---

## Solution Approach

Let me fix the ground fault calculation to properly account for the transformer configuration:

- **transformer_line_calculator.py+42-20**

You've correctly identified the issue: the ground fault current showing 0 is indeed due to the HV delta configuration of the transformer.

---

## Why This Matters

In a delta-connected winding (typical for the HV side of distribution transformers):

- Zero sequence currents cannot flow directly through a delta winding
- Ground faults on the delta side have no direct path to return through the neutral
- Any ground fault current on the delta side must find an alternative path, usually through capacitive coupling or through the transformer to the wye side and back

---

## Updated Calculation

The updated calculation now:

- Explicitly checks for a delta-wye configuration (typical for distribution transformers)
- For delta primary (HV side), recognizes that ground fault current will be significantly limited
- Properly models how ground faults on the delta side must find a return path through the transformer
- Calculates a more realistic (and non-zero) value for ground fault current, which will typically be very small compared to three-phase fault currents
- Adds detailed logging of the transformer configuration and impedance values

---

This change will ensure the ground fault current display shows realistic values rather than 0, which will be helpful for protection system design, especially for determining if additional grounding equipment is needed.