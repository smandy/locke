module locke.padded;

import locke.util : doReplace;

import std.string;
import std.stdio;
import std.conv;

template Padded(T) {
  const postAmbleLength = 128 - 4 * long.sizeof - T.sizeof;
  struct Padded {
	 private long[4] preamble;
	 T value;
	 private byte[postAmbleLength] postAmble;

	 alias value this;
  };
};

version(None) {
  unittest {
	 Padded!long l1;
	 writefln("Padded long size is %s", Padded!long.sizeof);
	 writefln("Padded int  size is %s", Padded!int.sizeof);
	 writefln("Padded char size is %s", Padded!char.sizeof);
	 writefln("Padded byte size is %s", Padded!char.sizeof);
  };
};