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

     components new AMReceiverC(AM_PACK) as GeneralReceive;
     TransportP.Receive -> GeneralReceive;

     components new SimpleSendC(AM_PACK);
     TransportP.Sender -> SimpleSendC;

     components new HashmapC(socket_store_t, 10);
     TransportP.sockets -> HashmapC;
}
/*

Run time Error:



0:1:43.326798394 DEBUG (3): A Command has been Issued.
0:1:43.326798394 DEBUG (3): Command Type: Client
0:1:43.326798394 DEBUG (3): setTestServer() -- Initializing Server
0:1:43.326798394 DEBUG (3): Transport.socket()
0:1:43.326798394 DEBUG (3): Transport.bind()
0:1:43.326798394 DEBUG (3): 			-- port: 9
0:1:43.326798394 DEBUG (3): 			-- Successful bind
0:1:43.326798394 DEBUG (3): Transport.listen()
0:1:43.326798394 DEBUG (3): 			-- Successful
0:1:56.505860491 DEBUG (4): A Command has been Issued.
0:1:56.505860491 DEBUG (4): Command Type: Client
0:1:56.505860491 DEBUG (4): Transport.socket()
0:1:56.505860491 DEBUG (4): CommandHandler.setTestClient()
0:1:56.505860491 DEBUG (4): Transport.bind()
0:1:56.505860491 DEBUG (4): 			-- port: 12
0:1:56.505860491 DEBUG (4): 			-- Successful bind
0:1:56.505860491 DEBUG (4): 	-- Got em, Bind Successful.
0:1:56.505860491 DEBUG (4): Transport.connect()
0:1:56.505860491 DEBUG (4): 			-- Port(12)->Port(9) w/ address(3)
0:1:56.505860491 DEBUG (4): 			Breaking before makeTCPPack
0:1:56.505860491 DEBUG (4): 				~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~HERE: length: 8 memcpy not working ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
0:1:56.505860491 DEBUG (4): 				~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~HERE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
0:1:56.505860491 DEBUG (4): 			-- Successful
0:1:56.505860491 DEBUG (4): 	-- Connection Secure.
0:2:12.623047284 DEBUG (3): ListenTimer Fired
0:2:12.623047284 DEBUG (3): ListenTimer.fired() -- Server State: Listen
0:2:12.623047284 DEBUG (3): 			-- Sockets does contain fd: 1
0:2:12.623047284 DEBUG (3): 			-- Sockets state: 1
0:2:12.623047284 DEBUG (3): 			-- returning 1
0:2:12.623047284 DEBUG (3): ListenTimer.fired() -- Succesfully saved new fd
0:2:25.802734918 DEBUG (4): WriteTimer.fired()
0:2:48.102921459 DEBUG (3): A Command has been Issued.
0:2:48.102921459 DEBUG (3): Command Type: Ping
0:2:48.102921459 DEBUG (3): 	Package(3,6) Ping Sent
0:2:48.102921459 DEBUG (3): Src: 3 Dest: 6 Seq: 62 TTL: 24 Protocol:0  Payload: Hello, World
0:2:51.094299681 DEBUG (6): 	Package(3,6) Ping Recieved Seq(7998): Hello, World
0:2:51.330216244 DEBUG (3): 	Package(6,3) Ping Reply Recieved: Hello, World
0:9:22.403321542 DEBUG (3): A Command has been Issued.
0:9:22.403321542 DEBUG (3): Command Type: Ping
0:9:22.403321542 DEBUG (3): 	Package(3,6) Ping Sent
0:9:22.403321542 DEBUG (3): Src: 3 Dest: 6 Seq: 97 TTL: 24 Protocol:0  Payload: The World is flat
root@2bca9a8ca11e:/home/cse160/Networks-Project#




COMPILE  TIME:


In component `TransportP':
lib/modules/TransportP.nc: In function `Transport.makePack':
lib/modules/TransportP.nc:41: syntax error before `;'
lib/modules/TransportP.nc: In function `Transport.connect':
lib/modules/TransportP.nc:264: warning: passing argument 1 of `Transport.makeSynPack' from incompatible pointer type
/opt/tinyos-main/support/make/extras/sim.extra:67: recipe for target 'sim-exe' failed
make: *** [sim-exe] Error 1

*/
