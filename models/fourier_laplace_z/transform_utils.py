# Try to import pywt, but provide fallback if not available
try:
    import pywt
    PYWT_AVAILABLE = True
except ImportError:
    PYWT_AVAILABLE = False
    print("PyWavelets (pywt) not available, using basic wavelet implementation")

# Add any shared utility functions here
def get_available_wavelet_types():
    """Returns a list of available wavelet types based on PyWavelets availability"""
    if PYWT_AVAILABLE:
        # Return a subset of common wavelets for better UI experience
        return ['db1', 'db2', 'db4', 'sym2', 'sym4', 'coif1', 'coif3', 'morl']
    else:
        return ['Basic']
