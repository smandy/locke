module locke.oneToOneReader;

import locke.oneToOneShmQueue;
import std.string;
import std.stdio;
import core.thread;
import std.datetime;


import locke.oneToOneCommon;
import locke.writerCommon;
import locke.rateTimer;

void main() {
  alias SHMReader!(Payload, size) ReaderType;
  auto reader = ReaderType("%s.dat".format(prefix), 
														"%s.meta".format(prefix));
  readFrom!ReaderType(reader);
};