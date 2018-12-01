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
}
/*

In component `TransportP':
lib/modules/TransportP.nc: In function `Transport.close':
lib/modules/TransportP.nc:680: warning: assignment makes integer from pointer without a cast
lib/modules/TransportP.nc:687: syntax error before `else'
lib/modules/TransportP.nc: At top level:
lib/modules/TransportP.nc:692: syntax error before `return'
TransportP: `Transport.listen' not implemented
TransportP: `Transport.release' not implemented
/opt/tinyos-main/support/make/extras/sim.extra:67: recipe for target 'sim-exe' failed
make: *** [sim-exe] Error 1

*/
