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

mm   = np.memmap('/dev/shm/locke/o2m.dat', dtype = thaip  , shape = (5,))
data = np.memmap('/dev/shm/locke/o2m.dat', dtype = Memento, offset = 5 * thaip.itemsize)


while False:
    try:
        mm = np.memmap('/dev/shm/locke/o2m.dat', dtype = np.dtype(thaip), shape = (5,))
        xs = mm[:].copy()
        vals =  [x['value'] for x in xs[:]]
        print vals, [ vals[0] - x for x in vals[1:] ]
    except:
        print "Barf"
    time.sleep(1)

    
    

