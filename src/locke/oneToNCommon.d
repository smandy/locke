
mixin template OneToNCommon() {
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
	 return atomicLoad!(MemoryOrder.raw)( headTail.tail);
  };
};