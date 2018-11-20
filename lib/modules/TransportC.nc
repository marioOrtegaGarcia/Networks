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

     components new HashmapC(socket_store_t, 10);
     TransportP.sockets -> HashmapC;
}
/*
0:1:42.751633332 DEBUG (3): A Command has been Issued.
0:1:42.751633332 DEBUG (3): Command Type: Client
0:1:42.751633332 DEBUG (3): setTestServer() -- Initializing Server
0:1:42.751633332 DEBUG (3): Transport.socket()
0:1:42.751633332 DEBUG (3): Transport.bind()

0:1:42.751633332 DEBUG (3):                     -- port: 9
0:1:42.751633332 DEBUG (3):                     -- Successful bind
0:1:42.751633332 DEBUG (3): Transport.listen()
0:1:42.751633332 DEBUG (3):                     -- Successful
0:1:55.620117331 DEBUG (4): A Command has been Issued.
0:1:55.620117331 DEBUG (4): Command Type: Client
0:1:55.620117331 DEBUG (4): Transport.socket()
0:1:55.620117331 DEBUG (4): CommandHandler.setTestClient()
0:1:55.620117331 DEBUG (4): Transport.bind()
0:1:55.620117331 DEBUG (4):                     -- port: 12
0:1:55.620117331 DEBUG (4):                     -- Successful bind
0:1:55.620117331 DEBUG (4):     -- Got em, Bind Successful.
0:1:55.620117331 DEBUG (4): Transport.connect()
0:1:55.620117331 DEBUG (4):                     -- Port(12)->Port(9) w/ address(3)
0:1:55.620117331 DEBUG (4):                     -- Dest: 50333952
0:1:55.620117331 DEBUG (4):                     -- Successful
0:1:55.620117331 DEBUG (4):     -- Connection Secure.
0:2:12.047851972 DEBUG (3): ListenTimer Fired
0:2:12.047851972 DEBUG (3): ListenTimer.fired() -- Server State: Listen
0:2:12.047851972 DEBUG (3):                     -- Sockets does contain fd: 1
0:2:12.047851972 DEBUG (3):                     -- Sockets state: 1
0:2:12.047851972 DEBUG (3):                     -- returning 1
0:2:12.047851972 DEBUG (3): ListenTimer.fired() -- Succesfully saved new fd
0:2:24.916016168 DEBUG (4): WriteTimer.fired()
0:2:48.506837014 DEBUG (3): A Command has been Issued.
0:2:48.506837014 DEBUG (3): Command Type: Ping
0:2:48.506837014 DEBUG (3):     Package(3,6) Ping Sent
0:2:48.506837014 DEBUG (3): Src: 3 Dest: 6 Seq: 140 TTL: 24 Protocol:0  Payload: Hello, World
0:2:50.997894662 DEBUG (6):     Package(3,6) Ping Recieved Seq(7308): Hello, World
0:2:51.173401649 DEBUG (3):     Package(6,3) Ping Reply Recieved: Hello, World
0:9:26.091523176 DEBUG (3): A Command has been Issued.
0:9:26.091523176 DEBUG (3): Command Type: Ping
0:9:26.091523176 DEBUG (3):     Package(3,6) Ping Sent
0:9:26.091523176 DEBUG (3): Src: 3 Dest: 6 Seq: 190 TTL: 24 Protocol:0  Payload: The World is flat
*/
