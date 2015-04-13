import std.json;
import std.string;
import std.stdio;

import locke.manyToManyShmQueue;
import locke.example.oneToManyCommon;
import core.thread;
import std.file;

void main(string[] args) {
  parseArgs(args);
  alias ManyToManyWriter!(Payload, 1, size) WriterType;
  auto writer = WriterType("%s.dat".format(manyToManyPrefix) );
  writefln("Begin");
  writeToMany!WriterType(writer);
  writefln("End");
};