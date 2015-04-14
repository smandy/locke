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

shared struct Header(T, uint Consumers, uint Capacity) {
  Padded!long            tail;
  Padded!long[Consumers] heads;
};

mixin template ManyToManyCommon(T, 
										  uint Consumers, 
										  uint Capacity, 
										  uint IDX = 1 ) if (IDX<=Consumers) {
  alias Header!(T, Consumers, Capacity) HeaderType;

  mixin QueueCommon!();

  long currentPos;

  long getHead() {
	 long getMinHead( uint X )( long prev ) {
		static if ( X == 0 ) {
		  return prev;
		} else {
		  return getMinHead!(X-1)( min( prev, nthHead!X) );
		};
	 };
	 
	 long nthHead(uint X)() if (X>=1 && X<=Consumers) {     
		return atomicLoad!(MemoryOrder.acq)( header.heads[X-1].value );
	 }
    return getMinHead!(Consumers-1)( nthHead!Consumers );
  };

  long getTail() {
	 return atomicLoad!(MemoryOrder.acq)( header.commitTail.value);
  };

};

struct ManyToManyWriter( T, uint Consumers, uint Capacity ) if (isPow2(Capacity)) {
  mixin ManyToManyCommon!(T, Consumers, Capacity);

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
	 //enforce( cacheTail - cacheHead <= Capacity, "Overfull queue");
	 return (cacheTail - cacheHead >= Capacity);
  };

  bool reserved = false;
  long reservedPos = long.max;

  T* reserve() {
	 enforce(!reserved);
	 reservedPos = atomicOp!"+="(header.reserveTail.value, 1) - 1;
	 while ( reservedPos - cacheHead == Capacity ) {
		cacheHead = getHead();
	 };
	 reserved = true;
	 return &data[indexOf(reservedPos)];
  };

  void commit() {
	 enforce(reserved);
	 while ( !cas( &header.commitTail.value, reservedPos, reservedPos + 1 ) ) {
		//writefln( "%s vs %s", header.commitTail.value, reservedPos);
	 };
	 cacheTail = reservedPos + 1;
	 reserved = false;
	 reservedPos = long.max;
  };
};

struct ManyToManyReader(T, uint Consumers, uint Capacity, uint index) if (isPow2(Capacity)) {
  mixin ManyToManyCommon!(T, Consumers, Capacity);

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


