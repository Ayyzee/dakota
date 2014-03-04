// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

int main(int argc, char** argv, char** envp)
{
  sockaddr_in client_sin = sin_create(INADDR_ANY, 0);

  connection::slots_t* client_connection = connection::make(connection::klass, rcv_msg_callback);
  int n = connection::establish(client_connection, &client_sin, connection::CLIENT);  sc(n);
  connection::snd_msg(client_connection, msg);
  event_queue::loop(event_queue_klass::get_current(event_queue::klass), NULL);

  sys::exit(EXIT_FAILURE);
}
