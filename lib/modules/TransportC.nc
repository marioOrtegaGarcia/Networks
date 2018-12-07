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

     components new ListC(uint8_t, 255) as cList;
     TransportP.cChars -> cList;

     components new ListC(char, 255) as cList2;
     TransportP.chars -> cList2;

     components new ListC(char[], 255) as cList3;
     TransportP.users -> cList3;


}
/*




0:1:51.575622802 DEBUG (1): 		ATTEMPTING TO CALL RECIEVECOMM, CHARDATA: 10
0:1:51.575622802 DEBUG (1): 17
0:1:51.575622802 DEBUG (1): Character: h int: 104
0:1:51.575622802 DEBUG (1): Character: e int: 101
0:1:51.575622802 DEBUG (1): Character: l int: 108
0:1:51.575622802 DEBUG (1): Character: l int: 108
0:1:51.575622802 DEBUG (1): Character: o int: 111
0:1:51.575622802 DEBUG (1): Character:   int: 32
0:1:51.575622802 DEBUG (1): Character: a int: 97
0:1:51.575622802 DEBUG (1): Character: s int: 115
0:1:51.575622802 DEBUG (1): Character: c int: 99
0:1:51.575622802 DEBUG (1): Character: e int: 101
0:1:51.575622802 DEBUG (1): Character: r int: 114
0:1:51.575622802 DEBUG (1): Character: p int: 112
0:1:51.575622802 DEBUG (1): Character: a int: 97
0:1:51.575622802 DEBUG (1): Character:   int: 32
0:1:51.575622802 DEBUG (1): Character: 3 int: 51
0:1:51.575622802 DEBUG (1): Hello command Recieved
0:2:11.054687776 DEBUG (2): 	 transfer: 16
0:2:11.054687776 DEBUG (2): 	 Packet 8934 timed out! Resending char 10

0:2:11.147430683 DEBUG (1): Recieved a TCP Pack
0:2:11.147430683 DEBUG (1): 	Transport.receive() Data packet
0:2:11.147430683 DEBUG (1): 	 ~~~~~~~TCP PACKET~~~~~~~
0:2:11.147430683 DEBUG (1): 	 Ports {src: 49 dest: 41}
0:2:11.147430683 DEBUG (1): 	 payload: 10 seq: 8934 flag: 10 numBytes: 1
0:2:11.147430683 DEBUG (1): 	 ~~~~~~~IP PACKET~~~~~~~
0:2:11.147430683 DEBUG (1): 	 Node {src: 2 dest: 1}
0:2:11.147430683 DEBUG (1): 	 seq: 1663 TTL: 17 protocol: 4
0:2:11.147430683 DEBUG (1): 				findSocket(41, 49, 2) ->
0:2:11.147430683 DEBUG (1): 				      -- Contained {theSocket.src: 41, theSocket.dest.port: 49, theSocket.dest.addr: 2}
0:2:11.147430683 DEBUG (1): 					nesC: Let's debug the debug and get this pan
0:2:11.147430683 DEBUG (1): 				-> Transport.send()
0:2:11.147430683 DEBUG (1): 				-- IP PACK LAYER
0:2:11.147430683 DEBUG (1): 					-- Sending Packet: Src->1, Dest-> 2, Seq->1664
0:2:11.147430683 DEBUG (1): 					-- Sending Packet: TTL->17
0:2:11.147430683 DEBUG (1): 				-- TCP PACK LAYER
0:2:11.147430683 DEBUG (1): 					-- Sending Packet: destPort->49, srcPort-> 41, Seq->8934
0:2:11.147430683 DEBUG (1): 					-- Sending Packet: ack->8935, numBytes->1
0:2:11.147430683 DEBUG (1): 				-- Socket Data:
0:2:11.147430683 DEBUG (1): 				-- destPort: 49, destAddr: 2, srcPort: 41,
0:2:11.147430683 DEBUG (1): 				-- socket->srcPort: 41
0:2:11.147430683 DEBUG (1): 				-- Data->advertisedWindow: 0, Data->ack: 8935
0:2:11.147430683 DEBUG (1): Sent
0:2:11.147430683 DEBUG (1): 		ATTEMPTING TO CALL RECIEVECOMM, CHARDATA: 10
0:2:11.147430683 DEBUG (1): 1
0:2:11.147430683 DEBUG (1): Hello command Recieved
0:2:11.378219727 DEBUG (2): Recieved a TCP Pack
0:2:11.378219727 DEBUG (2): 	Transport.receive() default flag ACK
0:2:11.378219727 DEBUG (2): 				findSocket(49, 41, 1) ->
0:2:11.378219727 DEBUG (2): 				      -- Contained {theSocket.src: 49, theSocket.dest.port: 41, theSocket.dest.addr: 1}
0:2:11.378219727 DEBUG (2): 					nesC: Let's debug the debug and get this pan
0:2:11.378219727 DEBUG (2): 		Comparing Ack to Sequence number: tcp ack: 8935, tcp seq: 8935
0:2:11.378219727 DEBUG (2): 		ACK RECIEVED: ALLOWING NEXT PACKET TO BE SENT
0:2:11.378219727 DEBUG (2): Finished receiving command




*/
