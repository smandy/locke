import core.memory;

import std.stdio;

version (X86_64)
{
  T atomicOp(string s : "+=", T)(ref shared T val, T mod) pure nothrow @nogc
	 if (__traits(isIntegral, T))
		{
        T oval = void;
        static if (T.sizeof == 1)
			 {
            asm pure nothrow @nogc
				  {
                mov AL, mod;
                mov RDX, val;
                lock;
                xadd[RDX], AL;
                mov oval, AL;
				  }
			 }
        else static if (T.sizeof == 2)
					{
					  asm pure nothrow @nogc
						 {
							mov AX, mod;
							mov RDX, val;
							lock;
							xadd[RDX], AX;
							mov oval, AX;
						 }
					}
        else static if (T.sizeof == 4)
					{
					  asm pure nothrow @nogc
						 {
							mov EAX, mod;
							mov RDX, val;
							lock;
							xadd[RDX], EAX;
							mov oval, EAX;
						 }
					}
        else static if (T.sizeof == 8)
					{
					  asm pure nothrow @nogc
						 {
							mov RAX, mod;
							mov RDX, val;
							lock;
							xadd[RDX], RAX;
							mov oval, RAX;
						 }
					}
        return oval + mod;
		}
}