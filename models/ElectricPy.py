import electricpy as ep
'''
natfreq(C, L, Hz=True)
C (float) - Capacitance Value in Farads.
L (float) - Inductance in Henries.
Hz (bool, optional) - Control argument to set return value in either Hz or rad/sec; default=True.
'''
# resonant freq given L & c

qc = ep.natfreq(1E-6, 1.5, Hz=True)

print("Hz=", qc)

'''
electricpy.powerset(P=None, Q=None, S=None, PF=None, find='')
P (float, optional) Real Power, unitless; default=None
Q (float, optional) Reactive Power, unitless; default=None
S (float, optional) Apparent Power, unitless; default=None
PF (float, optional) Power Factor, unitless, provided as a decimal value, lagging is positive, leading is negative; default=None
find (str, optional) Control argument to specify which value should be returned.
'''
# real, reactive, apparent power, power factor
pc = ep.powerset(P=400, Q=200)

print(pc)