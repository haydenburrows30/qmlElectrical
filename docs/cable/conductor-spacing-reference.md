# Typical Conductor Spacing Values for Transmission Lines

Typical conductor spacing values vary by voltage level and tower configuration.
These values can be used as references when setting up transmission line models.

## Typical Phase-to-Phase Spacings by Voltage Level

| Voltage Level | Typical Conductor Spacing | Notes |
|---------------|---------------------------|-------|
| 69 kV         | 2.5-3.0 meters           | Horizontal configuration |
| 115 kV        | 3.0-3.7 meters           | Horizontal or triangular |
| 138 kV        | 3.5-4.5 meters           | Horizontal or triangular |
| 230 kV        | 5.0-7.0 meters           | Horizontal or triangular |
| 345 kV        | 7.0-9.0 meters           | Horizontal or vertical |
| 500 kV        | 9.0-12.0 meters          | Horizontal or vertical |
| 765 kV        | 12.0-15.0 meters         | Horizontal or vertical |

## Standardized Reference Spacing

When manufacturers specify impedance values for conductors, they typically use one of these reference spacings:

1. **1 foot (0.3048 meters)**: Traditional reference spacing in imperial system
2. **1 meter**: Common reference in metric system
3. **GMD = 1 meter**: Geometric Mean Distance of 1 meter between conductors

## Conversion Formula

To convert reactance from one spacing to another:

X₂ = X₁ + 0.2 × ln(D₂/D₁)

Where:
- X₁ = Reactance at reference spacing D₁ (Ω/km)
- X₂ = Reactance at new spacing D₂ (Ω/km)
- D₁ = Reference spacing (m)
- D₂ = New spacing (m)

## Bundle Configuration vs Conductor Spacing

It's important to distinguish between:

- **Bundle spacing**: Distance between subconductors in the same phase (typically 0.3-0.6m)
- **Conductor spacing**: Distance between different phase conductors (values in table above)

Both affect the line's inductance and reactance, but in different ways.
