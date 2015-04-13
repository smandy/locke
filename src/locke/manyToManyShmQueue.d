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

shared struct Header(T, int Consumers, int Capacity) {
  Padded!long            tail;
  Padded!long[Consumers] heads;
};

mixin template ManyToManyCommon(T, 
										  int Consumers, 
										  int Capacity, 
										  int IDX = 1 ) if (IDX<=Consumers) {
  alias Header!(T, Consumers, Capacity) HeaderType;

  enum size = HeaderType.sizeof + Capacity * T.sizeof;
  HeaderType* header;
  T* data;

  private void initFile( string fn ) {
	 writefln("Size is %s", size);
	 if (!fn.exists()) {
		makeFileOfSize( fn, size);
	 };
	 auto f = File(fn, "a+");
	 void* ptr =  mmap64(null, size, PROT_READ | PROT_WRITE, MAP_SHARED, f.fileno(), 0 );
	 writefln("Ptr is %s", ptr);

	 header = cast(HeaderType*) ptr;
	 data   = cast(T*)         (ptr + HeaderType.sizeof);
	 writefln("Size of header is %s", HeaderType.sizeof);
	 writefln("Header is %s", header);
	 writefln("Data is %s"  , data);
  };

  enum uint MASK = Capacity - 1;

  pure static int indexOf(long n) {
    return cast(int)(n & MASK);
  };

  long currentPos;

  ref T current()  {
	 //pragma(msg, typeof(data[indexOf(currentPos)]) );
	 return data[indexOf(currentPos)];
  };

  private long getMinHead( int X )( long prev ) {
    static if ( X == 0 ) {
      return prev;
    } else {
      return getMinHead!(X-1)( min( prev, nthHead!X) );
    };
  };

  long getHead() {
    return getMinHead!(Consumers-1)( nthHead!Consumers );
  };

  long getTail() {
	 return atomicLoad!(MemoryOrder.raw)( header.tail.value);
  };

  private long nthHead(int X)() if (X>=1 && X<=Consumers) {     
    return atomicLoad!(MemoryOrder.raw)( header.heads[X-1].value );
  }
};

struct ManyToManyWriter(T, int Consumers, int Capacity, bool multiThreaded = false) if (isPow2(Capacity)) {
  mixin ManyToManyCommon!(T, Consumers, Capacity);

  // CacheTail is threadlocal. This will come out in the wash.
  // different threads have different cacheTails but this is okay
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

  void offer(ref T t) {
	 immutable reservedPos = atomicOp!"+="(header.tail.value, 1);
	 //writefln("Reserved is %s", reservedPos);
	 while ( reservedPos - cacheHead == Capacity ) {
		cacheHead = getHead();
	 };
	 data[indexOf(reservedPos)] = t;
	 while ( cas( &header.tail.value, reservedPos - 1, reservedPos ) ) {};
	 cacheTail = reservedPos;
  };
};

struct ManyToManyReader(T, int Consumers, int Capacity, int index) if (isPow2(Capacity)) {
  mixin ManyToManyCommon!(T, Consumers, Capacity);

  long cacheTail;

  this( string fn ) {
    //this.rb = MmapOne!(shared Header!(T,Consumers, Capacity))(fn, PROT_READ | PROT_WRITE).instance;

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


