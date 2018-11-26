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

0:1:42.887696389 DEBUG (3): A Command has been Issued.
0:1:42.887696389 DEBUG (3): Command Type: Client
0:1:42.887696389 DEBUG (3): setTestServer() -- Initializing Server
0:1:42.887696389 DEBUG (3): Transport.socket()
0:1:42.887696389 DEBUG (3): Transport.bind()
0:1:42.887696389 DEBUG (3): 			-- port: 9
0:1:42.887696389 DEBUG (3): 			-- Successful bind
0:1:42.887696389 DEBUG (3): Transport.listen()
0:1:42.887696389 DEBUG (3): 			-- Successful
0:1:56.006836387 DEBUG (4): A Command has been Issued.
0:1:56.006836387 DEBUG (4): Command Type: Client
0:1:56.006836387 DEBUG (4): Transport.socket()
0:1:56.006836387 DEBUG (4): CommandHandler.setTestClient()
0:1:56.006836387 DEBUG (4): Transport.bind()
0:1:56.006836387 DEBUG (4): 			-- port: 12
0:1:56.006836387 DEBUG (4): 			-- Successful bind
0:1:56.006836387 DEBUG (4): 	-- Got em, Bind Successful.
0:1:56.006836387 DEBUG (4): Transport.connect()
0:1:56.006836387 DEBUG (4): 			-- Port(12)->Port(9) w/ address(3)
0:1:56.006836387 DEBUG (4): 		/ack
0:1:56.006836387 DEBUG (4): 				~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~HERE: length: 8 memcpy not working ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Segmentation fault




*/
