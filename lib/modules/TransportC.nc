//#include "../../packet.h"
#include "../../includes/socket.h"
#include "../../includes/tcp_packet.h"

configuration TransportC{
     provides interface Transport;
}

implementation{
     components TransportP;
     Transport = TransportP;

     components RandomC as Random;
     TransportP.Random -> Random;

     components new SimpleSendC(AM_PACK);
     TransportP.Sender -> SimpleSendC;

     components new HashmapC(socket_store_t, 10);
     TransportP.sockets -> HashmapC;

     components new TimerMilliC() as  TimerT1;
     TransportP.TimedOut -> TimerT1;

     components new TimerMilliC() as  TimerT2;
     TransportP.AckTimer -> TimerT2;
}
/*




In component `Node':
Node.nc: In function `CommandHandler.setTestServer':
Node.nc:429: warning: passing argument 1 of `Transport.passNeighborsList' from incompatible pointer type
Node.nc: In function `CommandHandler.setTestClient':
Node.nc:461: warning: passing argument 1 of `Transport.passNeighborsList' from incompatible pointer type
Node.nc: In function `CommandHandler.setAppServer':
Node.nc:492: warning: passing argument 1 of `Transport.passNeighborsList' from incompatible pointer type
Node.nc:497: implicit declaration of function `convert2String'
Node.nc:497: warning: assignment makes pointer from integer without a cast
Node.nc: In function `CommandHandler.setAppClient':
Node.nc:529: warning: passing argument 1 of `Transport.passNeighborsList' from incompatible pointer type
Node.nc: In function `convert2String':
Node.nc:861: warning: assignment makes pointer from integer without a cast
Node.nc:863: warning: return from incompatible pointer type
In file included from lib/modules/TransportC.nc:10,
                 from NodeC.nc:74:
In component `TransportP':
lib/modules/TransportP.nc: In function `Transport.stopWait':
lib/modules/TransportP.nc:256: warning: assignment makes pointer from integer without a cast
lib/modules/TransportP.nc: In function `Transport.receive':
lib/modules/TransportP.nc:577: warning: passing argument 3 of `Transport.stopWait' makes integer from pointer without a cast
/opt/tinyos-main/support/make/extras/sim.extra:67: recipe for target 'sim-exe' failed
make: *** [sim-exe] Error 1








*/
