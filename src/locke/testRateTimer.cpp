#inclde "rateTimer.hpp"
#include <chrono>

int main( int argc , char *argv[] ) {

  RateTimer rt;

  while(true) {
    std::this_thread::sleep_for(2s);
  };
    
};
