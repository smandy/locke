import std.datetime;

import std.stdio;
import std.string;

struct RateTimer {
  auto sw = StopWatch( AutoStart.no);

  TickDuration lastTime;
  long lastTicks;

  const hnDurToSecs = 1.0 / 100e-9;

  auto rateForTicks( long ticks ) {
	 const newTime  = sw.peek();
	 const durSecs  = (newTime - lastTime).hnsecs;
	 const deltaTicks = ticks - lastTicks;
	 const rate = (hnDurToSecs  * deltaTicks ) / durSecs;
	 lastTicks = ticks;
	 lastTime  = newTime;
	 return rate;
  };

  this(long ticks) {
	 sw.start();
	 rateForTicks(ticks);
  };
};


