import locke.mmapper;

import locke.padded;
import std.stdio;

import locke.util : isPow2;
import core.atomic;
import std.conv;
import std.exception;
import core.thread;

struct HeadTail {
  Padded!long tail;
  Padded!long head;
};

static assert(HeadTail.sizeof==256);

mixin template OneToOneCommon() {
  shared HeadTail *headTail;

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
    return atomicLoad!(MemoryOrder.raw)( headTail.tail.value);
  };

  long getHead() {
    //writefln("GetHead");
    return atomicLoad!(MemoryOrder.raw)( headTail.head.value);
  };
};

struct SHMWriter(T, int capacity) if (isPow2(capacity)) {
  mixin OneToOneCommon;

  long cacheHead;

  this( string fn, string headTailFile ) {
    this.mm = Mmapper!T(fn, capacity, PROT_READ | PROT_WRITE);
    this.headTail = MmapOne!(shared HeadTail)(headTailFile, PROT_READ | PROT_WRITE).instance;
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
    atomicStore!(MemoryOrder.raw)( headTail.tail.value, ++currentPos);
  };
};

struct SHMReader(T, int capacity) if (isPow2(capacity)) {
  mixin OneToOneCommon;

  long cacheTail;

  this( string fn, string headTailFile ) {
    this.mm = Mmapper!T(fn, capacity, PROT_READ | PROT_WRITE);
    this.headTail = MmapOne!(shared HeadTail)(headTailFile, PROT_READ | PROT_WRITE).instance;
    currentPos = getHead();
    cacheTail  = getTail();
    writefln("Head %s cacheTail is %s", currentPos, cacheTail);
  };

  bool avail() {
    if ( cacheTail - currentPos > 0) return true;
    cacheTail = getTail();
    return cacheTail - currentPos > 0;
  };

  void advance(int n) {
    version(boundsCheck) {
      enforce(avail(), "No head to advance beyond!");
    }
    atomicStore!(MemoryOrder.raw)( headTail.head.value, ++currentPos);
  };
};


version(o2o) {
  import std.stdio;

  enum MsgType : uint { L1_UPDATE, L2_UPDATE, L3_UPDATE, TRADE };

  struct MD {
    MsgType msgType;
    int     securityId;
  };

  unittest {
    writefln("Woot shm");

    auto prefix = "/tmp/foo8";
    import std.string;
    auto writer = SHMWriter!(MD,16)("%s.dat".format(prefix), "%s.meta".format(prefix) );
    writefln("Writer created");
    auto reader = SHMReader!(MD,16)("%s.dat".format(prefix), "%s.meta".format(prefix));
    writefln("Reader created");
    auto x = writer.current;
    pragma(msg, typeof(x));

    writefln("before write reader avail is %s", reader.avail());

    writer.current.msgType = MsgType.L2_UPDATE;
    writer.current.securityId = 666;
    writefln(to!string(writer.current()));
    writer.enqueue();
    writefln("after write1 reader avail is %s", reader.avail());

    writer.current.msgType = MsgType.TRADE;
    writer.current.securityId = 667;
    writefln(to!string(writer.current()));
    writer.enqueue();
    writefln("after write2 reader avail is %s", reader.avail());

    writefln("Reading .... %s", to!string(reader.current));
    reader.advance();
    writefln("after read1 reader avail is %s", reader.avail());

    writefln("Reading .... %s" , to!string(reader.current));
    reader.advance();
    writefln("after read2 reader avail is %s", reader.avail());
  };
};



