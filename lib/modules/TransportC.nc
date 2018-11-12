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
dataStructures/modules/HashmapC.nc:10: expected interface `HashmapC', but got component 'HashmapC'
In file included from NodeC.nc:25:
Node.nc:36: unexpected type arguments
In file included from NodeC.nc:25:
Node.nc: In function `ListenTimer.fired':
Node.nc:153: interface has no command or event named `size'
Node.nc:155: interface has no command or event named `insert'
Node.nc:160: interface has no command or event named `size'
In component `NodeC':
NodeC.nc: At top level:
NodeC.nc:29: expected component `HashmapC', but got a component
NodeC.nc:29: component `HashmapC' is not generic
In file included from NodeC.nc:72:
In component `TransportC':
lib/modules/TransportC.nc:12: expected component `HashmapC', but got a component
lib/modules/TransportC.nc:12: component `HashmapC' is not generic
lib/modules/TransportC.nc:13: no match
In component `NodeC':
NodeC.nc:49: no match
/opt/tinyos-main/support/make/extras/sim.extra:67: recipe for target 'sim-exe' failed
make: *** [sim-exe] Error 1
*/
