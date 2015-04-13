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


void func(alias F)(string[] args) {
  F( args,
	  "maxIters" , &maxIters,
	  "writerId" , &writerId,
	  "numIds"   , &numIds
	  );
};

// void printArgs(string[] args) {
//   func!argPrinter( args);
//};

void argPrinter( T...)( T ts) {
  static if ( ts.length > 1) {
	 static if (ts.length % 2 != 0) {
		argPrinter( ts[1..$] );
	 } else {
		writefln("%s %s", ts[0], ts[1]);
		argPrinter( ts[2..$] );
	 }
  };
};

void parseArgs( string[] args ) {
  func!argPrinter(args);
  func!getopt(args);
};

void writeTo(T)(T writer) {
  long idx = 0;
  while(idx < maxIters) {
	 while (writer.full) {};
	 atomicStore!(MemoryOrder.seq)(writer.current.id, ++idx);
	 writer.enqueue;
	 if ( (idx & MASK) == 0) {
		writefln("%s... ", idx);
	 };	 
  };
};

void writeToMany(T)(T writer) {
  
  //static Payload exemplar;
  //exemplar.writerId = writerId;
  long idx = 0;
  int[] buckets = new int[numIds];
  auto timer = RateTimer(0);
  while(idx < maxIters) {
	 while (writer.full) {};
	 //atomicOp!"+="(exemplar.id, 1);
	 Payload exemplar;
	 exemplar.id = idx;
	 exemplar.writerId = writerId;
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
	 //int x = reader.avail;
	 //writefln("Avail %s", x);
	 while ( reader.avail()==0) {};

	 ++idx;
	 //writefln("idx %s", idx);
	 immutable v = atomicLoad!(MemoryOrder.seq)(reader.current.id);
	 tot += v;
	 immutable writerId = atomicLoad!(MemoryOrder.seq)(reader.current.writerId);
	 if (writerId < buckets.length) {
		  ++buckets[writerId];
	 }
	 if ( (idx & MASK) == 0 ) {
		writefln("rate = %s/sec %s vs %s...%s %s", 
					timer.rateForTicks(idx), 
					idx, 
					maxIters,
					tot,
					buckets);
	 };
	 reader.advance(1);
	 reader.commitConsumed();
  }
  writefln("rate = %s/sec %s vs %s...%s %s", 
			  timer.rateForTicks(idx), 
			  idx, 
			  maxIters,
			  tot,
			  buckets);
};