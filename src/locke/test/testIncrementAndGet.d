import locke.incrementAndGet;

import core.thread;
//import core.atomic;
import std.algorithm;
import std.stdio;
import std.array;
import std.range : iota;
import std.functional;

import core.memory : GC;


void main() {

  GC.disable();

  shared int* x = new int(0);

  void inc(int n) {
	 atomicOp!"+="(*x, n); 
  };

  alias partial!(inc,1) inc1;

  auto t1 = new Thread( &inc1 ).start();
  // auto t2 = new Thread( partial!(inc, 1) ).start();
  // auto t3 = new Thread( partial!(inc, 1) ).start();

  foreach( t ; [t1]) {
	 t.join();
  };

  writefln(" x is %s -> %s", x, *x);
};
