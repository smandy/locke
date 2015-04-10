import locke.padded;
import locke.mmapper;

import core.sys.posix.sys.mman;

import std.datetime;
import core.atomic;
import std.stdio;
import std.file : remove;

void main( string[] args ) {
  remove("/tmp/pingPong");
  const conv = ( 1.0 / 100e-9) / 1e6;
  auto mm = Mmapper!(shared Padded!long)( "/tmp/pingPong", 2, PROT_READ | PROT_WRITE);
  auto expected = 1L;
  auto lastCount = expected;
  auto sw = StopWatch( AutoStart.yes);
  auto last = sw.peek;
  const float objs = (2<<20) - 1;

  const float fac = 100.0 / objs;
  while(true) {
	 atomicStore!( MemoryOrder.rel )(mm[0].value, expected);
	 while( atomicLoad!(MemoryOrder.acq)(mm[1].value) != expected) {};
	 ++expected;
	 if ( (expected & ( (2 << 20) - 1)) == 0) {
		const newTime = sw.peek();
		const dur = newTime - last;
		last = newTime;
		lastCount = expected;
		const dur2 = dur.hnsecs;
		//objects per hnsec;
		writefln("%s.. %s ns/obj", expected, fac * dur2 );
	 };
  };
};