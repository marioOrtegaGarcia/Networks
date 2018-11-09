#include "../../packet.h"
#include "../../includes/socket.h"

configuration TransportC{
     provides interface Transport;
}

implementation{
     components TransportP;
     /* Transport = TransportP; */

     components new HashmapC(socket_store_t, 10) as Hashmap;
     TransportP.sockets = Hashmap;
}
