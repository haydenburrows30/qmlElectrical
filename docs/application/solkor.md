# Solkor Padding Resistance Calculation

This feature helps determine the optimal padding resistance for Solkor protection schemes.

---

## Calculation Steps

1. **Calculate Padding Resistance**

   - Use the formula:  
     $$
     \text{Padding Resistance} = \frac{2000 - \text{loop resistance}}{2}
     $$

2. **Find Best Combination of Standard Resistors**

   - Standard resistor values: **500, 260, 130, 65, 35** (ohms)
   - The algorithm finds the best combination to match the calculated value.

3. **Display the Combination**

   - Shows the result in a clear format, for example:
     - `500 + 65`
     - `2×260 + 35 = 555`

4. **Output**

   - This information is shown in both the UI and the exported PDF.

---

## Example

- **Loop resistance:** 890 Ω
- **Padding resistance:** $(2000 - 890) / 2 = 555$ Ω
- **Best combination:** `2×260 + 35 = 555`

---