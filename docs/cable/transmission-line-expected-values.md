# Expected Results When Changing Transmission Line Parameters

## Bundle Spacing Effect on Impedance

The bundle spacing should have a noticeable effect on impedance, but only when using multiple subconductors:

1. **Increased Bundle Spacing**:
   - **IMPORTANT**: Bundle spacing has NO EFFECT with a single conductor
   - **Increases** the bundle GMR (Geometric Mean Radius) with multiple conductors
   - **Reduces** the inductance per unit length
   - **Reduces** the surge impedance (Z₀)
   - **Increases** the surge impedance loading (SIL)

2. **Physical Explanation**:
   - Wider spacing means less mutual coupling between subconductors
   - This reduces the magnetic flux linkage per unit current
   - Lower flux linkage means lower inductance
   - Since Z₀ = √(L/C), reducing L reduces Z₀

3. **Typical Impact**:
   - Doubling bundle spacing (e.g., 0.3m to 0.6m) should reduce Z₀ by ~3-6%
   - This should increase SIL by ~3-6% 
   - Effect is more noticeable with more sub-conductors

4. **Testing**:
   - First change to 2 or more subconductors - bundle spacing has no effect with 1 conductor
   - Try changing bundle spacing from 0.4m to 0.8m with 2 sub-conductors
   - Expected result: Z₀ decreases by ~4%, SIL increases by ~4%
   - Try the same with 4 sub-conductors for a more noticeable effect

## GMR Effect on Impedance

GMR (Geometric Mean Radius) of a conductor has a significant impact on transmission line parameters:

1. **Effect on Inductance**:
   - GMR is inversely related to inductance
   - Increasing GMR **decreases** inductance according to the formula:
     - L = 0.2 * ln(1/GMR) + 0.5 mH/km (simplified Carson's formula)

2. **Expected Impact**:
   - Doubling the conductor GMR should reduce inductance by ~10-15%
   - This will reduce Z₀ by ~5-8% (since Z₀ ∝ √L/C)
   - Reducing Z₀ will increase SIL by ~5-8% (since SIL ∝ 1/Z₀)
   
3. **Testing**:
   - Try changing GMR from 0.0078m to 0.016m
   - Expected result: Inductance decreases by ~10-15%, Z₀ decreases by ~5-8%
   - This effect will be present for both single conductors and bundles

4. **Physical Explanation**:
   - Larger GMR means increased effective cross-section of the conductor
   - This spreads out the magnetic field, reducing flux linkages
   - Reduced flux linkage means lower inductance per unit length

5. **Real-World Examples**:
   - ACSR "Drake" conductor: GMR = 0.0103m
   - ACSR "Bluebird" conductor: GMR = 0.0122m
   - ACSR "Falcon" conductor: GMR = 0.0133m
   - The larger GMR values create lower-impedance transmission lines

## Other Parameter Effects

When changing the advanced parameters, you should expect to see changes in the UI, particularly in the Results and ABCD Parameters sections.

1. **Bundle Configuration (1-4 conductors)**:
   - Increasing the number of conductors should decrease the characteristic impedance
   - This should update the Z₀ value and affect SIL (Surge Impedance Loading)
   - ABCD parameters should change due to the modified characteristic impedance

2. **Conductor GMR**:
   - Larger GMR reduces inductance and impacts characteristic impedance
   - Z₀ should decrease with larger GMR values

3. **Conductor Temperature**:
   - Higher temperatures increase resistance due to the temperature coefficient
   - This slightly increases attenuation constant (α) and has minor impact on Z₀

4. **Earth Resistivity**:
   - Higher earth resistivity increases series impedance
   - This affects earth-return current paths and slightly increases losses (α)