import std.stdio;

import locke.rateTimer;
import core.thread;
import std.exception;
import std.string;
import core.atomic;

void writeTo(T)(T writer) {
  long idx = 0;
  while(true) {
	 ///writefln("Reloaded %s", atomicLoad!(MemoryOrder.acq)(writer.current.id));

	 writer.enqueue;
	 if ( idx % ((2 << 20 ) -1) == 0) {
		writefln("%s ...", idx);
	 };	 
  };
};

void readFrom(T)(T reader) {
  long idx = 0;
  const msgGap = 2 << 20;
  const MASK   = msgGap - 1;
  writefln("msgGap %032b MASK %032b", msgGap, MASK);
  auto timer = RateTimer(0);
  long tot = 0;
  long expected = 0;
  while(true) {
	 int cacheAvail = reader.avail;
	 int x = cacheAvail;
	 while(x>0) {
		++idx;
		expected += idx;
		//const v = reader.current.id;
		// pragma(msg, "foo");
		// pragma(msg, typeof( reader.current.id));
		// pragma(msg, "boo");
		//const v = atomicLoad!(MemoryOrder.raw)( reader.current.id);
		auto v = atomicLoad!(MemoryOrder.seq)(reader.current.id);
		tot += v;
		writefln("%s: %s %s", idx, tot, expected);
		enforce(tot==expected, "%s expected %s".format( tot, expected));
		if ( idx % MASK == 0) {
		  writefln("rate = %s/sec %s ...%s", 
					  timer.rateForTicks(idx), 
					  idx, tot);
		};
		--x;
	 }
	 reader.advance(cacheAvail);
  };
};