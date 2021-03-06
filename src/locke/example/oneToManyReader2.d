module locke.example.oneToOneReader;

import locke.oneToManyShmQueue;
import std.string;
import std.stdio;
import core.thread;
import std.datetime;

import locke.example.oneToManyCommon;

void main() {
  alias OneToManyReader!(Payload, 4, size, 2) ReaderType;
  auto reader = ReaderType("%s.dat".format(  oneToManyPrefix ) );
  readFrom!ReaderType(reader);
};