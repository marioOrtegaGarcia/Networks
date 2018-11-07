#include "../../packet.h"
#include "../../includes/socket.h"

configuration TransportC{
     provides interface Transport;
}

implementation{
     components TransportP;
     Transport = TransportP;

     components new HashmapC(socket_addr_t, 10) as HashmapC;
     TransportP.sockets = HashmapC;
}
