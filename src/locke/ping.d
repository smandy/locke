import locke.padded;
import locke.mmapper;

import core.sys.posix.sys.mman;

import std.datetime;
import core.atomic;
import std.stdio;

import std.file : remove;

void main( string[] args ) {
  auto mm = Mmapper!(shared Padded!long)( "/tmp/pingPong", 2, PROT_READ | PROT_WRITE);
  auto expected = 1L;
  const MASK = (2 << 23) - 1;
  while(true) {
	 while( atomicLoad!(MemoryOrder.acq, long)(mm[0]) != expected) {};
	 atomicStore!( MemoryOrder.rel , long)(mm[1].value, expected++);
  };
};