import std.stdio;

import locke.rateTimer;
import core.thread;
import std.exception;
import std.string;
import core.atomic;


  // while(true) {
  // 	 while(writer.full) {
  // 	 };
  // 	 writer.current.id = idx++;
  // 	 writer.enqueue;
  // 	 if ( idx % ((2 << 20) -1) == 0) {
  // 		writefln("%s ...", idx);
  // 	 };	 
  // };


void writeTo(T)(T writer) {
  long idx = 0;
  while(true) {
	 while (writer.full) {};
	 writer.current.id = ++idx;
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
		//auto v = atomicLoad!(MemoryOrder.raw)(reader.current.id);
		immutable v = reader.current.id;
		tot += v;

		expected += idx;
		enforce(tot==expected, "%s expected %s".format( tot, expected));

		if ( idx % MASK == 0) {
		  writefln("rate = %s/sec %s ...%s", 
					  timer.rateForTicks(idx), 
					  idx, tot);
		};
		reader.advance(1);
		--x;
	 }
	 reader.commitConsumed();
  };
};