#include "../../packet.h"
#include "../../includes/socket.h"

configuration TransportC{
     provides interface Transport;
}

implementation{
     components new TransportP();
     Transport = TransportP.Transport;

     
}
