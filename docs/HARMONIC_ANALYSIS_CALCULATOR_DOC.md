# Harmonic Analysis Calculator: Calculation Documentation

This document explains the calculations performed by the Harmonic Analysis Calculator (`harmonic_analysis.py`) for waveform synthesis and harmonic distortion analysis.

---

## 1. Waveform Synthesis

**Formula:**  
\[
y(t) = \sum_{n=1}^{N} A_n \cdot \sin(n t + \phi_n)
\]
- \(A_n\): Amplitude of the \(n\)-th harmonic
- \(\phi_n\): Phase angle of the \(n\)-th harmonic (degrees, converted to radians)
- \(t\): Time (radians)

---

## 2. Total Harmonic Distortion (THD)

**Formula:**  
\[
\text{THD} = \frac{\sqrt{\sum_{n=2}^{N} A_n^2}}{A_1} \times 100\%
\]
- \(A_1\): Fundamental amplitude
- \(A_n\): Amplitude of the \(n\)-th harmonic

---

## 3. Crest Factor (CF)

**Formula:**  
\[
\text{CF} = \frac{\text{Peak}}{\text{RMS}}
\]
- Peak: Maximum absolute value of the waveform
- RMS: Root mean square of the waveform

---

## 4. Form Factor (FF)

**Formula:**  
\[
\text{FF} = \frac{\text{RMS}}{\text{Average (rectified)}}
\]
- Average (rectified): Mean of the absolute value of the waveform

---

## 5. Individual Harmonic Distortion

**Formula (for each displayed harmonic):**  
\[
\text{Distortion}_n = \frac{A_n}{A_1} \times 100\%
\]
- Calculated for 1st, 3rd, 5th, 7th, 11th, and 13th harmonics

---

## 6. Waveform Points

- Points for plotting are generated as \((x, y)\) pairs, with \(x\) in degrees.

---

## 7. Caching

- Results are cached in memory and on disk for performance.

---

## 8. Export

- Harmonic data and summary results can be exported to CSV.

---

**For further details, see the code in `/models/theory/harmonic_analysis.py`.**
