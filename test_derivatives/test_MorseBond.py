# -*- coding: utf-8 -*-
"""
Created on Fri Oct 25 11:06:04 2024

@author: n.patsalidis
"""
import numpy as np
from matplotlib import pyplot as plt
import sys
sys.path.append('../main_scripts')
import FF_Develop as ff
from time import perf_counter
params = np.array([2.5,10,3])
m1 = ff.TestPotentials('MorseBond',params,1,10,0.0001,ignore_high_u=100,plot=True)
m1.gradient_check(tol=1,plot=True)
m1.derivative_gradient_check(tol=1e1,verbose=True)
m1.derivative_check(plot=True,verbose=True)

params = np.array([2.2,30,2])
m2 = ff.TestPotentials('MorseBond',params,1,5,0.0001,ignore_high_u=100)
m2.derivative_gradient_check(tol=1e1,verbose=True)
m2.gradient_check(tol=1)
m2.derivative_check(verbose=True)


params = np.array([2.2,30,3])
m3 = ff.TestPotentials('MorseBond',params,1,5,0.0001,ignore_high_u=100)
m3.gradient_check(tol=1e1,verbose=True)
m3.derivative_gradient_check(tol=1e1,verbose=True)
m3.derivative_check(tol=1e1,verbose=True)
m3.time_cost()
m3.vectorization_scalability()