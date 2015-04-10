module locke.mmapper;

public import core.sys.posix.sys.mman;

import std.file : exists;
import std.stdio : File;

import std.stdio;
import locke.util : makeFileOfSize;

import locke.padded;
import core.atomic;
import std.exception;

struct Mmapper(T) {
  int num;
  this( string fn, int num, int prot) {
	 this.num = num;
	 size_t sz = num * T.sizeof;
	 writefln("Size is %s", sz);
	 if (!fn.exists()) {
		makeFileOfSize( fn, sz);
	 };
	 auto f = File(fn, "a+");
	 ary = cast(T*) mmap64(null, sz, PROT_READ | PROT_WRITE, MAP_SHARED, f.fileno(), 0 );
	 writefln("Ptr is %s", ary);
  };

  T *ary;
  alias ary this;

  ref T opIndex(size_t n) {
	 enforce( n<=num);
	 return ary[n];
  };
};

struct MmapOne(T) {
  T *instance;
  this( string fn, int prot) {
	 size_t sz = T.sizeof;
	 writefln("Size is %s", sz);
	 if (!fn.exists()) {
		makeFileOfSize( fn, sz);
	 };
	 auto f = File(fn, "a+");
	 instance = cast(T*) mmap64(null, sz, PROT_READ | PROT_WRITE, MAP_SHARED, f.fileno(), 0 );
	 writefln("Ptr is %s", instance);
  };
};


version (andyTest) {
  unittest {
	 auto x = MmapOne!long( "/tmp/mmap10.dat", PROT_READ | PROT_WRITE );
	 writefln("x is %s", *x.instance);
	 *x += 10;
	 writefln("x is %s", *x.instance);
  }
};

version(mmapper) {
  unittest {
	 writefln("Doit");
	 auto x = Mmapper!long( "/tmp/mmap2.dat", 10, PROT_READ | PROT_WRITE );
	 auto x2 = 65;
	 auto idx = 0;
	 
	 for(int i = 0;i<10;++i) {
		x[i] = x2++;
	 };
	 
	 auto p2 = Mmapper!(shared Padded!long)( "/tmp/mmap3.dat", 10, PROT_READ | PROT_WRITE );
	 auto x3 = 0L;
	 while(true) {
		atomicStore!(MemoryOrder.rel)(p2[0].value, x3++);
	 };
  };
};