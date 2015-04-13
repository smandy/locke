def switcheroo(a,b):
    def ret(x):
        if x==a:
            return b
        else:
            return x
    return ret

if 0:
    env = Environment(
        DFLAGS = ['-Isrc', '-vgc'],
        PREFERRED_D_COMPILER = 'gdc'
        #tools  = ['gdc']
        )  #, DC = 'gdc' )
    s = switcheroo('dmd','gdc')
else:
    env = Environment(
        DFLAGS = ['-Isrc', '-inline','-O', '-vgc']
        )

print "Preferred ", env.get('PREFERRED_D_COMPILERS', ['dmd', 'gdc', 'ldc'])
print env['TOOLS']

env.VariantDir( 'build', 'src')
env.SConscript( 'build/SConscript',
                exports = { 'env' : env } )


