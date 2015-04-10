#!/usr/bin/env rdmd

import std.string;

import std.stdio;
import std.array;


string doReplace( string strTemplate, string[string] replacements) {
  auto ret = strTemplate;
  foreach( q,v ; replacements) {
	 ret = ret.replace( "${%s}".format(q) , v);
  };
  return ret;
};

const strTemplate = """
  private long[4] ${name}_preamble;
  ${thaip} ${name};
  private byte[${postAmbleLength}] ${name}_postamble;
""";

void main() {
  //writefln( "foo" + "foo" + ")s" );

  writefln( doReplace( strTemplate, [ "name" : "head",
												"thaip" : "long",
												"postAmbleLength" : "12"] ) );
};