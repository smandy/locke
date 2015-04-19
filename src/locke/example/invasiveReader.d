module locke.example.manyToManyReader1;

import locke.example.oneToManyCommon;

import locke.invasiveManyToManyShmQueue;
import std.string;
import std.stdio;
import core.thread;
import std.datetime;

void main(string[] args) {
  parseArgs(args);
  alias InvasiveManyToManyReader!(Payload, 1, size, 1) ReaderType;
  auto reader = ReaderType("%s.dat".format(  invasiveManyToManyPrefix ) );
  readFrom!ReaderType(reader);
};