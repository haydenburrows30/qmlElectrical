# Lightning Protection System Designer

A calculator for designing lightning protection systems according to IEC 62305 standards.

## Features

- Calculates lightning strike probability based on location and structure characteristics
- Determines appropriate protection level based on risk analysis
- Provides key protection system parameters:
  - Rolling sphere radius
  - Mesh grid size
  - Down conductor spacing
  - Separation distance
  - Ground resistance targets
- Supports different structure types with specific risk factors
- Generates detailed protection system reports

## Parameters

### Structure Parameters

- **Height**: Structure height in meters
- **Length**: Structure length in meters
- **Width**: Structure width in meters
- **Structure Type**: 
  - Common structure
  - Metal structure
  - Structure with flammable contents
  - Structure with explosive/chemical contents
  - Hospital or school

### Location Parameters

- **Thunderdays per year**: Average number of days with thunder activity
- **Ground resistivity**: Soil resistivity in ohm-meters
- **Terrain coefficient**: Adjustment for terrain type (0.1-1 for urban, 1 for flat land, 2 for hilly terrain)

### Protection System

- **Protection Level**: I, II, III, or IV (according to IEC 62305)
- **Mesh Method**: Whether to apply mesh method
- **Rolling Sphere**: Whether to apply rolling sphere method

## Results

- **Ground flash density**: Flashes per km² per year
- **Collection area**: Effective lightning collection area in m²
- **Annual strikes**: Expected direct strike frequency
- **Required efficiency**: Protection system efficiency requirement
- **Recommended level**: Recommended protection level based on risk
- **Protection system parameters**:
  - Rolling sphere radius
  - Mesh size
  - Down conductor spacing
  - Required down conductors
  - Minimum ground rods
  - Separation distance
  - Target ground resistance
- **Protection probability**: Overall protection effectiveness percentage

## Standards

This calculator follows principles from these standards:
- IEC 62305-1: Protection against lightning - General principles
- IEC 62305-2: Protection against lightning - Risk management
- IEC 62305-3: Protection against lightning - Physical damage to structures and life hazard
- IEC 62305-4: Protection against lightning - Electrical and electronic systems within structures

## Notes

- The calculator provides a preliminary design assessment
- For critical installations, a detailed risk assessment by a qualified professional is recommended
- Local building codes and standards should be considered for final implementation