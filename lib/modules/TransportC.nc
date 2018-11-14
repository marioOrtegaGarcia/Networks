//#include "../../packet.h"
#include "../../includes/socket.h"

configuration TransportC{
     provides interface Transport;
}

implementation{
     components TransportP;
     Transport = TransportP;

     components new HashmapC(socket_store_t, 10);
     TransportP.sockets -> HashmapC;
}
/*
In component `Node':
Node.nc: In function `ListenTimer.fired':
Node.nc:161: warning: declaration of `fd' shadows global declaration
Node.nc:68: warning: location of shadowed declaration
Node.nc:162: `sockets' undeclared (first use in this function)
Node.nc:162: (Each undeclared identifier is reported only once
Node.nc:162: for each function it appears in.)
Node.nc:167: incompatible type for argument 1 of `Socks.pushback'
/opt/tinyos-main/support/make/extras/sim.extra:67: recipe for target 'sim-exe' failed
make: *** [sim-exe] Error 1
*/
