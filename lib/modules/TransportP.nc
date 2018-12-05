#include "../../includes/socket.h"
#include "../../includes/packet.h"
#include "../../includes/tcp_packet.h"
/**
 * The Transport interface handles sockets and is a layer of abstraction
 * above TCP. This will be used by the application layer to set up TCP
 * packets. Internally the system will be handling syn/ack/data/fin
 * Transport packets.
 *
 * @project
 *   Transmission Control Protocol
 * @author
 *      Alex Beltran - abeltran2@ucmerced.edu
 * @date
 *   2013/11/12
 */

module TransportP {
	provides interface Transport;
	uses interface Hashmap<socket_store_t> as sockets;
	uses interface Random as Random;
	uses interface SimpleSend as Sender;
	uses interface Timer<TMilli> as TimedOut;
	uses interface Timer<TMilli> as AckTimer;
}

implementation {
	pack sendMessage;
	uint16_t* IPseq = 0;
	uint16_t tcpSeq = 0;
	//tcp_packet* tcp_msg;
	uint16_t RTT = 12000;
	uint16_t fdKeys = 0;
	uint8_t numConnected = 0;
	uint8_t max_tcp_payload = 20;
	uint8_t transfer;
	uint8_t sentData = 0;
	bool send = TRUE;

	event void TimedOut.fired() {

		tcp_packet* payload;
		payload = (tcp_packet*)sendMessage.payload;

		dbg(GENERAL_CHANNEL, "\n\n\t\tPacket %u timed out! Resending...\n\n\n", tcpSeq);

		call Sender.send(sendMessage, sendMessage.dest);

		call TimedOut.startOneShot(12000);
	}
	event void AckTimer.fired() {
		tcp_packet* payload;
		payload = (tcp_packet*)sendMessage.payload;
		dbg(GENERAL_CHANNEL, "\n\n\t\tAck %u timed out! Resending...\n\n\n", payload->seq);
		call Sender.send(sendMessage, sendMessage.dest);
	}


	command void Transport.passSeq(uint16_t* seq) {
		IPseq = seq;
	}

	command void Transport.makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length) {
		tcp_packet* tcpp = (tcp_packet*) payload;

		Package->src = src;
		Package->dest = dest;
		Package->TTL = TTL;
		Package->seq = seq;
		//Package->protocol = protocol;

		//dbg(GENERAL_CHANNEL, "\t--payload Size: %u ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n", sizeof(payload));
		//dbg(GENERAL_CHANNEL, "TCP Pack Unwrap: %d", tcpp->destPort);

		dbg(GENERAL_CHANNEL,"\t\t\t\t~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~HERE at makePack ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
		memcpy(Package->payload, payload, TCP_MAX_PAYLOAD_SIZE);
	}

	command void Transport.makeTCPPack(tcp_packet* TCPheader, uint8_t destPort, uint8_t srcPort, uint16_t seq, uint16_t ack, uint8_t flag, uint8_t advertisedWindow, uint8_t numBytes, uint8_t* payload) {
		//uint8_t* data = payload;
		// We can set whole variable pointer, but cant read or set off of
		//dbg(GENERAL_CHANNEL, "\t\t\t\t %u \n", theTCPheader->destPort);
		/* TCPheader->payload = malloc(sizeof(&payload)); */
		TCPheader->destPort = destPort;
		TCPheader->srcPort = srcPort;
		TCPheader->seq = seq;
		TCPheader->ack = ack;
		TCPheader->flag = flag;
		TCPheader->advertisedWindow = advertisedWindow;
		//TCPheader->numBytes = numBytes;
		dbg(GENERAL_CHANNEL, "\t\t\t\tSize of TCPheader->payload: %u, payload: %u, numBytes: %u\n", sizeof(TCPheader->payload), sizeof(payload), numBytes);
		/* TCPheader->payload = malloc(numBytes); */

		dbg(GENERAL_CHANNEL, "\t\t\t\t~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~HERE at makeTCPPack ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
	 	memcpy(TCPheader->payload, payload, sizeof(payload));
	}

	// Method used to make SYN to only initiate the required variables
	command tcp_packet* Transport.makeSynPack(tcp_packet* TCPheader, uint8_t destPort, uint8_t srcPort, uint16_t seq) {
		TCPheader->destPort = destPort;
		TCPheader->srcPort = srcPort;
		TCPheader->seq = seq;
		TCPheader->flag = SYN;
		dbg(GENERAL_CHANNEL, "\t\t\tmakeSynPack complete with values destPort: %d srcPort: %d seq: %d\n", TCPheader->destPort, TCPheader->srcPort, TCPheader->seq);
		return TCPheader;
	}

	// Method used to make ACK to reply too SYN
	command void Transport.makeAckPack(tcp_packet* TCPheader, uint8_t destPort, uint8_t srcPort, uint16_t seq, uint8_t flag, uint8_t advertisedWindow) {
		TCPheader->destPort = destPort;
		TCPheader->srcPort = srcPort;
		TCPheader->seq = seq;
		TCPheader->flag = flag;
		TCPheader->advertisedWindow = advertisedWindow;
	}


	command socket_store_t Transport.getSocket(socket_t fd) {
		/* if(call sockets.contains(fd))
			return (call sockets.get(fd));
		else
			return (socket_store_t) NULL; */
			return call sockets.get(fd);
	}

	command socket_t Transport.findSocket(uint8_t destAddr, uint8_t srcPort, uint8_t destPort) {
		socket_store_t theSocket;
		uint8_t i;
		uint8_t fd = 1;
		dbg(GENERAL_CHANNEL, "\t\t\t\tfindSocket(%u, %u, %u) ->\n", destAddr, srcPort, destPort);
		for (i = 1; i < 11; i++) {
			if(call sockets.contains(i)){
				theSocket = call sockets.get(i);
				dbg(GENERAL_CHANNEL, "\t\t\t\t      -- Contained {theSocket.src: %u, theSocket.dest.port: %u, theSocket.dest.addr: %u}\n", theSocket.src, theSocket.dest.port, theSocket.dest.addr);
				//dbg(GENERAL_CHANNEL, "\t\t\t\tParameter destAddr: %u Contained theSocket.src: %u \n", destAddr, theSocket.src);
				//dbg(GENERAL_CHANNEL, "\t\t\t\ttheSocket.dest.addr: %u, theSocket.dest.port: %u\n", theSocket.dest.addr, theSocket.dest.port);
				//dbg(GENERAL_CHANNEL, "\t\t\t\tsrcPort: %u, destPort: %u\n", srcPort, destPort);

				//if(theSocket.src == dest && theSocket.dest.port == srcPort && theSocket.dest.addr == dest) {

				if(theSocket.src == destAddr && theSocket.dest.port == srcPort && theSocket.dest.addr == destPort) {
					dbg(GENERAL_CHANNEL, "\t\t\t\t\tnesC: Let's debug the debug and get this pan\n");
					//dbg(GENERAL_CHANNEL, "Hey we found socket with  fd: %u theSocket.src: %u theSocket.dest.port: %u theSocket.dest.addr: %u\n", i, theSocket.src, theSocket.dest.port, theSocket.dest.addr);

					return (socket_t)i;
				} else {
					dbg(GENERAL_CHANNEL, "\t\t\t\t\tnesC be Tripping\n");
				}
			}
		}
	}

	command bool Transport.isValidSocket(socket_t fd){
		if(call sockets.contains(fd))
			return TRUE;
		return FALSE;
	}

	// Computing the Calculated Window based off the advertised Window minuts the things we've already sent and know they have received
	command uint8_t Transport.calcWindow(socket_store_t* sock, uint16_t advertisedWindow) {
		return advertisedWindow - (sock->lastSent - sock->lastAck - 1);
	}

	command pack Transport.send(socket_store_t * s, pack IPpack) {
		// Making a tcp_packet pointer for the payload of IP Pack
		tcp_packet* data;
		data = (tcp_packet*)IPpack.payload;
		dbg(GENERAL_CHANNEL, "\t\t\t\t-> Transport.send()\n");


		dbg(GENERAL_CHANNEL, "\t\t\t\t-- IP PACK LAYER\n");
		dbg(GENERAL_CHANNEL, "\t\t\t\t\t-- Sending Packet: Src->%d, Dest-> %d, Seq->%d\n", IPpack.src, IPpack.dest, IPpack.seq);
		dbg(GENERAL_CHANNEL, "\t\t\t\t\t-- Sending Packet: TTL->%d\n", IPpack.TTL);
		dbg(GENERAL_CHANNEL, "\t\t\t\t-- TCP PACK LAYER\n");
		dbg(GENERAL_CHANNEL, "\t\t\t\t\t-- Sending Packet: destPort->%d, srcPort-> %d, Seq->%d\n", data->destPort, data->srcPort, data->seq);
		dbg(GENERAL_CHANNEL, "\t\t\t\t\t-- Sending Packet: ack->%d, numBytes->%d\n", data->ack, data->numBytes);
		call Sender.send(IPpack, s->dest.addr);
		//s->lastSent = data->seq;
		//dbg(GENERAL_CHANNEL, "\t\t\t\t-- Socket->lastSent: %u\n", s->lastSent);
		//dbg(GENERAL_CHANNEL, "Setting the src: %u and dest Ports: %u from our socket_store_t\n", s->src, s->dest.port);
		dbg(GENERAL_CHANNEL, "\t\t\t\t-- Socket Data:\n");
		//data->destPort = s->dest.port;
		dbg(GENERAL_CHANNEL, "\t\t\t\t-- destPort: %u, destAddr: %u, srcPort: %u, \n", s->dest.port, s->dest.addr, s->src);
		//data->srcPort = s->src;
		dbg(GENERAL_CHANNEL, "\t\t\t\t-- socket->srcPort: %u\n", data->srcPort);


		//dbg(GENERAL_CHANNEL, "\t\t\t\t-- Segfault B4 calcWindow()\n");

		// Computing aw and increasing the ACK
		//data->advertisedWindow = call Transport.calcWindow(s, data->advertisedWindow);
		//data->ack = s->nextExpected;
		dbg(GENERAL_CHANNEL, "\t\t\t\t-- Data->advertisedWindow: %u, Data->ack: %u\n", data->advertisedWindow, data->ack);
		//call Transport.makeTCPPack(data, data->destPort, data->srcPort, data->seq, data->ack, data->flag, data->advertisedWindow, data->numBytes, (void*)data->payload);
		//call Transport.makePack(&IPpack, IPpack->src, IPpack->dest, IPpack->TTL, IPpack->protocol, IPpack->seq, (void*) data, sizeof(data));

		// Sending the IP packet to the destPort

		dbg(GENERAL_CHANNEL, "Sent\n");


		return IPpack;
	}


	command void Transport.stopWait(socket_store_t sock, uint8_t data, uint16_t IPseqnum) {

		pack msg;
		tcp_packet tcp;
		transfer = data;

		dbg(GENERAL_CHANNEL, "\t\t\tBegining Stop & Wait, Trasnfer: %u, data: %u\n", transfer, data);
		if(send == TRUE && sentData < transfer){
			//make tcp_packet
			tcpSeq = tcpSeq + 1;
			tcp.destPort = sock.dest.port;
			tcp.srcPort = sock.src;
			dbg(GENERAL_CHANNEL, "\t\t\t\t TCP Seq: %u\n", tcpSeq);
			tcp.seq = tcpSeq;
			tcp.flag = 10;
			tcp.numBytes = sizeof(sentData);
			memcpy(tcp.payload, &sentData, TCP_MAX_PAYLOAD_SIZE);

			sendMessage.dest = sock.dest.addr;
			//dbg(GENERAL_CHANNEL, "\t\t\t\tsrc->%u\n", TOS_NODE_ID);
			sendMessage.src = TOS_NODE_ID;
			//dbg(GENERAL_CHANNEL, "\t\t\t\tseq->%u\n", IPseqnum+1);
			dbg(GENERAL_CHANNEL, "\t\t\t\tIP Seq Before: %u\n", IPseqnum);
			sendMessage.seq = IPseqnum;
			if(IPseq == 0)
				IPseq = IPseqnum;

			//dbg(GENERAL_CHANNEL, "\t\t\t\tTTL->18\n");
			sendMessage.TTL = 18;
			//dbg(GENERAL_CHANNEL, "\t\t\t\tprotocol->%u\n",PROTOCOL_TCP);
			sendMessage.protocol = PROTOCOL_TCP;
			//dbg(GENERAL_CHANNEL, "\t\tCopying TCP pack to IP payload\n");
			memcpy(sendMessage.payload, &tcp, TCP_MAX_PAYLOAD_SIZE);
			dbg(GENERAL_CHANNEL, "\t\t\tSending num %u to Node %u over socket %u\n", sentData, sock.dest.addr, sock.dest.port);
			//call Transport.send(&sock, msg);
			call Sender.send(sendMessage, sock.dest.addr);

			send = FALSE;
			sentData++;
			if(sentData != transfer)
				call TimedOut.startOneShot(6000);
		}
	}
	/* event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {

		pack* receivedMsg = (pack*) payload;
		//Sending all the PROTOCOL_TCP's to the Transport.receive function

		//dbg(GENERAL_CHANNEL, "\t\t\t -- Receive.receive() :: Size of Pack = %d\n", sizeof(receivedMsg)); //Size  is 8

		if (sizeof(receivedMsg) == 8) {
			// dbg(GENERAL_CHANNEL, "\t\t\t --  PASSED: Length  check\n");
			if (receivedMsg->protocol == PROTOCOL_TCP)
				dbg(GENERAL_CHANNEL, "\t\t\t -- PROTOCOL_TCP\n");
				call Transport.receive(receivedMsg);
		} else {
			//dbg(GENERAL_CHANNEL, "\t\t\t -- %d\n", len);  28
			//dbg(GENERAL_CHANNEL, "\t\t\n");
		}

	} */
	/**
 	* Get a socket if there is one available.
 	* @Side Client/Server
 	* @return
 	*    socket_t - return a socket file descriptor which is a number
 	*    associated with a socket. If you are unable to allocated
 	*    a socket then return a NULL socket_t.
 	*/
	 command socket_t Transport.socket() {
		int i;
		socket_store_t newSocket;
		dbg(GENERAL_CHANNEL, "\tTransport.socket() ->\n");
		// Generate new Key
		fdKeys++;
		if(fdKeys < 10) {
			newSocket.state = CLOSED;
			newSocket.lastWritten = 0;
			/* newSocket.lastAck = 0xFF; */
			newSocket.lastAck = 255;
			newSocket.lastSent = 0;
			newSocket.lastRead = 0;
			newSocket.lastRcvd = 0;
			newSocket.nextExpected = 0;
			newSocket.RTT = RTT;
			call sockets.insert(fdKeys, newSocket);
			dbg (GENERAL_CHANNEL, "\t\t\t   -> socket_t(%d)\n", fdKeys);
			return (socket_t)fdKeys;
		} else {
		// If we already looped though all 10 keys look for unused file descriptor
			for(i = 0; i < 10; i++)
				if(!call sockets.contains(i))
					return (socket_t)i;
		}
		return (socket_t)NULL;
	}

	/**
 	* Bind a socket with an address.
 	* @param
 	*    socket_t fd: file descriptor that is associated with the socket
 	*       you are binding.
 	* @param
 	*    socket_addr_t *addr: the source port and source address that
 	*       you are biding to the socket, fd.
 	* @Side Client/Server
 	* @return error_t - SUCCESS if you were able to bind this socket, FAIL
 	*       if you were unable to bind.
 	*/
	command error_t Transport.bind(socket_t fd, socket_addr_t *addr) {
		socket_store_t refSocket;
		dbg(GENERAL_CHANNEL, "\tTransport.bind() ->\n");
		// Making sure we contin  the file descriptor
		if(call sockets.contains(fd)) {
			refSocket = call sockets.get(fd);
			call sockets.remove(fd);


			/* dbg(GENERAL_CHANNEL, "\taddr->port: %u\n", addr->port);
			dbg(GENERAL_CHANNEL, "\taddr->addr: %u\n", addr->addr); */

			// Binding the file  descriptor with the source port address
			//refSocket.state = CLOSED;

			refSocket.dest.port = ROOT_SOCKET_PORT;
			refSocket.dest.addr = ROOT_SOCKET_ADDR;
			refSocket.src = addr->port;
			dbg(GENERAL_CHANNEL, "\t\t\t -- fd: %u port: %u addr: %u\n", fd, addr->port, addr->addr);

			// Adding the Socket  back  to our hashtable
			call sockets.insert(fd, refSocket);
			dbg(GENERAL_CHANNEL, "\t\t\t -> Successful bind\n");
			return SUCCESS;
		}
		dbg(GENERAL_CHANNEL, "\t\t\t -- Failed bind\n");
		return FAIL;
	}

	/**
 	* Checks to see if there are socket connections to connect to and
 	* if there is one, connect to it.
 	* @param
 	*    socket_t fd: file descriptor that is associated with the socket
 	*       that is attempting an accept. remember, only do on listen.
 	* @side Server
 	* @return socket_t - returns a new socket if the connection is
 	*    accepted. this socket is a copy of the server socket but with
 	*    a destination associated with the destination address and port.
 	*    if not return a null socket.
 	*/
	command socket_t Transport.accept(socket_t fd) {
		socket_store_t localSocket;
		dbg(GENERAL_CHANNEL, "\t Transport.accept(%d) ->\n", fd);
		// Failing  if the filedescripter is not contained
		if (!call sockets.contains(fd)) {
			dbg(GENERAL_CHANNEL, "\t\t\t     -- sockets.contains(fd:  %d): False\n", fd);
			return (socket_t)NULL;
		} else {
			dbg(GENERAL_CHANNEL, "\t\t\t     -- sockets.contains(fd:  %d): True\n", fd);
		}

		localSocket = call sockets.get(fd);
		dbg(GENERAL_CHANNEL, "\t\t\t     -- | CLOSED = 0, LISTEN = 1, ESTABLISHED = 3, SYN_SENT  = 4, SYN_RCVD = 5 |\n");
		dbg(GENERAL_CHANNEL, "\t\t\t     -- localSocket.state: %u\n", localSocket.state);

		// If were on a litening state and we have less than 10 sockets used
		if (localSocket.state == LISTEN && numConnected < 10) {

			// Keeping track of used sockets and my destination address, udating state
			numConnected++;
			localSocket.dest.addr = TOS_NODE_ID;
			localSocket.state = SYN_RCVD;

			dbg (GENERAL_CHANNEL, "\t\t\t     -- localSocket.state: %d localSocket.dest.addr: %d \n", localSocket.state, localSocket.dest.addr);

			// Clearing old and  inserting the modified socket back
			call sockets.remove(fd);
			call sockets.insert(fd, localSocket);
			dbg(GENERAL_CHANNEL, "\t\t\t     -- returning fd: %d\n", fd);
			return fd;
		}
		dbg(GENERAL_CHANNEL, "\t\t\t     -- returning fd: NULL\n");
		return (socket_t)NULL;
	}

	/**
 	* Write to the socket from a buffer. This data will eventually be
 	* transmitted through your TCP implimentation.
 	* @param
 	*    socket_t fd: file descriptor that is associated with the socket
 	*       that is attempting a write.
 	* @param
 	*    uint8_t *buff: the buffer data that you are going to wrte from.
 	* @param
 	*    uint16_t bufflen: The amount of data that you are trying to
 	*       submit.
 	* @Side For your project, only client side. This could be both though.
 	* @return uint16_t - return the amount of data you are able to write
 	*    from the pass buffer. This may be shorter then bufflen
 	*/
	command uint16_t Transport.write(socket_t fd, uint8_t *buff, uint16_t bufflen){
		uint8_t i;
		uint16_t freeSpace, position;
		socket_store_t socket;

		dbg(GENERAL_CHANNEL, "\tTransport.write() -- beginning to write to socket\n");

		if(call sockets.contains(fd))
			socket = call sockets.get(fd);
		// Amount of data we can write, (bufferlength or write length which ever is less)
		if(socket.lastWritten == socket.lastAck)
			freeSpace = SOCKET_BUFFER_SIZE - 1;
	 	else if(socket.lastWritten > socket.lastAck)
			freeSpace = SOCKET_BUFFER_SIZE - (socket.lastWritten - socket.lastAck) - 1;
		else if(socket.lastWritten < socket.lastAck)
			freeSpace = socket.lastAck - socket.lastWritten - 1;

		if(freeSpace > bufflen)
			bufflen = freeSpace;

		if (bufflen == 0) {
			dbg(GENERAL_CHANNEL, "\tTransport.write() -- Buffer Full\n");
			return 0;
		}

		// Writing to the sendBuff array
		for(i = 0; i < freeSpace; i++) {
			position = (socket.lastWritten + i + 1) % SOCKET_BUFFER_SIZE;
			socket.sendBuff[position] = buff[i];
		}

		// Updating the last written position
		socket.lastWritten += position;
	}

	/**
 	* This will pass the packet so you can handle it internally.
 	* @param
 	*    pack *package: the TCP packet that you are handling.
 	* @Side Client/Server
 	* @return uint16_t - return SUCCESS if you are able to handle this
 	*    packet or FAIL if there are errors.
 	*/
	command error_t Transport.receive(pack* package){
		pack msg;
		uint8_t temp;
		socket_t fd;
		tcp_packet* recievedTcp;
		socket_store_t socket;
		error_t check = FAIL;
		uint16_t tempSeq;

		// Setting our pack and tcp_packet types
		// Why are we setting msg as a pointer????????
		sendMessage = *package;
		recievedTcp = (tcp_packet*)package->payload;

		sendMessage.TTL--;

		// Using switch cases for every flag enum we use
		switch(recievedTcp->flag) {
			case 1://syn
				dbg(GENERAL_CHANNEL, "\tTransport.receive: SYN TCP PACK Recieved with ttl: %u\n", sendMessage.TTL);

				//reply with SYN + ACK
				recievedTcp->flag = ACK;

				dbg(GENERAL_CHANNEL, "\tSet flag to SYN+ACK\n");
				//makeTCPPack
				//dbg(GENERAL_CHANNEL, "\t\t\t\t -> Making TCP Pack\n");


				recievedTcp->seq++;
				recievedTcp->advertisedWindow = 1;

				temp = recievedTcp->destPort;
				recievedTcp->destPort = recievedTcp->srcPort;
				recievedTcp->srcPort = temp;

				//call Transport.makeAckPack(recievedTcp, recievedTcp->destPort, recievedTcp->srcPort, recievedTcp->seq+1, recievedTcp->flag, 10 /*advertisedWindow*/);

				//makePack and Set TCP PAck as payload for msg
				//dbg(GENERAL_CHANNEL, "\t\t\t\t -> Making IP Pack\n");
				temp = sendMessage.dest;
				sendMessage.dest = sendMessage.src;
				sendMessage.src = temp;
				sendMessage.seq++;
				sendMessage.TTL = (uint8_t)18;
				sendMessage.protocol = PROTOCOL_TCP;
				//dbg(GENERAL_CHANNEL, "\t\t\t -- DBG BEFORE MEMCPY\n");
				memcpy(sendMessage.payload, recievedTcp, TCP_MAX_PAYLOAD_SIZE);
				//dbg(GENERAL_CHANNEL, "\t\t\t -- DBG AFTER MEMCPY\n");
				//call Transport.makePack(&msg, msg.dest, msg.src, msg.seq, 18 /*TTL*/, msg.protocol, (uint8_t*)recievedTcp, sizeof(recievedTcp));

				//send pack
				dbg(GENERAL_CHANNEL, "\t\t\t\tFinding Socket from Sockets Hashmap (we switched the src/dest and ports, if anything weird happens, check here)\n");

				dbg(GENERAL_CHANNEL, "\t\t\t\tFrom PACK::::: sendMessage.dest: %u, sendMessage.src: %u, sendMessage.seq: %u, sendMessage.TTL: %u, msg.protocol: %u\n", sendMessage.dest, sendMessage.src, sendMessage.seq, sendMessage.TTL, sendMessage.protocol);
				fd = call Transport.findSocket(recievedTcp->srcPort, ROOT_SOCKET_PORT, ROOT_SOCKET_PORT);
				socket = call sockets.get(fd);

				socket.dest.port = recievedTcp->destPort;
				socket.dest.addr = sendMessage.dest;
				socket.state = SYN_RCVD;

				call sockets.remove(fd);
				call sockets.insert(fd, socket);
				dbg(GENERAL_CHANNEL, "\t\t\t\tsocket.src: %u socket.dest.port: %u\n",  socket.src, socket.dest.port);
				call Transport.send(&socket, sendMessage);
				return SUCCESS;
				break;

			case 2:	//ACK
				dbg(GENERAL_CHANNEL, "\tTransport.receive() default flag ACK\n");
				//Start Sending to the Sever

				//swap
				temp = recievedTcp->destPort;
				recievedTcp->destPort = recievedTcp->srcPort;
				recievedTcp->srcPort = temp;

				//swap
				temp = sendMessage.dest;
				sendMessage.dest = sendMessage.src;
				sendMessage.src = temp;


				dbg(GENERAL_CHANNEL, "\t\tsendMessage.dest: %u recievedTcp->destPort: %u sendMessage.seq: %u\n", sendMessage.dest, recievedTcp->destPort,  sendMessage.seq);
				dbg(GENERAL_CHANNEL, "\t\t recievedTcp->srcPort: %u, msg.src: %u, recievedTcp->destPort: %u sendMessage.dest: %u\n",recievedTcp->srcPort, sendMessage.src, recievedTcp->destPort, sendMessage.dest);

				fd = call Transport.findSocket(recievedTcp->srcPort, recievedTcp->destPort, sendMessage.dest);

				socket = call sockets.get(fd);

				//socket.lastAck = recievedTcp->ack;
				socket.state = ESTABLISHED;
				dbg(GENERAL_CHANNEL, "\t\tComparing Ack to Sequence number: tcp ack: %u, tcp seq: %u\n", recievedTcp->ack, tcpSeq+1);
				if(recievedTcp->ack == tcpSeq+1){
					send = TRUE;
					//tempSeq = IPseq;
					dbg(GENERAL_CHANNEL, "\t\tACK RECIEVED: ALLOWING NEXT PACKET TO BE SENT\n");
					call Transport.stopWait(socket, transfer, IPseq++);
				}

				call sockets.remove(fd);
				call sockets.insert(fd, socket);
				//Set view advertisedWindow
				return SUCCESS;
				break;

			case 4: // Fin f
				dbg(GENERAL_CHANNEL, "\tTransport.receive() default flag FIN\n");
				return SUCCESS;

				break;

			case 8: // RST
				dbg(GENERAL_CHANNEL, "\tTransport.receive() default flag RST\n");
				fd = call Transport.findSocket(recievedTcp->destPort, recievedTcp->srcPort, sendMessage.src);

				socket = call sockets.get(fd);



				call sockets.remove(fd);
				dbg(GENERAL_CHANNEL, "\t\tSuccessfully closed both ends of connection!\n");
				return SUCCESS;

				break;

			case 10:
				dbg(GENERAL_CHANNEL, "\tTransport.receive() Data packet\n");
				//Start Sending to the Sever

				//swap
				temp = recievedTcp->destPort;
				recievedTcp->destPort = recievedTcp->srcPort;
				recievedTcp->srcPort = temp;
				recievedTcp->flag = 2;
				recievedTcp->ack = recievedTcp->seq+1;

				//swap
				temp = sendMessage.dest;
				sendMessage.dest = sendMessage.src;
				sendMessage.src = temp;

				//dbg(GENERAL_CHANNEL, "\tTransport.receive() Data packet\n");
				dbg(GENERAL_CHANNEL, "\t\trecievedTcp->ack: %u\n", recievedTcp->ack);
				dbg(GENERAL_CHANNEL, "\t\tsendMessage.dest: %u recievedTcp->destPort: %u sendMessage.seq: %u, flag: \n", sendMessage.dest, recievedTcp->destPort,  sendMessage.seq, recievedTcp->flag);
				dbg(GENERAL_CHANNEL, "\t\t recievedTcp->srcPort: %u, sendMessage.src: %u, recievedTcp->destPort: %u sendMessage.dest: %u\n",recievedTcp->srcPort, sendMessage.src, recievedTcp->destPort, sendMessage.dest);

				dbg(GENERAL_CHANNEL, "\tData:\t%u\n", *recievedTcp->payload);
				fd = call Transport.findSocket(recievedTcp->srcPort, recievedTcp->destPort, sendMessage.dest);

				memcpy(sendMessage.payload, (void*)recievedTcp, TCP_MAX_PAYLOAD_SIZE);

				//socket.nextExpected = recievedTcp->seq+1;

				socket = call sockets.get(fd);

				++(sendMessage.seq);
				call Transport.send(&socket, sendMessage);
				if(sentData != transfer)
					call AckTimer.startOneShot(12000);
				return SUCCESS;
				break;

			default:
				dbg(GENERAL_CHANNEL, "\tTransport.receive() default flag ACK\n");
				return FAIL;
		}

		return check;
	}

	/**
 	* Read from the socket and write this data to the buffer. This data
 	* is obtained from your TCP implimentation.
 	* @param
 	*    socket_t fd: file descriptor that is associated with the socket
 	*       that is attempting a read.
 	* @param
 	*    uint8_t *buff: the buffer that is being written.
 	* @param
 	*    uint16_t bufflen: the amount of data that can be written to the
 	*       buffer.
 	* @Side For your project, only server side. This could be both though.
 	* @return uint16_t - return the amount of data you are able to read
 	*    from the pass buffer. This may be shorter then bufflen
 	*/
	command uint16_t Transport.read(socket_t fd, uint8_t *buff, uint16_t bufflen){
		uint16_t i, pos, len;
		socket_store_t socket;

		dbg(GENERAL_CHANNEL, "\tTransport.read() ->\n");
		/* if(call sockets.contains(fd))
			socket = call sockets.get(fd);
		else
			return 0; */

		if (!call sockets.contains(fd)) {
			dbg(GENERAL_CHANNEL, "\t\t\t -- sockets.contains(fd:  %d): False\n", fd);
			return 0;
		} else {

			dbg(GENERAL_CHANNEL, "\t\t\t -- sockets.contains(fd:  %d): True\n", fd);
			socket = call sockets.get(fd);
		}



		//calulate read space in buffer
	 	if(socket.lastRcvd >= socket.lastRead)
			len = socket.lastRcvd - socket.lastRead;
		else if(socket.lastRcvd < socket.lastRead)
			len = SOCKET_BUFFER_SIZE - socket.lastRead + socket.lastRcvd;

		dbg(GENERAL_CHANNEL, "\t\t\t -- Read space len: %d\n", len);
		//minimum value between length and buffer length
		if (len > bufflen)
			len = bufflen;
		dbg(GENERAL_CHANNEL, "\t\t\t -- Min from len and buffer len -> len: %d\n", len);
		//calculate space in buffer ready to be read up to first gap
		if (socket.nextExpected <= socket.lastRcvd+1)
			len = socket.nextExpected - socket.lastRead;
		dbg(GENERAL_CHANNEL, "\t\t\t -- Ready to be read len: %d\n", len);
		for (i = 0; i < len; i++) {
			pos = (socket.lastRead + i) % SOCKET_BUFFER_SIZE;
			buff[i] =  socket.rcvdBuff[pos];
		}

		socket.lastRead += len;

		call sockets.insert(fd, socket);
		dbg(GENERAL_CHANNEL, "\t\t\t -> len: %d\n", len);
		return len;
	}

	/**
 	* Attempts a connection to an address.
 	* @param
 	*    socket_t fd: file descriptor that is associated with the socket
 	*       that you are attempting a connection with.
 	* @param
 	*    socket_addr_t *addr: the destination address and port where
 	*       you will atempt a connection.
 	* @side Client
 	* @return socket_t - returns SUCCESS if you are able to attempt
 	*    a connection with the fd passed, else return FAIL.
 	*/
	command error_t Transport.connect(socket_t fd, socket_addr_t * addr) {
		socket_store_t newConnection;
		uint16_t seq;
		pack msg;
		uint8_t ttl;
		tcp_packet* tcp_msg;
		uint8_t* payload = 0;
		ttl = 18;

		dbg(GENERAL_CHANNEL, "\tTransport.connect(%u,%d)  ->\n", fd, addr->addr);
		//if FD exists, get socket and set destination address to provided input addr
		if (call sockets.contains(fd)) {
			newConnection = call sockets.get(fd);
			call sockets.remove(fd);

			// Set connec both ports
			//dbg(GENERAL_CHANNEL, "\t\t\t\t\t-- Port(%u)->Port(%u) w/ address(%u)\n", newConnection.src, addr->port, addr->addr);
			// Set destination address
			newConnection.dest = *addr;

			//send SYN packet
			dbg(GENERAL_CHANNEL, "\t\t\t\t-- newConnection [ port src: %d dest: [ port: %d addr: %d]]\n", newConnection.src, newConnection.dest.port, newConnection.dest.addr);
			seq = call Random.rand16() % 33000;
			tcpSeq = seq;

			dbg(GENERAL_CHANNEL, "\t\t\t\t-- MADE TCP_MSG LETS SEE IF THIS IS WHATS BREAKING \n");

			//dbg(GENERAL_CHANNEL, "\t\t\t\t\t ~~ Debug before makeSynPack\n");
			tcp_msg->destPort = newConnection.dest.port;
			tcp_msg->srcPort = newConnection.src;
			tcp_msg->seq = seq;
			tcp_msg->flag = SYN;
			tcp_msg->numBytes = 0;

			dbg(GENERAL_CHANNEL, "\t\t\t\t-- tcp_msg->destPort: %u tcp_msg->srcPort: %u tcp_msg->seq: %u\n", tcp_msg->destPort, tcp_msg->srcPort, tcp_msg->seq);

			dbg(GENERAL_CHANNEL, "\t\t\t\t-- tcp_msg->flag: %u tcp_msg->numBytes: %u\n", tcp_msg->flag, tcp_msg->numBytes);

			/* tcp_packet* test = call Transport.makeSynPack(&tcp_msg, newConnection.dest.port, newConnection.src, seq); */

			//dbg(GENERAL_CHANNEL, "\t\t\t\t~~ Debug before makePack\n");
			//dbg(GENERAL_CHANNEL, "tcp_msg->destPort: %d  ############################\n", tcp_msg->destPort);
			//dbg(GENERAL_CHANNEL, "\t\t\t\t\t ~~ Debug after makePack, this runs an Error in Transport.connect()#########\n");

			msg.dest = newConnection.dest.addr;
			msg.src = TOS_NODE_ID;
			msg.seq = seq;
			msg.TTL = ttl;
			msg.protocol = PROTOCOL_TCP;
			memcpy(msg.payload, (void*)tcp_msg, TCP_MAX_PAYLOAD_SIZE);
			//dbg(GENERAL_CHANNEL, "TTL: %u\n", msg.TTL);




			/*
			call Transport.makePack(&msg,
						(uint16_t)TOS_NODE_ID,
						(uint16_t)newConnection.src,
						(uint16_t)19,
						PROTOCOL_TCP,
						(uint16_t)1,
						(void*)tcp_msg,
						(uint8_t)sizeof(tcp_msg));
			*/
			/* We need to actually call send() once make Pack ends up workng */
			newConnection.state = SYN_SENT;
			//dbg(GENERAL_CHANNEL, "\t\t\t\t-> I THINK THIS IS WHERE THE SEG FAULT IS HAPPENING BUT LETS SEE \n");
			dbg(GENERAL_CHANNEL, "\t\t\t\t-- Sending Syn Packet: Src->%d, Dest-> %d, Seq->%d\n", msg.src, msg.dest, msg.seq);
			dbg(GENERAL_CHANNEL, "\t\t\t\t-- Sending Syn Packet: TTL->%d\n", msg.TTL);
			call Transport.send(&newConnection, msg);
			//remove old connection info
			//insert new connection into list of current connections
			call sockets.insert(fd, newConnection);
			dbg(GENERAL_CHANNEL, "\t\t\t\t-- Successful\n");
			return SUCCESS;
		} else {
			dbg(GENERAL_CHANNEL, "\t\t\t\t-- Failed\n");
			return FAIL;
		}
	}

	/**
 	* Closes the socket.
 	* @param
 	*    socket_t fd: file descriptor that is associated with the socket
 	*       that you are closing.
 	* @side Client/Server
 	* @return socket_t - returns SUCCESS if you are able to attempt
 	*    a closure with the fd passed, else return FAIL.
 	*/
	 command error_t Transport.close(socket_t fd, uint16_t seq) {
		 //remove socket from list of active connections
		 socket_store_t socket;
		 pack msg;
		 tcp_packet tcp_msg;

		 dbg(GENERAL_CHANNEL, "Transport.Close\n");
		 if (call sockets.contains(fd)) {

		 	socket = call sockets.get(fd);
			dbg(GENERAL_CHANNEL, "\t\tSetting TCP:\tDestPort->%u\n", socket.dest.port);
			tcp_msg.destPort = socket.dest.port;
			dbg(GENERAL_CHANNEL, "\t\t\t\tsrcPort->%u\n", socket.src);
			tcp_msg.srcPort = socket.src;
			dbg(GENERAL_CHANNEL, "\t\t\t\tseq->%u\n", seq);
			tcp_msg.seq = tcpSeq++;
			dbg(GENERAL_CHANNEL, "\t\t\t\tflag->%u\n", RST);
			tcp_msg.flag = RST;
			dbg(GENERAL_CHANNEL, "\t\t\t\tnumBytes->0\n");
			tcp_msg.numBytes = 0;
			dbg(GENERAL_CHANNEL, "\t\tSetting IP:\tdest->%u\n", socket.dest.addr);
			msg.dest = socket.dest.addr;
			dbg(GENERAL_CHANNEL, "\t\t\t\tsrc->%u\n", TOS_NODE_ID);
			msg.src = TOS_NODE_ID;
			dbg(GENERAL_CHANNEL, "\t\t\t\tseq->%u\n", seq);
			msg.seq = seq;
			dbg(GENERAL_CHANNEL, "\t\t\t\tTTL->18\n");
			msg.TTL = 18;
			dbg(GENERAL_CHANNEL, "\t\t\t\tprotocol->%u\n",PROTOCOL_TCP);
			msg.protocol = PROTOCOL_TCP;
			dbg(GENERAL_CHANNEL, "\t\tCopying TCP pack to IP payload\n");
			memcpy(msg.payload, &tcp_msg, TCP_MAX_PAYLOAD_SIZE);

			call sockets.remove(fd);
			call sockets.insert(fd, socket);
			dbg(GENERAL_CHANNEL, "\t\tSending RST Packet\n");
			call Transport.send(&socket, msg);
		} else {
			dbg(GENERAL_CHANNEL, "UNABLE TO CLOSE");
			return FAIL;
		}
		dbg(GENERAL_CHANNEL, "\t\tSuccess!\n");

		 return SUCCESS;
	}

	/**
	* A hard close, which is not graceful. This portion is optional.
	* @param
	*    socket_t fd: file descriptor that is associated with the socket
	*       that you are hard closing.
	* @side Client/Server
	* @return socket_t - returns SUCCESS if you are able to attempt
	*    a closure with the fd passed, else return FAIL.
	*/
	command error_t Transport.release(socket_t fd) {
		return SUCCESS;
	}

	/**
	* Listen to the socket and wait for a connection.
	* @param
	*    socket_t fd: file descriptor that is associated with the socket
	*       that you are hard closing.
	* @side Server
	* @return error_t - returns SUCCESS if you are able change the state
	*   to listen else FAIL.
	*/
	command error_t Transport.listen(socket_t fd){
		socket_store_t socket;
		dbg(GENERAL_CHANNEL, "\tTransport.listen() ->\n");

		if(call sockets.contains(fd)) {
			socket = call sockets.get(fd);
			call sockets.remove(fd);

			// Setting to the ROOT Socket (port and address) Destinatinom for listening

			socket.state = LISTEN;
			dbg(GENERAL_CHANNEL, "\t\t\t   -- dest.port: %d dest.addr: %d state: %u\n", socket.dest.port, socket.dest.addr, socket.state);


			call sockets.insert(fd, socket);
			dbg(GENERAL_CHANNEL, "\t\t\t   -- Insert to sockets w/ fd: %d\n", fd);
			dbg(GENERAL_CHANNEL, "\t\t\t   -> Successful listen\n");
			return SUCCESS;
		}
		return FAIL;


		/* if(call sockets.contains(fd)){
			//We wanna get the socket back with our file descriptor
			socket = call sockets.get(fd);
			//Then we wanna update the values
			socket.state = LISTEN;
			call sockets.remove(fd);
			call sockets.insert(fd, socket);
			dbg(GENERAL_CHANNEL, "\t\t\t-- Server State: Listen with fd(%d)\n", fd);
			return (error_t)SUCCESS;
		}
		else{
			dbg(GENERAL_CHANNEL, "\t\t\t-- Server not listening: sockets didn't contain fd\n");
			return (error_t)FAIL;
		} */
	}
}
