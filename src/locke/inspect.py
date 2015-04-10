import numpy as np


thaip = [ ('pad1', 'S32'),
		    ('value' , np.int64),
          ('pad2', 'S24'),
          ('pad3', 'S64')
          ]

import sys

#fn = sys.argv[1]

import time


while True:
    try:
        mm = np.memmap('/dev/shm/locke/o2m.meta', dtype = np.dtype(thaip))
        xs = mm[:].copy()
        vals =  [x['value'] for x in xs[:]]
        print vals, [ vals[0] - x for x in vals[1:] ]
    except:
        print "Barf"
    time.sleep(1)

