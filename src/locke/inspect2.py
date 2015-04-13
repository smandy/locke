import numpy as np


thaip = dtype( [ ('pad1', 'S32'),
                 ('value' , np.int64),
                 ('pad2', 'S24'),
                 ('pad3', 'S64')
                 ] )

Memento = dtype( [ ('id', np.int64),
                   ('pad', 'S248') ] )
import sys

#fn = sys.argv[1]

import time

mm   = np.memmap('/dev/shm/locke/m2m.dat', dtype = thaip  , shape = (3,))
data = np.memmap('/dev/shm/locke/m2m.dat', dtype = Memento, offset = 5 * thaip.itemsize)

print mm
    
    

