module locke.util;

import std.file : exists;
import std.stdio : File;
import std.exception;
import std.string;
import std.range;
import std.stdio;

void makeFileOfSize( string fn, size_t bytes) {
  enforce( !fn.exists(), "%s already exists".format(fn) );
  auto f = File(fn, "w+");
  f.seek( bytes - 1);
  f.write("\x00");
  f.close();
};

bool isPow2(T)(T t ) {
  return (t & (t-1))==0;
};


string doReplace( string strTemplate, string[string] replacements) {
  auto ret = strTemplate;
  foreach( q,v ; replacements) {
	 ret = ret.replace( "${%s}".format(q) , v);
  };
  return ret;
};

version(util) {
  unittest {
	 makeFileOfSize( "/tmp/foo2.dat", 256);
  };
}

version(pow2) {
  unittest {
	 writefln("Woot!");

	 iota(1,20).writeln();
	 iota(1, 20)
		.map!( x => "%2s : %s".format(x , isPow2(x)) )()
		.join("\n")
		.writeln();
  };
}