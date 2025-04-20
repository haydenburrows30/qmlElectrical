# Impact of Conductance on Characteristic Impedance

The **conductance parameter** has a significant impact on the characteristic impedance of a transmission line. Below is an explanation of this relationship.

## Characteristic Impedance Formula

In transmission line theory, the characteristic impedance ($Z_0$) is calculated as:

$$
Z_0 = \sqrt{\frac{Z}{Y}}
$$

Where:

- **$Z$**: Series impedance per unit length ($R + j\omega L$)
- **$Y$**: Shunt admittance per unit length ($G + j\omega C$)

**Parameter definitions:**
- $R$: Resistance per unit length ($\Omega$/km)
- $L$: Inductance per unit length (H/km)
- $G$: Conductance per unit length (S/km)
- $C$: Capacitance per unit length (F/km)
- $\omega$: Angular frequency ($2\pi f$)

---

## Effects of Increasing Conductance ($G$)

- **Magnitude Effect:**  
  Higher conductance increases the shunt admittance ($Y$), which decreases the magnitude of $Z_0$ (since $Z_0$ is inversely proportional to $\sqrt{Y}$).

- **Phase Angle Effect:**  
  Increased conductance affects the phase angle of the characteristic impedance. With higher $G$, $Z_0$ tends to have a smaller (or even negative) phase angle, indicating more resistive or capacitive behavior.

- **Losses:**  
  Conductance represents leakage current in the insulation between conductors. Higher $G$ means higher dielectric losses.

- **Signal Attenuation:**  
  Increased conductance leads to higher signal attenuation along the line, reflected in the attenuation constant.

---

## Practical Considerations

- For a typical power transmission line, conductance is usually very small (near zero) due to high insulation resistance.
- Under certain conditions (e.g., wet weather, aging insulation), conductance can increase, significantly affecting performance by:
  - Lowering the characteristic impedance
  - Increasing losses

---

## Implementation Note

In your implementation, you can observe this relationship in the calculation section. The alternative impedance calculation also demonstrates that as conductance ($G$) increases, the characteristic impedance magnitude decreases.

---

## Key Concept

The fundamental concept is:

- **Characteristic impedance** ($Z_0 = \sqrt{Z/Y}$) depends only on the per-unit-length parameters ($R$, $L$, $G$, $C$), **not** on the total line length.
- **ABCD parameters** do depend on the line length.