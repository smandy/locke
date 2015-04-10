def switcheroo(a,b):
    def ret(x):
        if x==a:
            return b
        else:
            return x
    return ret

if 1:
    env = Environment(
        DFLAGS = ['-Isrc', '-g'],
        PREFERRED_D_COMPILER = 'gdc'
        #tools  = ['gdc']
        )  #, DC = 'gdc' )
    s = switcheroo('dmd','gdc')
else:
    env = Environment(
        DFLAGS = ['-Isrc']
        )

print "Preferred ", env.get('PREFERRED_D_COMPILERS', ['dmd', 'gdc', 'ldc'])
print env['TOOLS']

## SConscript( 'src/SConscript',
##             variant_dir='build/debug',
##             exports = { 'env' : env } )

SConscript( 'src/SConscript',
            #variant_dir='build/debug',
            exports = { 'env' : env } )


