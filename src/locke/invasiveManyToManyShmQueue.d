import locke.mmapper;

import locke.padded;
import std.stdio;

import locke.incrementAndGet : atomicOp;

import locke.util : isPow2;
import core.atomic;
import std.conv;
import std.exception;
import std.algorithm : min;
import core.thread;
import locke.queueCommon;
import locke.multipleHeads;

shared struct Header(T, uint Consumers, uint Capacity) {
  Padded!ulong            tail;
  Padded!ulong[Consumers] heads;
};

mixin template InvasiveManyToManyCommon(T, 
										  uint Consumers, 
										  uint Capacity, 
													 uint IDX = 1 ) if (IDX<=Consumers) {
  alias Header!(T, Consumers, Capacity) HeaderType;

  mixin QueueCommon!();
  HeaderType* header;
  T* data;

  long currentPos;

  long getTail() {
	 return atomicLoad!(MemoryOrder.acq)( header.tail.value);
  };

  // getHead() impl that loops over consumers
  mixin MultipleHeads;
};

struct InvasiveManyToManyWriter( T, uint Consumers, uint Capacity ) if (isPow2(Capacity)) {

  pragma(msg, typeof(T.sequenceNumber));

  mixin InvasiveManyToManyCommon!(T, Consumers, Capacity);

  long cacheTail;
  long cacheHead;

  this(string fn) {
	 initFile(fn);
	 cacheHead = getHead();
	 cacheTail = getTail();
  };

  bool full() {
	 if ( cacheTail - cacheHead < Capacity ) return false;
	 cacheTail = getTail();
	 cacheHead = getHead();
	 return (cacheTail - cacheHead >= Capacity);
  };

  void offer(U)( ref U u) if ( U.sizeof == T.sizeof ) {
	 auto reservedPos = atomicOp!"+="(header.tail.value, 1) - 1;
	 pragma(msg, typeof(reservedPos));
	 data[indexOf(reservedPos)] = cast(T) u;
	 atomicStore!(MemoryOrder.rel)(u.sequenceNumber, reservedPos + 1 );
	 cacheTail = reservedPos + 1;
  };
};

struct InvasiveManyToManyReader(T, uint Consumers, uint Capacity, uint index) if (isPow2(Capacity)) {
  mixin InvasiveManyToManyCommon!(T, Consumers, Capacity);

  long cacheTail;

  this( string fn ) {
    //this.rb = MmapOne!(shared Header!(T,Consumers, Capacity))(fn, PROT_READ | PROT_WRITE).instance;
	 initFile(fn);
    currentPos = getHead();
    cacheTail  = getTail();
    writefln("Head %s cacheTail is %s", currentPos, cacheTail);
  };

  uint avail() {
	 immutable firstStab = cast(int)(cacheTail - currentPos);
    if (firstStab > 0 ) return firstStab;
    cacheTail = getTail();

	 uint ret = 0;


    return cast(int)(cacheTail - currentPos);
  };

  void advance(uint n) {
    version(boundsCheck) {
      enforce(avail > 0, "No head to advance beyond!");
    }
	 currentPos += n;
  };

  void commitConsumed() {
	 atomicStore!(MemoryOrder.seq)( header.heads[index-1].value, currentPos);
  };
};


