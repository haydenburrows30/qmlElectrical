The conductance parameter has a significant impact on the characteristic impedance of a transmission line. Let me explain this relationship:

Impact of Conductance on Characteristic Impedance
In transmission line theory, the characteristic impedance (Z₀) is calculated using the formula:

Z₀ = √(Z/Y)

Where:

Z is the series impedance per unit length (R + jωL)
Y is the shunt admittance per unit length (G + jωC)
Breaking this down:

R is the resistance per unit length (Ω/km)
L is the inductance per unit length (H/km)
G is the conductance per unit length (S/km)
C is the capacitance per unit length (F/km)
ω is the angular frequency (2πf)
When conductance G increases:

Magnitude Effect: Higher conductance increases the shunt admittance Y, which decreases the magnitude of Z₀. This is because Z₀ is inversely proportional to the square root of Y.

Phase Angle Effect: Conductance affects the phase angle of the characteristic impedance. With higher conductance, the characteristic impedance tends to have a smaller phase angle (or even negative phase angle), indicating a more resistive or capacitive behavior.

Losses: Conductance represents the leakage current in the insulation between conductors. Higher conductance means higher dielectric losses in the transmission line insulation.

Signal Attenuation: Increased conductance leads to higher signal attenuation along the line, which is reflected in the attenuation constant.

In your implementation, you can observe this relationship in the calculation section:

For a typical power transmission line, conductance is usually very small (near zero) because the insulation between conductors has high resistance. However, in certain conditions like wet weather or aging insulation, conductance can increase and significantly affect the line's performance by lowering the characteristic impedance and increasing losses.

The alternative impedance calculation you've implemented also shows this relationship:

This clearly demonstrates that as conductance (part of g) increases, the characteristic impedance magnitude decreases.



The fundamental concept to understand is that characteristic impedance Z₀ = √(Z/Y) depends only on the per-unit-length parameters (R, L, G, C) and not on the total line length. The ABCD parameters, however, do depend on the line length.