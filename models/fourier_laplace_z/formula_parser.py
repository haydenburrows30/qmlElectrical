import re
import numpy as np

def evaluate_custom_formula(t, formula, base_frequency):
    """Parse and evaluate a custom waveform formula with harmonics
    
    Args:
        t: numpy array of time values
        formula: string containing the custom formula
        base_frequency: the base frequency to use for the waveform
        
    Returns:
        tuple: (result_array, formula_display)
    """
    if not formula:
        return np.zeros_like(t), "Empty formula"
    
    # Create a nice display version of the formula
    formula_display = formula
    
    # Initialize result array
    result = np.zeros_like(t)
    
    # Handle basic formulas with harmonics
    try:
        # Look for harmonic patterns like: A*sin(n*w*t)
        # Pattern matching for harmonic components
        harmonic_pattern = r'([+-]?\s*\d*\.?\d*)\s*\*?\s*sin\(\s*(\d+)\s*\*?\s*(\d*\.?\d*)\s*\*?\s*t\s*\)'
        
        # Find all harmonic components
        harmonics = re.findall(harmonic_pattern, formula)
        
        if not harmonics:
            # Try alternative pattern with 2π notation
            harmonic_pattern = r'([+-]?\s*\d*\.?\d*)\s*\*?\s*sin\(\s*(\d+)\s*\*?\s*2\s*\*?\s*[πp]i?\s*\*?\s*(\d*\.?\d*)\s*\*?\s*t\s*\)'
            harmonics = re.findall(harmonic_pattern, formula)
        
        if not harmonics:
            # Try looking for sin(w*t) pattern without harmonics
            simple_pattern = r'([+-]?\s*\d*\.?\d*)\s*\*?\s*sin\(\s*(\d*\.?\d*)\s*\*?\s*t\s*\)'
            simple_harmonics = re.findall(simple_pattern, formula)
            
            if simple_harmonics:
                for amplitude_str, freq_str in simple_harmonics:
                    # Default to 1.0 if amplitude is just a sign or empty
                    amplitude = float(amplitude_str) if amplitude_str.strip() and amplitude_str.strip() not in ['+', '-'] else (1.0 if amplitude_str.strip() != '-' else -1.0)
                    
                    # Default to base frequency if not specified
                    freq = float(freq_str) if freq_str.strip() else base_frequency
                    
                    # Add component
                    result += amplitude * np.sin(2 * np.pi * freq * t)
        
        # Handle 2π notation pattern 
        simple_2pi_pattern = r'([+-]?\s*\d*\.?\d*)\s*\*?\s*sin\(\s*2\s*\*?\s*[πp]i?\s*\*?\s*(\d*\.?\d*)\s*\*?\s*t\s*\)'
        simple_2pi_harmonics = re.findall(simple_2pi_pattern, formula)
        
        if simple_2pi_harmonics:
            for amplitude_str, freq_str in simple_2pi_harmonics:
                # Default to 1.0 if amplitude is just a sign or empty
                amplitude = float(amplitude_str) if amplitude_str.strip() and amplitude_str.strip() not in ['+', '-'] else (1.0 if amplitude_str.strip() != '-' else -1.0)
                
                # Default to base frequency if not specified
                freq = float(freq_str) if freq_str.strip() else base_frequency
                
                # Add component
                result += amplitude * np.sin(2 * np.pi * freq * t)
        
        # Process the harmonic components
        if harmonics:
            for amplitude_str, harmonic_str, freq_str in harmonics:
                # Default to 1.0 if amplitude is just a sign or empty
                amplitude = float(amplitude_str) if amplitude_str.strip() and amplitude_str.strip() not in ['+', '-'] else (1.0 if amplitude_str.strip() != '-' else -1.0)
                
                # Get harmonic number, default to 1 if not specified
                harmonic = int(harmonic_str) if harmonic_str.strip() else 1
                
                # Default to base frequency if not specified
                freq = float(freq_str) if freq_str.strip() else base_frequency
                
                # Add harmonic component
                result += amplitude * np.sin(harmonic * 2 * np.pi * freq * t)
        
        # If no recognized patterns were found, try a safe eval approach with limited functions
        if not harmonics and not simple_harmonics and not simple_2pi_harmonics:
            # Create a safe dictionary with only math functions and NumPy ufuncs
            safe_dict = {
                "sin": np.sin,
                "cos": np.cos,
                "tan": np.tan,
                "exp": np.exp,
                "sqrt": np.sqrt,
                "pi": np.pi,
                "abs": np.abs,
                "t": t,
                "w": 2 * np.pi * base_frequency,
                "f": base_frequency,
                # Add additional functions for more complex expressions
                "sinh": np.sinh,
                "cosh": np.cosh,
                "tanh": np.tanh,
                "log": np.log,
                "log10": np.log10
            }
            
            # Process the formula by replacing common shorthand
            formula_code = formula
            formula_code = formula_code.replace("^", "**")  # Replace ^ with ** for exponentiation
            formula_code = formula_code.replace("π", "pi")  # Replace π with pi
            
            # Evaluate the formula
            result = eval(formula_code, {"__builtins__": {}}, safe_dict)
        
        # If still no result, raise an error
        if np.all(result == 0):
            raise ValueError("No valid terms found in formula")
        
        return result, formula_display
    
    except Exception as e:
        print(f"Error evaluating custom formula: {str(e)}")
        # Return zeros and error message
        return np.zeros_like(t), f"Error: {str(e)}"
