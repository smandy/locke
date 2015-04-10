
import std.string;
import std.stdio;

import locke.oneToManyShmQueue;
import locke.oneToOneCommon;
import locke.writerCommon;
import core.thread;

void main() {
  alias OneToManyWriter!(Payload, 4, size) WriterType;
  auto writer = WriterType("%s.dat".format(oneToManyPrefix) );
  writeTo!WriterType(writer);
};
