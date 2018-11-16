//#include "../../packet.h"
#include "../../includes/socket.h"
#include "../../includes/tcp_packet.h"

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
0:1:43.272324654 DEBUG (3): A Command has been Issued.
0:1:43.272324654 DEBUG (3): Command Type: Client
0:1:43.272324654 DEBUG (3): setTestServer() -- Initializing Server

0:1:43.272324654 DEBUG (3): Transport.bind -- Successful bind
0:1:43.272324654 DEBUG (3): Transport.listen() -- Server State: Listen with fd(1)
0:2:12.568359784 DEBUG (3): ListenTimer Fired
0:2:12.568359784 DEBUG (3): ListenTimer.fired() -- Server State: Listen
0:2:12.568359784 DEBUG (3): Transport.accept() -- Sockets does contain fd: 1
0:2:12.568359784 DEBUG (3): Transport.accept() -- Sockets state: 1
0:2:12.568359784 DEBUG (3): Transport.accept returning 1
0:2:12.568359784 DEBUG (3): ListenTimer.fired() -- Succesfully saved new fd
0:3:0.558441669 DEBUG (3): A Command has been Issued.
0:3:0.558441669 DEBUG (3): Command Type: Ping
0:3:0.558441669 DEBUG (3):      Package(3,6) Ping Sent
0:3:0.558441669 DEBUG (3): Src: 3 Dest: 6 Seq: 255 TTL: 24 Protocol:0  Payload: Hello, World
0:3:3.360016262 DEBUG (6):      Package(3,6) Ping Recieved Seq(8703): Hello, World
0:3:4.330170451 DEBUG (3):      Package(6,3) Ping Reply Recieved: Hello, World
0:9:47.819336501 DEBUG (3): A Command has been Issued.
0:9:47.819336501 DEBUG (3): Command Type: Ping
0:9:47.819336501 DEBUG (3):     Package(3,6) Ping Sent
0:9:47.819336501 DEBUG (3): Src: 3 Dest: 6 Seq: 66 TTL: 24 Protocol:0  Payload: The World is flat
*/
