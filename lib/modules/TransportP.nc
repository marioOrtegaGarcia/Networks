#include "../../includes/packet.h"
#include "../../includes/socket.h"
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
	uses interface Receive;
	uses interface SimpleSend as Sender;
}

implementation {
	pack sendMessage;
	tcp_packet* tcp_msg;
	uint16_t RTT = 12000;
	uint16_t fdKeys = 0;
	uint8_t numConnected = 0;
	uint8_t max_tcp_payload = 20;

	command void Transport.makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length) {
		tcp_packet* tcpp = (tcp_packet*) payload;

		Package->src = src;
		Package->dest = dest;
		Package->TTL = TTL;
		Package->seq = seq;
		Package->protocol = protocol;

		dbg(GENERAL_CHANNEL, "\t\t\t~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~HERE: length: %u memcpy not working ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n", length);
		dbg(GENERAL_CHANNEL, "TCP Pack Unwrap: %d", tcpp->destPort);

		memcpy(Package->payload, payload, TCP_MAX_PAYLOAD_SIZE);
		dbg(GENERAL_CHANNEL,"\t\t\t\t~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~HERE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
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

		dbg(GENERAL_CHANNEL, "\t\t\t\t~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~HERE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
	 	memcpy(TCPheader->payload, payload, sizeof(payload));
	}

	// Method used to make SYN to only initiate the required variables
	command void Transport.makeSynPack(tcp_packet* TCPheader, uint8_t destPort, uint8_t srcPort, uint16_t seq) {
	TCPheader->destPort = destPort;
	TCPheader->srcPort = srcPort;
	TCPheader->seq = seq;
	TCPheader->flag = SYN;
	dbg(GENERAL_CHANNEL, "\t\t\tmakeSynPack complete with values destPort: %d srcPort: %d seq: %d\n", TCPheader->destPort, TCPheader->srcPort, TCPheader->seq);
	}

	// Method used to make ACK to reply too SYN
	command void Transport.makeAckPack(tcp_packet* TCPheader, uint8_t destPort, uint8_t srcPort, uint16_t seq, uint8_t flag, uint8_t advertisedWindow) {
	TCPheader->destPort = destPort;
	TCPheader->srcPort = srcPort;
	TCPheader->seq = seq;
	TCPheader->flag = flag;
	TCPheader->advertisedWindow = advertisedWindow;
	}

	// Computing the Calculated Window based off the advertised Window minuts the things we've already sent and know they have received
	command uint8_t Transport.calcWindow(socket_store_t* sock, uint16_t advertisedWindow) {
		return advertisedWindow - (sock->lastSent - sock->lastAck - 1);
	}

	command pack Transport.send(socket_store_t * s, pack IPpack) {
		// Making a tcp_packet pointer for the payload of IP Pack
		tcp_packet* data;
		data = (tcp_packet*)IPpack.payload;

		// Computing aw and increasing the ACK
		data->advertisedWindow = call Transport.calcWindow(s, data->advertisedWindow);
		data->ack = s->nextExpected;

		//  Setting the src and dest Ports from our socket_store_t
		data->srcPort = s->src;
		data->destPort = s->dest.port;

		//call Transport.makeTCPPack(data, data->destPort, data->srcPort, data->seq, data->ack, data->flag, data->advertisedWindow, data->numBytes, (void*)data->payload);
		//call Transport.makePack(&IPpack, IPpack->src, IPpack->dest, IPpack->TTL, IPpack->protocol, IPpack->seq, (void*) data, sizeof(data));

		// Sending the IP packet to the destPort
		call Sender.send(IPpack, data->destPort);

		return IPpack;
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {

		pack* recievedMsg = (pack*) payload;
		//Sending all the PROTOCOL_TCP's to the Transport.receive function
		if (recievedMsg->protocol == PROTOCOL_TCP)
			call Transport.receive(recievedMsg);
	}
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
		dbg(GENERAL_CHANNEL, "Transport.socket()\n");
		// Generate new Key
		fdKeys++;
		if(fdKeys < 10) {
			newSocket.state = CLOSED;
			newSocket.lastWritten = 0;
			/* newSocket.lastAck = 0xFF; */
			newSocket.lastAck = 0;
			newSocket.lastSent = 0;
			newSocket.lastRead = 0;
			newSocket.lastRcvd = 0;
			newSocket.nextExpected = 0;
			newSocket.RTT = RTT;
			call sockets.insert(fdKeys, newSocket);
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
		dbg(GENERAL_CHANNEL, "Transport.bind()\n");
		// Making sure we contin  the file descriptor
		if(call sockets.contains(fd)) {
			refSocket = call sockets.get(fd);
			call sockets.remove(fd);

			// Binding the file  descriptor with the source port address
			refSocket.state = CLOSED;
			refSocket.src = addr->port;
			dbg(GENERAL_CHANNEL, "\t\t\t-- port: %u\n", addr->port);

			// Adding the Socket  back  to our hashtable
			call sockets.insert(fd, refSocket);
			dbg(GENERAL_CHANNEL, "\t\t\t-- Successful bind\n");
			return SUCCESS;
		}
		dbg(GENERAL_CHANNEL, "\t\t\t-- Failed bind\n");
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

		// Failing  if the filedescripter is not contained
		if (!call sockets.contains(fd)) {
			dbg(GENERAL_CHANNEL, "Transport.accept() -- Sockets does not contain fd: %d\n", fd);
			return (socket_t)NULL;
		}

		localSocket = call sockets.get(fd);
		dbg(GENERAL_CHANNEL, "\t\t\t-- Sockets does contain fd: %d\n", fd);
		dbg(GENERAL_CHANNEL, "\t\t\t-- Sockets state: %u\n", localSocket.state);

		// If were on a litening state and we have less than 10 sockets used
		if (localSocket.state == LISTEN && numConnected < 10) {

			// Keeping track of used sockets and my destination address, udating state
			numConnected++;
			localSocket.dest.addr = TOS_NODE_ID;
			localSocket.state = SYN_RCVD;

			// Clearing old and  inserting the modified socket back
			call sockets.remove(fd);
			call sockets.insert(fd, localSocket);
			dbg(GENERAL_CHANNEL, "\t\t\t-- returning %d\n", fd);
			return fd;
		}
		dbg(GENERAL_CHANNEL, "\t\t\t-- returning NULL\n");
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
		tcp_packet* recievedTcp;
		error_t check = FAIL;

		// Setting our pack and tcp_packet types
		// Why are we setting msg as a pointer????????
		msg = *package;
		recievedTcp = (tcp_packet*)package->payload;

		// Using switch cases for every flag enum we use
		switch(recievedTcp->flag) {
			case 1 ://syn
				//reply with SYN + ACK
				recievedTcp->flag = 2;

				//makeTCPPack
				call Transport.makeAckPack(recievedTcp, recievedTcp->destPort, recievedTcp->srcPort, recievedTcp->seq+1, recievedTcp->flag, 10 /*advertisedWindow*/);

				//makePack and Set TCP PAck as payload for msg
				call Transport.makePack(&msg, msg.dest, msg.src, msg.seq, msg.TTL, msg.protocol, (uint8_t*)recievedTcp, sizeof(recievedTcp));

				//send pack
				break;

			case 2:	//ACK
				dbg(GENERAL_CHANNEL, "\tTransport.receive() default flag ACK\n");
				//Start Sending to the Sever
				break;

			case 4: // Fin
				dbg(GENERAL_CHANNEL, "\tTransport.receive() default flag FIN\n");

				break;

			case 8: // RST
				dbg(GENERAL_CHANNEL, "\tTransport.receive() default flag RST\n");

				break;

			default:
				dbg(GENERAL_CHANNEL, "\tTransport.receive() Data packet?\n");
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
		pack msg;
		uint16_t seq;
		uint8_t* payload = 0;


		dbg(GENERAL_CHANNEL, "Transport.connect()\n");
		//if FD exists, get socket and set destination address to provided input addr
		if (call sockets.contains(fd)) {
			newConnection = call sockets.get(fd);
			call sockets.remove(fd);

			// Set connec both ports
			dbg(GENERAL_CHANNEL, "\t\t\t-- Port(%u)->Port(%u) w/ address(%u)\n", newConnection.src, addr->port, addr->addr);
			// Set destination address
			newConnection.dest = *addr;

			//send SYN packet

			seq = call Random.rand16() % 65530;

			dbg(GENERAL_CHANNEL, "\t\t\t Debug before makeSynPack\n");
			call Transport.makeSynPack(&tcp_msg, newConnection.dest.port, newConnection.src, seq);

			dbg(GENERAL_CHANNEL, "But this  runs ######################\n");
			//dbg(GENERAL_CHANNEL, "tcp_msg->destPort: %d############################\n", tcp_msg->destPort);
			dbg(GENERAL_CHANNEL, "But this  runs ######################\n");
			call Transport.makePack(&msg,
						(uint16_t)TOS_NODE_ID,
						(uint16_t)newConnection.src,
						(uint16_t)1,
						PROTOCOL_TCP,
						(uint16_t)1,
						(void*)tcp_msg,
						(uint8_t)sizeof(tcp_msg));

			/* We need to actually call send() once make Pack ends up workng */
			newConnection.state = SYN_SENT;

			//remove old connection info
			//insert new connection into list of current connections

			call sockets.insert(fd, newConnection);
			dbg(GENERAL_CHANNEL, "\t\t\t-- Successful\n");
			return SUCCESS;
		} else {
			dbg(GENERAL_CHANNEL, "\t\t\t-- Failed\n");
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
	 command error_t Transport.close(socket_t fd){

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
	command error_t Transport.release(socket_t fd){

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
		dbg(GENERAL_CHANNEL, "Transport.listen()\n");

		if(call sockets.contains(fd)) {
			socket = call sockets.get(fd);
			call sockets.remove(fd);

			// Setting to the ROOT Socket (port and address) Destinatinom for listening
			socket.dest.port = ROOT_SOCKET_PORT;
			socket.dest.addr = ROOT_SOCKET_ADDR;
			socket.state = LISTEN;

			call sockets.insert(fd, socket);
			dbg(GENERAL_CHANNEL, "\t\t\t-- Successful\n");
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
