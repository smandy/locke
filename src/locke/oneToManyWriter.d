
import std.string;
import std.stdio;

import locke.oneToManyShmQueue;
import locke.oneToOneCommon;
import locke.writerCommon;
import core.thread;

void main() {
  alias OneToManyWriter!(Payload, size, 4) WriterType;
  auto writer = WriterType("%s.dat".format(oneToManyPrefix), "%s.meta".format(oneToManyPrefix) );
  writeTo!WriterType(writer);
};
