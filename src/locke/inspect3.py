import numpy as np


thaip = np.dtype( [ ('pad1', 'S32'),
                 ('value' , np.int64),
                 ('pad2', 'S24'),
                 ('pad3', 'S64')
                 ] )

header = np.dtype( [ ('tail', thaip),
                     ('head', thaip) ] )

import sys

#fn = sys.argv[1]

import time

mm   = np.memmap('/dev/shm/locke/i2m.dat', dtype = thaip  , shape = (2,))


print mm
    
    

