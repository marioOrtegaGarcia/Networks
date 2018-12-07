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


}
/*




0:2:11.285202301 DEBUG (1): 				-- Socket Data:
0:2:11.285202301 DEBUG (1): 				-- destPort: 49, destAddr: 2, srcPort: 41,
0:2:11.285202301 DEBUG (1): 				-- socket->srcPort: 41
0:2:11.285202301 DEBUG (1): 				-- Data->advertisedWindow: 0, Data->ack: 8935
0:2:11.285202301 DEBUG (1): Sent
0:2:11.285202301 DEBUG (1): 		ATTEMPTING TO CALL RECIEVECOMM, CHARDATA: 10
0:2:11.285202301 DEBUG (1): 18
0:2:11.285202301 DEBUG (1): Character: h int: 104
0:2:11.285202301 DEBUG (1): Character: e int: 101
0:2:11.285202301 DEBUG (1): Character: l int: 108
0:2:11.285202301 DEBUG (1): Character: l int: 108
0:2:11.285202301 DEBUG (1): Character: o int: 111
0:2:11.285202301 DEBUG (1): Character:   int: 32
0:2:11.285202301 DEBUG (1): Character: a int: 97
0:2:11.285202301 DEBUG (1): Character: s int: 115
0:2:11.285202301 DEBUG (1): Character: c int: 99
0:2:11.285202301 DEBUG (1): Character: e int: 101
0:2:11.285202301 DEBUG (1): Character: e int: 101
0:2:11.285202301 DEBUG (1): Character: r int: 114
0:2:11.285202301 DEBUG (1): Character: p int: 112
0:2:11.285202301 DEBUG (1): Character: a int: 97
0:2:11.285202301 DEBUG (1): Character:   int: 32
0:2:11.285202301 DEBUG (1): Character: 3 int: 51
0:2:11.318649403 DEBUG (2): Recieved a TCP Pack
0:2:11.318649403 DEBUG (2): 	Transport.receive() default flag ACK
0:2:11.318649403 DEBUG (2): 				findSocket(49, 41, 1) ->
0:2:11.318649403 DEBUG (2): 				      -- Contained {theSocket.src: 49, theSocket.dest.port: 41, theSocket.dest.addr: 1}
0:2:11.318649403 DEBUG (2): 					nesC: Let's debug the debug and get this pan
0:2:11.318649403 DEBUG (2): 		Comparing Ack to Sequence number: tcp ack: 8935, tcp seq: 8935
0:2:11.318649403 DEBUG (2): 		ACK RECIEVED: ALLOWING NEXT PACKET TO BE SENT
0:2:11.318649403 DEBUG (2): Finished receiving command



*/
