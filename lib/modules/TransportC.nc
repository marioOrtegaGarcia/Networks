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

0:1:56.069001192 DEBUG (4): 	Transport.connect(1,3)  ->
0:1:56.069001192 DEBUG (4): 				-- newConnection [ port src: 12 dest: [ port: 9 addr: 3]]
0:1:56.069001192 DEBUG (4): 				-- MADE TCP_MSG LETS SEE IF THIS IS WHATS BREAKING
0:1:56.069001192 DEBUG (4): 				-- tcp_msg->destPort: 9 tcp_msg->srcPort: 12 tcp_msg->seq: 13396
0:1:56.069001192 DEBUG (4): 				-- tcp_msg->flag: 1 tcp_msg->numBytes: 0
0:1:56.069001192 DEBUG (4): 				-- Sending Syn Packet: Src->4, Dest-> 3, Seq->13396
0:1:56.069001192 DEBUG (4): 				-- Sending Syn Packet: TTL->18
0:1:56.069001192 DEBUG (4): 				-> Transport.send()
0:1:56.069001192 DEBUG (4): 				-- IP PACK LAYER
0:1:56.069001192 DEBUG (4): 					-- Sending Packet: Src->4, Dest-> 3, Seq->13396
0:1:56.069001192 DEBUG (4): 					-- Sending Packet: TTL->18
0:1:56.069001192 DEBUG (4): 				-- TCP PACK LAYER
0:1:56.069001192 DEBUG (4): 					-- Sending Packet: destPort->9, srcPort-> 12, Seq->13396
0:1:56.069001192 DEBUG (4): 					-- Sending Packet: ack->24942, numBytes->0
0:1:56.069001192 DEBUG (4): 				-- Socket Data:
0:1:56.069001192 DEBUG (4): 				-- destPort: 9, destAddr: 3, srcPort: 12,
0:1:56.069001192 DEBUG (4): 				-- socket->srcPort: 12
0:1:56.069001192 DEBUG (4): 				-- Data->advertisedWindow: 0, Data->ack: 24942
0:1:56.069001192 DEBUG (4): Sent
0:1:56.069001192 DEBUG (4): 				-- Successful
0:1:56.069001192 DEBUG (4): 	-- Connection Secure.
0:1:56.162125164 DEBUG (3): Recieved a TCP Pack
0:1:56.162125164 DEBUG (3): 	Transport.receive: SYN TCP PACK Recieved with ttl: 17
0:1:56.162125164 DEBUG (3): 	Set flag to SYN+ACK
0:1:56.162125164 DEBUG (3): 				Finding Socket from Sockets Hashmap (we switched the src/dest and ports, if anything weird happens, check here)
0:1:56.162125164 DEBUG (3): 				From PACK::::: msg.dest: 4, msg.src: 3, msg.seq: 13397, msg.TTL: 18, msg.protocol: 4
0:1:56.162125164 DEBUG (3): 				findSocket(9, 255, 255) ->
0:1:56.162125164 DEBUG (3): 				      -- Contained {theSocket.src: 9, theSocket.dest.port: 255, theSocket.dest.addr: 255}
0:1:56.162125164 DEBUG (3): 					nesC: Let's debug the debug and get this pan
0:1:56.162125164 DEBUG (3): 				socket.src: 9 socket.dest.port: 12
0:1:56.162125164 DEBUG (3): 				-> Transport.send()
0:1:56.162125164 DEBUG (3): 				-- IP PACK LAYER
0:1:56.162125164 DEBUG (3): 					-- Sending Packet: Src->3, Dest-> 4, Seq->13397
0:1:56.162125164 DEBUG (3): 					-- Sending Packet: TTL->18
0:1:56.162125164 DEBUG (3): 				-- TCP PACK LAYER
0:1:56.162125164 DEBUG (3): 					-- Sending Packet: destPort->12, srcPort-> 9, Seq->13397
0:1:56.162125164 DEBUG (3): 					-- Sending Packet: ack->24942, numBytes->0
0:1:56.162125164 DEBUG (3): 				-- Socket Data:
0:1:56.162125164 DEBUG (3): 				-- destPort: 12, destAddr: 4, srcPort: 9,
0:1:56.162125164 DEBUG (3): 				-- socket->srcPort: 9
0:1:56.162125164 DEBUG (3): 				-- Data->advertisedWindow: 1, Data->ack: 24942
0:1:56.162125164 DEBUG (3): Sent
0:1:56.180313509 DEBUG (4): Recieved a TCP Pack
0:1:56.180313509 DEBUG (4): 	Transport.receive() default flag ACK
0:1:56.180313509 DEBUG (4): 		msg.dest: 3 recievedTcp->destPort: 9 msg.seq: 13397
0:1:56.180313509 DEBUG (4): 		 recievedTcp->srcPort: 12, msg.src: 4, recievedTcp->destPort: 9 msg.dest: 3
0:1:56.180313509 DEBUG (4): 				findSocket(12, 9, 3) ->
0:1:56.180313509 DEBUG (4): 				      -- Contained {theSocket.src: 12, theSocket.dest.port: 9, theSocket.dest.addr: 3}
0:1:56.180313509 DEBUG (4): 					nesC: Let's debug the debug and get this pan
0:1:56.180313509 DEBUG (4): 		Comparing Ack to Sequence number: tcp ack: 24942, tcp seq: 13397
0:2:12.344726972 DEBUG (3): ListenTimer.fired() {
0:2:12.344726972 DEBUG (3): 	 Transport.accept(1) ->
0:2:12.344726972 DEBUG (3): 			     -- sockets.contains(fd:  1): True
0:2:12.344726972 DEBUG (3): 			     -- | CLOSED = 0, LISTEN = 1, ESTABLISHED = 3, SYN_SENT  = 4, SYN_RCVD = 5 |
0:2:12.344726972 DEBUG (3): 			     -- localSocket.state: 5
0:2:12.344726972 DEBUG (3): 			     -- returning fd: NULL
0:2:12.344726972 DEBUG (3): 	-- fd is NULL
0:2:25.365234918 DEBUG (4): 	 WriteTimer.fired() ->
0:2:25.365234918 DEBUG (4): 			    -- Socket is valid: True
0:2:25.365234918 DEBUG (4): 			    -- Begining to  make data, sending 10 bytes
0:2:25.365234918 DEBUG (4): 			Begining Stop & Wait, Trasnfer: 10, data: 10
0:2:25.365234918 DEBUG (4): 				 TCP Seq: 13397
0:2:25.365234918 DEBUG (4): 				IP Seq Before: 1909
0:2:25.365234918 DEBUG (4): 			Sending num 0 to Node 3 over socket 9
0:2:25.559189352 DEBUG (3): Recieved a TCP Pack
0:2:25.559189352 DEBUG (3): 	Transport.receive() Data packet
0:2:25.559189352 DEBUG (3): 		recievedTcp->ack: 13398
0:2:25.559189352 DEBUG (3): 		msg.dest: 4 recievedTcp->destPort: 12 msg.seq: 1909, flag:
0:2:25.559189352 DEBUG (3): 		 recievedTcp->srcPort: 9, msg.src: 3, recievedTcp->destPort: 12 msg.dest: 4
0:2:25.559189352 DEBUG (3): 	Data:	0
0:2:25.559189352 DEBUG (3): 				findSocket(9, 12, 4) ->
0:2:25.559189352 DEBUG (3): 				      -- Contained {theSocket.src: 9, theSocket.dest.port: 12, theSocket.dest.addr: 4}
0:2:25.559189352 DEBUG (3): 					nesC: Let's debug the debug and get this pan
0:2:25.559189352 DEBUG (3): 				-> Transport.send()
0:2:25.559189352 DEBUG (3): 				-- IP PACK LAYER
0:2:25.559189352 DEBUG (3): 					-- Sending Packet: Src->3, Dest-> 4, Seq->1910
0:2:25.559189352 DEBUG (3): 					-- Sending Packet: TTL->17
0:2:25.559189352 DEBUG (3): 				-- TCP PACK LAYER
0:2:25.559189352 DEBUG (3): 					-- Sending Packet: destPort->12, srcPort-> 9, Seq->13397
0:2:25.559189352 DEBUG (3): 					-- Sending Packet: ack->13398, numBytes->1
0:2:25.559189352 DEBUG (3): 				-- Socket Data:
0:2:25.559189352 DEBUG (3): 				-- destPort: 12, destAddr: 4, srcPort: 9,
0:2:25.559189352 DEBUG (3): 				-- socket->srcPort: 9
0:2:25.559189352 DEBUG (3): 				-- Data->advertisedWindow: 0, Data->ack: 13398
0:2:25.559189352 DEBUG (3): Sent
0:2:25.705337891 DEBUG (4): Recieved a TCP Pack
0:2:25.705337891 DEBUG (4): 	Transport.receive() default flag ACK
0:2:25.705337891 DEBUG (4): 		msg.dest: 3 recievedTcp->destPort: 9 msg.seq: 1910
0:2:25.705337891 DEBUG (4): 		 recievedTcp->srcPort: 12, msg.src: 4, recievedTcp->destPort: 9 msg.dest: 3
0:2:25.705337891 DEBUG (4): 				findSocket(12, 9, 3) ->
0:2:25.705337891 DEBUG (4): 				      -- Contained {theSocket.src: 12, theSocket.dest.port: 9, theSocket.dest.addr: 3}
0:2:25.705337891 DEBUG (4): 					nesC: Let's debug the debug and get this pan
0:2:25.705337891 DEBUG (4): 		Comparing Ack to Sequence number: tcp ack: 13398, tcp seq: 13398
0:2:25.705337891 DEBUG (4): 		ACK RECIEVED: ALLOWING NEXT PACKET TO BE SENT
0:2:25.705337891 DEBUG (4): 			Begining Stop & Wait, Trasnfer: 10, data: 10
0:2:25.705337891 DEBUG (4): 				 TCP Seq: 13398
0:2:25.705337891 DEBUG (4): 				IP Seq Before: 1909
0:2:25.705337891 DEBUG (4): 			Sending num 1 to Node 3 over socket 9
0:2:25.773590594 DEBUG (3): Recieved a TCP Pack
0:2:25.773590594 DEBUG (3): 	Transport.receive() Data packet
0:2:25.773590594 DEBUG (3): 		recievedTcp->ack: 13399
0:2:25.773590594 DEBUG (3): 		msg.dest: 4 recievedTcp->destPort: 12 msg.seq: 1909, flag:
0:2:25.773590594 DEBUG (3): 		 recievedTcp->srcPort: 9, msg.src: 3, recievedTcp->destPort: 12 msg.dest: 4
0:2:25.773590594 DEBUG (3): 	Data:	1
0:2:25.773590594 DEBUG (3): 				findSocket(9, 12, 4) ->
0:2:25.773590594 DEBUG (3): 				      -- Contained {theSocket.src: 9, theSocket.dest.port: 12, theSocket.dest.addr: 4}
0:2:25.773590594 DEBUG (3): 					nesC: Let's debug the debug and get this pan
0:2:25.773590594 DEBUG (3): 				-> Transport.send()
0:2:25.773590594 DEBUG (3): 				-- IP PACK LAYER
0:2:25.773590594 DEBUG (3): 					-- Sending Packet: Src->3, Dest-> 4, Seq->1910
0:2:25.773590594 DEBUG (3): 					-- Sending Packet: TTL->17
0:2:25.773590594 DEBUG (3): 				-- TCP PACK LAYER
0:2:25.773590594 DEBUG (3): 					-- Sending Packet: destPort->12, srcPort-> 9, Seq->13398
0:2:25.773590594 DEBUG (3): 					-- Sending Packet: ack->13399, numBytes->1
0:2:25.773590594 DEBUG (3): 				-- Socket Data:
0:2:25.773590594 DEBUG (3): 				-- destPort: 12, destAddr: 4, srcPort: 9,
0:2:25.773590594 DEBUG (3): 				-- socket->srcPort: 9
0:2:25.773590594 DEBUG (3): 				-- Data->advertisedWindow: 0, Data->ack: 13399
0:2:25.773590594 DEBUG (3): Sent
0:2:25.801651370 DEBUG (4): Recieved a TCP Pack
0:2:25.801651370 DEBUG (4): 	Transport.receive() default flag ACK
0:2:25.801651370 DEBUG (4): 		msg.dest: 3 recievedTcp->destPort: 9 msg.seq: 1910
0:2:25.801651370 DEBUG (4): 		 recievedTcp->srcPort: 12, msg.src: 4, recievedTcp->destPort: 9 msg.dest: 3
0:2:25.801651370 DEBUG (4): 				findSocket(12, 9, 3) ->
0:2:25.801651370 DEBUG (4): 				      -- Contained {theSocket.src: 12, theSocket.dest.port: 9, theSocket.dest.addr: 3}
0:2:25.801651370 DEBUG (4): 					nesC: Let's debug the debug and get this pan
0:2:25.801651370 DEBUG (4): 		Comparing Ack to Sequence number: tcp ack: 13399, tcp seq: 13399
0:2:25.801651370 DEBUG (4): 		ACK RECIEVED: ALLOWING NEXT PACKET TO BE SENT
0:2:25.801651370 DEBUG (4): 			Begining Stop & Wait, Trasnfer: 10, data: 10
0:2:25.801651370 DEBUG (4): 				 TCP Seq: 13399
0:2:25.801651370 DEBUG (4): 				IP Seq Before: 1909
0:2:25.801651370 DEBUG (4): 			Sending num 2 to Node 3 over socket 9
0:2:31.660156793 DEBUG (4): 		Packet 13399 timed out! Resending...
0:2:31.684402997 DEBUG (3): Recieved a TCP Pack
0:2:31.684402997 DEBUG (3): 	Transport.receive() Data packet
0:2:31.684402997 DEBUG (3): 		recievedTcp->ack: 13400
0:2:31.684402997 DEBUG (3): 		msg.dest: 4 recievedTcp->destPort: 12 msg.seq: 1909, flag:
0:2:31.684402997 DEBUG (3): 		 recievedTcp->srcPort: 9, msg.src: 3, recievedTcp->destPort: 12 msg.dest: 4
0:2:31.684402997 DEBUG (3): 	Data:	2
0:2:31.684402997 DEBUG (3): 				findSocket(9, 12, 4) ->
0:2:31.684402997 DEBUG (3): 				      -- Contained {theSocket.src: 9, theSocket.dest.port: 12, theSocket.dest.addr: 4}
0:2:31.684402997 DEBUG (3): 					nesC: Let's debug the debug and get this pan
0:2:31.684402997 DEBUG (3): 				-> Transport.send()
0:2:31.684402997 DEBUG (3): 				-- IP PACK LAYER
0:2:31.684402997 DEBUG (3): 					-- Sending Packet: Src->3, Dest-> 4, Seq->1910
0:2:31.684402997 DEBUG (3): 					-- Sending Packet: TTL->17
0:2:31.684402997 DEBUG (3): 				-- TCP PACK LAYER
0:2:31.684402997 DEBUG (3): 					-- Sending Packet: destPort->12, srcPort-> 9, Seq->13399
0:2:31.684402997 DEBUG (3): 					-- Sending Packet: ack->13400, numBytes->1
0:2:31.684402997 DEBUG (3): 				-- Socket Data:
0:2:31.684402997 DEBUG (3): 				-- destPort: 12, destAddr: 4, srcPort: 9,
0:2:31.684402997 DEBUG (3): 				-- socket->srcPort: 9
0:2:31.684402997 DEBUG (3): 				-- Data->advertisedWindow: 0, Data->ack: 13400
0:2:31.684402997 DEBUG (3): Sent
0:2:47.652344866 DEBUG (4): A Command has been Issued.
0:2:47.652344866 DEBUG (4): Command Type: Close Connection
0:2:47.652344866 DEBUG (4): 				findSocket(12, 9, 3) ->
0:2:47.652344866 DEBUG (4): 				      -- Contained {theSocket.src: 12, theSocket.dest.port: 9, theSocket.dest.addr: 3}
0:2:47.652344866 DEBUG (4): 					nesC: Let's debug the debug and get this pan
0:2:47.652344866 DEBUG (4): Transport.Close
0:2:47.652344866 DEBUG (4): 		Setting TCP:	DestPort->9
0:2:47.652344866 DEBUG (4): 				srcPort->12
0:2:47.652344866 DEBUG (4): 				seq->2462
0:2:47.652344866 DEBUG (4): 				flag->8
0:2:47.652344866 DEBUG (4): 				numBytes->0
0:2:47.652344866 DEBUG (4): 		Setting IP:	dest->3
0:2:47.652344866 DEBUG (4): 				src->4
0:2:47.652344866 DEBUG (4): 				seq->2462
0:2:47.652344866 DEBUG (4): 				TTL->18
0:2:47.652344866 DEBUG (4): 				protocol->4
0:2:47.652344866 DEBUG (4): 		Copying TCP pack to IP payload
0:2:47.652344866 DEBUG (4): 		Sending RST Packet
0:2:47.652344866 DEBUG (4): 				-> Transport.send()
0:2:47.652344866 DEBUG (4): 				-- IP PACK LAYER
0:2:47.652344866 DEBUG (4): 					-- Sending Packet: Src->4, Dest-> 3, Seq->2462
0:2:47.652344866 DEBUG (4): 					-- Sending Packet: TTL->18
0:2:47.652344866 DEBUG (4): 				-- TCP PACK LAYER
0:2:47.652344866 DEBUG (4): 					-- Sending Packet: destPort->9, srcPort-> 12, Seq->13399
0:2:47.652344866 DEBUG (4): 					-- Sending Packet: ack->0, numBytes->0
0:2:47.652344866 DEBUG (4): 				-- Socket Data:
0:2:47.652344866 DEBUG (4): 				-- destPort: 9, destAddr: 3, srcPort: 12,
0:2:47.652344866 DEBUG (4): 				-- socket->srcPort: 12
0:2:47.652344866 DEBUG (4): 				-- Data->advertisedWindow: 0, Data->ack: 0
0:2:47.652344866 DEBUG (4): Sent
0:2:47.652344866 DEBUG (4): 		Success!
0:2:47.790543130 DEBUG (3): Recieved a TCP Pack
0:2:47.790543130 DEBUG (3): 	Transport.receive() default flag RST
0:2:47.790543130 DEBUG (3): 				findSocket(9, 12, 4) ->
0:2:47.790543130 DEBUG (3): 				      -- Contained {theSocket.src: 9, theSocket.dest.port: 12, theSocket.dest.addr: 4}
0:2:47.790543130 DEBUG (3): 					nesC: Let's debug the debug and get this pan
0:2:47.790543130 DEBUG (3): 		Successfully closed both ends of connection!


*/
