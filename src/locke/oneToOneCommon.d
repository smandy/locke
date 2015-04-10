
enum prefix          = "/dev/shm/locke/o2o";
enum oneToManyPrefix = "/dev/shm/locke/o2m";

shared struct Memento {
  long id;
  byte[248] pad;
};

alias Payload = Memento;
const size = 2 << 16;