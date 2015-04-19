import std.json;
import std.string;
import std.stdio;

import locke.invasiveManyToManyShmQueue;
import locke.example.oneToManyCommon;
import core.thread;
import std.file;

void main(string[] args) {
  parseArgs(args);
  alias InvasiveManyToManyWriter!(Payload, 1, size) WriterType;
  auto writer = WriterType("%s.dat".format(invasiveManyToManyPrefix) );
  writefln("Begin");
  writeToManyInvasive!WriterType(writer);
  writefln("End");
};