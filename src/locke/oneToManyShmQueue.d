import locke.mmapper;

import locke.padded;
import std.stdio;

import locke.util : isPow2;
import core.atomic;
import std.conv;
import std.exception;
import std.algorithm : min;
import core.thread;

struct Header(int N) {
  Padded!long tail;
  Padded!long[N] heads;
};

static assert(Header!1.sizeof==256); // (* 3 128 ) 384
static assert(Header!2.sizeof==384);

mixin template OneToManyCommon(T, int N, int IDX = 1) if (IDX<=N) {
  shared Header!N *header;

  enum uint MASK = capacity - 1;
  Mmapper!T mm;
  int indexOf(long n) {
    return cast(int)(n & MASK);
  };
  long currentPos;
  ref T current() {
    return mm[indexOf(currentPos)];
  };


  long getTail() {
    //writefln("GetTail");
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
    return getMin!(N-1)( nthHead!N );
  };

  private long nthHead(int X)() if (X>=1 && X<=N) {     
    return atomicLoad!(MemoryOrder.raw)( header.heads[X-1].value );
  };
};

struct OneToManyWriter(T, int capacity, int N) if (isPow2(capacity)) {
  mixin OneToManyCommon!(T,N);

  long cacheHead;

  this( string fn, string headerFile ) {
    this.mm = Mmapper!T(fn, capacity, PROT_READ | PROT_WRITE);
    this.header = MmapOne!(shared Header!N)(headerFile, PROT_READ | PROT_WRITE).instance;
    currentPos = getTail(); 
    cacheHead  = getHead();
    writefln("Tail is %s cacheHead is %s", currentPos, cacheHead);
  };

  bool full() {
    if ( currentPos - cacheHead < capacity) return false;
    cacheHead = getHead();
    return (currentPos - cacheHead == capacity);
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

struct OneToManyReader(T, int capacity, int N, int index) if (isPow2(capacity)) {
  mixin OneToManyCommon!(T,N,index);

  long cacheTail;

  this( string fn, string headerFile ) {
    this.mm = Mmapper!T(fn, capacity, PROT_READ | PROT_WRITE);
    this.header = MmapOne!(shared Header!N)(headerFile, PROT_READ | PROT_WRITE).instance;
    currentPos = getHead();
    cacheTail  = getTail();
    writefln("Head %s cacheTail is %s", currentPos, cacheTail);
  };

  int avail() {
	 const firstStab = cast(int)(cacheTail - currentPos);
    if (firstStab > 0 ) return firstStab;
    cacheTail = getTail();
    return cast(int)(cacheTail - currentPos);
  };

  void advance(int n) {
    version(boundsCheck) {
      enforce(avail > 0, "No head to advance beyond!");
    }
	 currentPos += n;
    atomicStore!(MemoryOrder.raw)( header.heads[index-1].value, currentPos);
  };
};


