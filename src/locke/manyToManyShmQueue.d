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

shared struct Header(T, int Consumers, int Capacity) {
  Padded!long            reserveTail;
  Padded!long            commitTail;
  Padded!long[Consumers] heads;
};

mixin template ManyToManyCommon(T, 
										  int Consumers, 
										  int Capacity, 
										  int IDX = 1 ) if (IDX<=Consumers) {
  alias Header!(T, Consumers, Capacity) HeaderType;

  mixin QueueCommon!();

  HeaderType* header;
  T* data;

  mixin MultipleHeads;

  final long getTail() {
	 return atomicLoad!(MemoryOrder.acq)( header.commitTail.value);
  };

};

struct ManyToManyWriter( T, int Consumers, int Capacity ) if (isPow2(Capacity)) {
  mixin ManyToManyCommon!(T, Consumers, Capacity);

  long cacheTail;
  long cacheHead;

  this(string fn) {
	 writefln("Calling initfile");
	 initFile(fn);
	 writefln("Getting head");
	 cacheHead = getHead();
	 writefln("head %s", cacheHead);
	 cacheTail = getTail();
	 writefln( "tail %s", cacheTail);
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
	 while ( !cas( &header.commitTail.value, reservedPos, reservedPos + 1 ) ) {};
	 cacheTail = reservedPos + 1;

	 reserved = false;
	 reservedPos = long.max;
  };
};

struct ManyToManyReader(T, int Consumers, int Capacity, int index) if (isPow2(Capacity)) {
  mixin ManyToManyCommon!(T, Consumers, Capacity);

  long cacheTail;

  this( string fn ) {
	 initFile(fn);
    currentPos = getHead();
    cacheTail  = getTail();
    writefln("Head %s cacheTail is %s", currentPos, cacheTail);
  };

  int avail() {
	 immutable firstStab = cast(int)(cacheTail - currentPos);
    if (firstStab > 0 ) return firstStab;
    cacheTail = getTail();
    return cast(int)(cacheTail - currentPos);
  };

  void advance(int n) {
    version(boundsCheck) {
      enforce(avail > 0, "No head to advance beyond!");
    }
	 currentPos += n;
  };

  void commitConsumed() {
	 atomicStore!(MemoryOrder.seq)( header.heads[index-1].value, currentPos);
  };
};


