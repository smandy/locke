module locke.example.manyToManyReader1;

import locke.example.oneToManyCommon;

import locke.manyToManyShmQueue;
import std.string;
import std.stdio;
import core.thread;
import std.datetime;

void main(string[] args) {
  parseArgs(args);
  alias ManyToManyReader!(Payload, 2, size, 1) ReaderType;
  auto reader = ReaderType("%s.dat".format(  manyToManyPrefix ) );
  readFrom!ReaderType(reader);
};