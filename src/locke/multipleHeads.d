module locke.multipleHeads;

mixin template MultipleHeads() {
  long getHead() {
	 long getMinHead( uint X )( long prev ) {
		static if ( X == 0 ) {
		  return prev;
		} else {
		  return getMinHead!(X-1)( min( prev, nthHead!X) );
		};
	 };
	 
	 long nthHead(uint X)() if (X>=1 && X<=Consumers) {     
		return atomicLoad!(MemoryOrder.acq)( header.heads[X-1].value );
	 }
    return getMinHead!(Consumers-1)( nthHead!Consumers );
  };
}
