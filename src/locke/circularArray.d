import locke.util;

import std.exception;

struct CircularArray(T, int capacity) {
  enum uint MASK = capacity - 1;
  
  long head;
  long tail;
  
  T[capacity] data;
  
  void boundsCheck() {
	 enforce( tail - head < capacity, "Buffer is full");
  };
  
  size_t indexOf(ulong n ) {
	 return cast(size_t)(n & MASK);
  };
  
  void enqueue( T t) {
	 boundsCheck();
	 data[indexOf(tail++)] = t;
  };
  
  T pop() {
	 enforce( size()>0, "Pop from empty array");
	 return data[indexOf(head++)];
	 };
  
  int size() {
	 return cast(int)(tail - head);
  };
  
  version(unittest) {
	 void dump() {
		import std.stdio;
		writeln(data);
	 };
  };
};

version(carray) {
  unittest {
	 import std.stdio;
	 CircularArray!(int,16) x;
	 x.enqueue(10);
	 x.dump();
	 x.enqueue(20);
	 x.dump();
	 writeln(x.pop);
	 x.dump();
	 writeln(x.pop);
	 x.dump();

	 x.enqueue(30);
	 x.dump();
	 x.enqueue(40);
	 x.dump();
	 writeln(x.pop);
	 x.dump();
	 writeln(x.pop);
	 x.dump();
  };
};