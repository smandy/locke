module locke.example.oneToManyCommon;

import locke.rateTimer : RateTimer;
import core.atomic;
import std.getopt;

enum oneToManyPrefix  = "/dev/shm/locke/o2m";
enum manyToManyPrefix = "/dev/shm/locke/m2m";

import std.stdio;

shared struct Memento {
  long id;
  int  writerId;
  byte[244] pad;
};

static assert( Memento.sizeof == 256);

alias Payload = Memento;
enum size   = 2 << 12;
enum msgGap = 2 << 22;
enum MASK   = msgGap - 1;

long maxIters = long.max;
int  writerId = 0;
int  numIds   = 0;

void parseArgs( string[] args) {
  getopt( args,
			 "maxIters" , &maxIters,
			 "writerId" , &writerId,
			 "numIds"   , &numIds
			 );
};

void writeTo(T)(T writer) {
  long idx = 0;
  while(idx < maxIters) {
	 while (writer.full) {};
	 atomicStore!(MemoryOrder.raw)(writer.current.id, ++idx);
	 writer.enqueue;
	 if ( (idx & MASK) == 0) {
		writefln("%s... ", idx);
	 };	 
  };
};

void writeToMany(T)(T writer) {

  static Payload exemplar;
  exemplar.writerId = writerId;
  long idx = 0;
  int[] buckets = new int[numIds];
  auto timer = RateTimer(0);
  while(idx < maxIters) {
	 while (writer.full) {};
	 //atomicOp!"+="(exemplar.id, 1);
	 exemplar.id = idx;
	 writer.offer(exemplar);
	 if ( (++idx & MASK) == 0 ) {
		writefln("rate = %s/sec ...%s vs %s", timer.rateForTicks(idx), idx, maxIters);
	 };
  };	 
};

void readFrom(T)(T reader) {
  long idx = 0;
  writefln("msgGap %032b MASK %032b", msgGap, MASK);
  auto timer = RateTimer(0);
  long tot = 0;
  long expected = 0;
  int[] buckets = new int[numIds];

  while(idx < maxIters) {
	 int x = reader.avail;
	 while(x>0) {
		++idx;
		immutable v = atomicLoad!(MemoryOrder.raw)(reader.current.id);
		tot += v;
		++buckets[reader.current.writerId];
		if ( (idx & MASK) == 0) {
		  writefln("rate = %s/sec %s vs %s...%s %s", 
					  timer.rateForTicks(idx), 
					  idx, 
					  maxIters,
					  tot,
					  buckets);
		};
		reader.advance(1);
		--x;
	 }
	 reader.commitConsumed();
  };
};