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

0:1:43.061524647 DEBUG (3): A Command has been Issued.
0:1:43.061524647 DEBUG (3): Command Type: Client
0:1:43.061524647 DEBUG (3): CommandHandler.setTestServer(9) -- Initializing Server
0:1:43.061524647 DEBUG (3): 	Transport.socket() ->
0:1:43.061524647 DEBUG (3): 			   -> socket_t(1)
0:1:43.061524647 DEBUG (3): 	Transport.bind() ->
0:1:43.061524647 DEBUG (3): 			 -- fd: 1 port: 9 addr: 3
0:1:43.061524647 DEBUG (3): 			 -> Successful bind
0:1:43.061524647 DEBUG (3): 	Transport.listen() ->
0:1:43.061524647 DEBUG (3): 			   -- dest.port: 255 dest.addr: 255 state: 1
0:1:43.061524647 DEBUG (3): 			   -- Insert to sockets w/ fd: 1
0:1:43.061524647 DEBUG (3): 			   -> Successful listen
0:1:56.058594826 DEBUG (4): A Command has been Issued.
0:1:56.058594826 DEBUG (4): Command Type: Client
0:1:56.058594826 DEBUG (4): CommandHandler.setTestClient()
0:1:56.058594826 DEBUG (4): 	Transport.socket() ->
0:1:56.058594826 DEBUG (4): 			   -> socket_t(1)
0:1:56.058594826 DEBUG (4): 	Transport.bind() ->
0:1:56.058594826 DEBUG (4): 			 -- fd: 1 port: 12 addr: 4
0:1:56.058594826 DEBUG (4): 			 -> Successful bind
0:1:56.058594826 DEBUG (4): 	Transport.connect(1,3)  ->
0:1:56.058594826 DEBUG (4): 				-- newConnection [ port src: 12 dest: [ port: 9 addr: 3]]
0:1:56.058594826 DEBUG (4): 				-- MADE TCP_MSG LETS SEE IF THIS IS WHATS BREAKING
0:1:56.058594826 DEBUG (4): 				-- tcp_msg->destPort: 9 tcp_msg->srcPort: 12 tcp_msg->seq: 13396
0:1:56.058594826 DEBUG (4): 				-- tcp_msg->flag: 1 tcp_msg->numBytes: 0
0:1:56.058594826 DEBUG (4): 				-- Sending Syn Packet: Src->4, Dest-> 3, Seq->13396
0:1:56.058594826 DEBUG (4): 				-- Sending Syn Packet: TTL->18
0:1:56.058594826 DEBUG (4): 				-> Transport.send()
0:1:56.058594826 DEBUG (4): 				-- IP PACK LAYER
0:1:56.058594826 DEBUG (4): 					-- Sending Packet: Src->4, Dest-> 3, Seq->13396
0:1:56.058594826 DEBUG (4): 					-- Sending Packet: TTL->18
0:1:56.058594826 DEBUG (4): 				-- TCP PACK LAYER
0:1:56.058594826 DEBUG (4): 					-- Sending Packet: destPort->9, srcPort-> 12, Seq->13396
0:1:56.058594826 DEBUG (4): 					-- Sending Packet: ack->24942, numBytes->0
0:1:56.058594826 DEBUG (4): 				-- Reassigning Ports with  socket
0:1:56.058594826 DEBUG (4): 				-- Data->destPort: 9
0:1:56.058594826 DEBUG (4): 				-- Data->srcPort: 12
0:1:56.058594826 DEBUG (4): 				-- Data->advertisedWindow: 0, Data->ack: 0
0:1:56.058594826 DEBUG (4): Sent
0:1:56.058594826 DEBUG (4): 				-- Successful
0:1:56.058594826 DEBUG (4): 	-- Connection Secure.
0:2:12.358398847 DEBUG (3): ListenTimer.fired() {
0:2:12.358398847 DEBUG (3): 	 Transport.accept(1) ->
0:2:12.358398847 DEBUG (3): 			     -- sockets.contains(fd:  1): True
0:2:12.358398847 DEBUG (3): 			     -- | CLOSED = 0, LISTEN = 1, ESTABLISHED = 3, SYN_SENT  = 4, SYN_RCVD = 5 |
0:2:12.358398847 DEBUG (3): 			     -- localSocket.state: 1
0:2:12.358398847 DEBUG (3): 			     -- localSocket.state: 5 localSocket.dest.addr: 3
0:2:12.358398847 DEBUG (3): 			     -- returning fd: 1
0:2:12.358398847 DEBUG (3): 	-- Succesfully saved new fd: 1
0:2:12.358398847 DEBUG (3): 	-- Reading from buffer
0:2:12.358398847 DEBUG (3): 	Transport.read() ->
0:2:12.358398847 DEBUG (3): 			 -- sockets.contains(fd:  1): True
0:2:12.358398847 DEBUG (3): 			 -- Read space len: 0
0:2:12.358398847 DEBUG (3): 			 -- Min from len and buffer len -> len: 0
0:2:12.358398847 DEBUG (3): 			 -- Ready to be read len: 0
0:2:12.358398847 DEBUG (3): 			 -> len: 0
0:2:12.358398847 DEBUG (3): 	-- len: 0
0:2:25.355469293 DEBUG (4): 	 WriteTimer.fired() ->
0:2:25.355469293 DEBUG (4): 			    -- Socket is valid: True
0:2:25.355469293 DEBUG (4): 			    -- Begining to  make data not Implemented yet
0:2:48.064453698 DEBUG (4): A Command has been Issued.
0:2:48.064453698 DEBUG (4): Command Type: Close Connection
0:2:48.064453698 DEBUG (4): 				findSocket(12, 9, 3) ->
0:2:48.064453698 DEBUG (4): 				      -- Contained {theSocket.src: 12, theSocket.dest.port: 9, theSocket.dest.addr: 3}
0:2:48.064453698 DEBUG (4): 					nesC: Let's debug the debug and get this pan
0:2:48.064453698 DEBUG (4): Transport.Close
0:2:48.064453698 DEBUG (4): Here 1
Segmentation fault
root@2bca9a8ca11e:/home/cse160/Networks-Project# 


*/
