import locke.mmapper;

import locke.padded;
import std.stdio;

import locke.util : isPow2;
import locke.queueCommon;

import core.atomic;
import std.conv;
import std.exception;
import std.algorithm : min;
import core.thread;

shared struct Header(T, int Readers, int Capacity) {
  Padded!long tail;
  Padded!long[Readers] heads;
};

mixin template OneToManyCommon(T, int Readers, int Capacity, int IDX = 1) if (IDX<=Readers) {
  alias Header!(T, Readers, Capacity) HeaderType;

  mixin QueueCommon!();
  //enum size = HeaderType.sizeof + Capacity * T.sizeof;
  HeaderType* header;
  T*          data;

  long currentPos;

  ref T current()  {
	 pragma(msg, typeof(data[indexOf(currentPos)]) );
	 return data[indexOf(currentPos)];
  };

  long getTail() {
	 return atomicLoad!(MemoryOrder.raw)( header.tail.value);
  };

  private long getMin( int X )( long prev ) {
    static if ( X == 0 ) {
      return prev;
    } else {
      return getMin!(X-1)( min( prev, nthHead!X) );
    };
  };

  long getHead() {
    return getMin!(Readers-1)( nthHead!Readers );
  };

  private long nthHead(int X)() if (X>=1 && X<=Readers) {     
    return atomicLoad!(MemoryOrder.raw)( header.heads[X-1].value );
  }
};

struct OneToManyWriter(T, int Readers, int Capacity) if (isPow2(Capacity)) {
  mixin OneToManyCommon!(T,Readers, Capacity);

  long cacheHead;

  this(string fn) {
	 initFile(fn);
	 cacheHead = getHead();
  };

  bool full() {
    if ( currentPos - cacheHead < Capacity) return false;
    cacheHead = getHead();
    return (currentPos - cacheHead == Capacity);
  };

  void enqueue() {
    version(boundsCheck) {
      if ( currentPos - cacheHead >= capacity) {
        writefln("Getting head - cache full");
        cacheHead = getHead();
        enforce(currentPos - cacheHead >= capacity, "Queue full");
      };
    }
    atomicStore!(MemoryOrder.raw)( header.tail.value, ++currentPos);
  };
};

struct OneToManyReader(T, int Readers, int Capacity, int index) if (isPow2(Capacity)) {
  mixin OneToManyCommon!(T, Readers, Capacity);

  long cacheTail;

  this( string fn ) {
    //this.rb = MmapOne!(shared Header!(T,Readers, Capacity))(fn, PROT_READ | PROT_WRITE).instance;

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
	 atomicStore!(MemoryOrder.raw)( header.heads[index-1].value, currentPos);
  };
};


