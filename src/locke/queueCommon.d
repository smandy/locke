module locke.queueCommon;

mixin template QueueCommon() {
  enum uint MASK = Capacity - 1;
  enum size = HeaderType.sizeof + Capacity * T.sizeof;

  final private void initFile( string fn ) {
	 writefln("Size is %s", size);
	 if (!fn.exists()) {
		makeFileOfSize( fn, size);
	 };
	 auto f = File(fn, "a+");
	 void* ptr =  mmap64(null, size, PROT_READ | PROT_WRITE, MAP_SHARED, f.fileno(), 0 );
	 enforce( ptr, "Failed to mmap");
	 writefln("Ptr is %s", ptr);

	 header = cast(HeaderType*) ptr;
	 data   = cast(T*)         (ptr + HeaderType.sizeof);
	 writefln("Size of header is %s", HeaderType.sizeof);
	 writefln("Header is %s", header);
	 writefln("Data is %s"  , data);
  };


  final pure static int indexOf(long n) {
    return cast(int)(n & MASK);
  };

  long currentPos;

  final ref T current()  {
	 return data[indexOf(currentPos)];
  };
}