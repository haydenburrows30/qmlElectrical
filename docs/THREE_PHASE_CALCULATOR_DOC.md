# Three-Phase Sine Wave Calculator: Calculation Documentation

This document explains the calculations performed by the ThreePhaseSineWaveModel (`three_phase.py`) for three-phase waveform analysis.

---

## 1. Waveform Generation

**Formula:**  
\[
v(t) = A \cdot \sin(2\pi f t + \theta)
\]
- \(A\): Amplitude (peak value)
- \(f\): Frequency (Hz)
- \(\theta\): Phase angle (degrees, converted to radians)

Each phase (A, B, C) is generated with its own amplitude and phase angle.

---

## 2. RMS and Peak Values

- **RMS:**  
  \[
  \text{RMS} = \sqrt{\frac{1}{N} \sum_{i=1}^N y_i^2}
  \]
- **Peak:**  
  \[
  \text{Peak} = \max(|y_i|)
  \]

---

## 3. Line-to-Line RMS

**Formula:**  
\[
\text{RMS}_{ab} = \sqrt{\frac{1}{N} \sum_{i=1}^N (y_a - y_b)^2}
\]
(similar for \(bc\) and \(ca\))

---

## 4. Sequence Components

- **Positive Sequence:**  
  \[
  V_1 = \left| \frac{V_a + a V_b + a^2 V_c}{3} \right|
  \]
- **Negative Sequence:**  
  \[
  V_2 = \left| \frac{V_a + a^2 V_b + a V_c}{3} \right|
  \]
- **Zero Sequence:**  
  \[
  V_0 = \left| \frac{V_a + V_b + V_c}{3} \right|
  \]
  where \(a = 1 \angle 120^\circ\).

---

## 5. Power Calculations

- **Active Power (kW):**  
  \[
  P = \sum_{\text{phases}} V_{\text{rms}} I \cos(\phi) / 1000
  \]
- **Reactive Power (kVAR):**  
  \[
  Q = \sum_{\text{phases}} V_{\text{rms}} I \sin(\phi) / 1000
  \]
- **Apparent Power (kVA):**  
  \[
  S = \sum_{\text{phases}} V_{\text{rms}} I / 1000
  \]

---

## 6. Power Factor

**Formula:**  
\[
\text{PF} = |\cos(\text{current angle} - \text{voltage angle})|
\]
Calculated for each phase and averaged.

---

## 7. Total Harmonic Distortion (THD)

- Returns a placeholder value based on frequency for demonstration.
- Not a true harmonic analysis.

---

## 8. Data Export

- Provides methods to get waveform data for plotting and export.

---

**For further details, see the code in `/models/theory/three_phase.py`.**
