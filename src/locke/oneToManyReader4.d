module locke.oneToOneReader;

import locke.oneToManyShmQueue;
import std.string;
import std.stdio;
import core.thread;
import std.datetime;
import locke.writerCommon : readFrom;

import locke.oneToOneCommon;

void main() {
  alias OneToManyReader!(Payload, size, 4, 4) ReaderType;
  auto reader = ReaderType("%s.dat".format(  oneToManyPrefix ), 
									"%s.meta".format( oneToManyPrefix ));
  readFrom!ReaderType(reader);
};