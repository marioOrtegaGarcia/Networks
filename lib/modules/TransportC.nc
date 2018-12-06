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
:43.359986648 DEBUG (8): 				-- MADE TCP_MSG LETS SEE IF THIS IS WHATS BREAKING
0:2:43.359986648 DEBUG (8): 				-- newConnection->destPort: 9 newConnection->srcPort: 6, seq: 30112
0:2:43.359986648 DEBUG (8): 				-- tcp_msg.destPort: 9 tcp_msg.srcPort: 6 tcp_msg.seq: 30112
0:2:43.359986648 DEBUG (8): 				-- tcp_msg.flag: 1 tcp_msg.numBytes: 0
0:2:43.359986648 DEBUG (8): 				-- Sending Syn Packet: Src->8, Dest-> 3, Seq->30112
0:2:43.359986648 DEBUG (8): 				-- Sending Syn Packet: TTL->18
0:2:43.359986648 DEBUG (8): 				-> Transport.send()
0:2:43.359986648 DEBUG (8): 				-- IP PACK LAYER
0:2:43.359986648 DEBUG (8): 					-- Sending Packet: Src->8, Dest-> 3, Seq->30112
0:2:43.359986648 DEBUG (8): 					-- Sending Packet: TTL->18
0:2:43.359986648 DEBUG (8): 				-- TCP PACK LAYER
0:2:43.359986648 DEBUG (8): 					-- Sending Packet: destPort->9, srcPort-> 6, Seq->30112
0:2:43.359986648 DEBUG (8): 					-- Sending Packet: ack->64639, numBytes->0
0:2:43.359986648 DEBUG (8): 				-- Socket Data:
0:2:43.359986648 DEBUG (8): 				-- destPort: 9, destAddr: 3, srcPort: 6,
0:2:43.359986648 DEBUG (8): 				-- socket->srcPort: 6
0:2:43.359986648 DEBUG (8): 				-- Data->advertisedWindow: 0, Data->ack: 64639
0:2:43.359986648 DEBUG (8): Sent
0:2:43.359986648 DEBUG (8): 				-- Successful
0:2:43.359986648 DEBUG (8): 	-- Connection Secure.
0:2:43.407563300 DEBUG (7): RELAYING TCP PACKET TO NEIGHBORS0:2:46.103791177 DEBUG (6): RELAYING TCP PACKET TO NEIGHBORS0:2:48.541184279 DEBUG (5): RELAYING TCP PACKET TO NEIGHBORS0:2:51.164169951 DEBUG (4): RELAYING TCP PACKET TO NEIGHBORS0:2:52.224609918 DEBUG (4):

		Packet 31600 timed out! Resending...


0:2:53.544251028 DEBUG (3): Recieved a TCP Pack
0:2:53.544251028 DEBUG (3): 	Transport.receive: SYN TCP PACK Recieved with ttl: 13
0:2:53.544251028 DEBUG (3): 	Set flag to SYN+ACK
0:2:53.544251028 DEBUG (3): 				Finding Socket from Sockets Hashmap (we switched the src/dest and ports, if anything weird happens, check here)
0:2:53.544251028 DEBUG (3): 				From PACK::::: sendMessage.dest: 8, sendMessage.src: 3, sendMessage.seq: 30113, sendMessage.TTL: 18, msg.protocol: 4
0:2:53.544251028 DEBUG (3): 				findSocket(9, 255, 255) ->
0:2:53.544251028 DEBUG (3): 				      -- Contained {theSocket.src: 9, theSocket.dest.port: 255, theSocket.dest.addr: 3}
0:2:53.544251028 DEBUG (3): 					nesC be Tripping
0:2:53.544251028 DEBUG (3): 				socket.src: 0 socket.dest.port: 6
0:2:53.544251028 DEBUG (3): 				-> Transport.send()
0:2:53.544251028 DEBUG (3): 				-- IP PACK LAYER
0:2:53.544251028 DEBUG (3): 					-- Sending Packet: Src->3, Dest-> 8, Seq->30113
0:2:53.544251028 DEBUG (3): 					-- Sending Packet: TTL->18
0:2:53.544251028 DEBUG (3): 				-- TCP PACK LAYER
0:2:53.544251028 DEBUG (3): 					-- Sending Packet: destPort->6, srcPort-> 9, Seq->30113
0:2:53.544251028 DEBUG (3): 					-- Sending Packet: ack->64639, numBytes->0
0:2:53.544251028 DEBUG (3): 				-- Socket Data:
0:2:53.544251028 DEBUG (3):




*/
