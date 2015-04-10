
import std.string;
import std.stdio;

import locke.oneToOneShmQueue;
import locke.oneToOneCommon;
import locke.writerCommon;

import core.thread;

void main() {
  alias SHMWriter!(Payload,size) WriterType;
  auto writer = WriterType("%s.dat".format(prefix), "%s.meta".format(prefix) );
  writeTo!WriterType(writer);
};
