
import std.string;
import std.stdio;

import locke.oneToManyShmQueue;
import locke.example.oneToManyCommon;
import core.thread;

void main() {
  alias OneToManyWriter!(Payload, 1, size) WriterType;
  auto writer = WriterType("%s.dat".format(oneToManyPrefix) );
  writeTo!WriterType(writer);
};
