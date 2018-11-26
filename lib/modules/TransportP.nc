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

	command void Transport.makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
                Package->src = src;
                Package->dest = dest;
                Package->TTL = TTL;
                Package->seq = seq;
                Package->protocol = protocol;
		dbg(GENERAL_CHANNEL, "\t\t\t\t~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~HERE: length: %u memcpy not working ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n", sizeof(payload));
                //memcpy(Package->payload, payload, sizeof(payload/*length*/));
		dbg(GENERAL_CHANNEL, "\t\t\t\t~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~HERE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
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

	command void Transport.makeSynPack(tcp_packet* TCPheader, uint8_t destPort, uint8_t srcPort, uint16_t seq, uint8_t flag) {
	TCPheader->destPort = destPort;
	TCPheader->srcPort = srcPort;
	TCPheader->seq = seq;
	TCPheader->flag = flag;
	}

	command void Transport.makeAckPack(tcp_packet* TCPheader, uint8_t destPort, uint8_t srcPort, uint16_t seq, uint8_t flag, uint8_t advertisedWindow) {
	TCPheader->destPort = destPort;
	TCPheader->srcPort = srcPort;
	TCPheader->seq = seq;
	TCPheader->flag = flag;
	TCPheader->advertisedWindow = advertisedWindow;
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		pack* recievedMsg =  (pack*)  payload;

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
		fdKeys++;
		if(fdKeys < 10) {
			newSocket.state = CLOSED;
			newSocket.lastWritten = 0;
			newSocket.lastAck = 0xFF;
			newSocket.lastSent = 0;
			newSocket.lastRead = 0;
			newSocket.lastRcvd = 0;
			newSocket.nextExpected = 0;
			newSocket.RTT = RTT;
			call sockets.insert(fdKeys, newSocket);
			return (socket_t)fdKeys;
		} else {
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
		if(call sockets.contains(fd)) {
			refSocket = call sockets.get(fd);
			call sockets.remove(fd);

			refSocket.state = CLOSED;
			refSocket.src = addr->port;
			dbg(GENERAL_CHANNEL, "\t\t\t-- port: %u\n", addr->port);

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
		if (!call sockets.contains(fd)) {
			dbg(GENERAL_CHANNEL, "Transport.accept() -- Sockets does not contain fd: %d\n", fd);
			return (socket_t)NULL;
		}

		localSocket = call sockets.get(fd);
		dbg(GENERAL_CHANNEL, "\t\t\t-- Sockets does contain fd: %d\n", fd);
		dbg(GENERAL_CHANNEL, "\t\t\t-- Sockets state: %u\n", localSocket.state);
		if (localSocket.state == LISTEN && numConnected < 10) {
			numConnected++;
			localSocket.dest.addr = TOS_NODE_ID;
			localSocket.state = SYN_RCVD;
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
		tcp_packet recievedTcp;
		error_t check = FAIL;

		msg = package;
		recievedTcp = package->payload;

		switch(recievedTcp->flag) {
			case 1 ://syn
				//reply with SYN + ACK
				recievedTcp->flag = 2;
				//makeTCPPack
				makeAckPack(&recievedTcp, recievedTcp->destPort, recievedTcp->srcPort, recievedTcp->seq+1, recievedTcp->flag, 10 /*advertisedWindow*/)
				//Set TCP PAck as payload for msg
				//makePack
				makePack(&msg, msg->dest, msg->src, msg->seq, msg->TTL, msg->protocol, msg->payload);
				//sendpack
				break;

			case 2:	//ACK
				dbg(GENERAL_CHANNEL, "Transport.receive() default flag ACK");
				//Start Sending to the Sever
				break;

			case 4: // Fin
				dbg(GENERAL_CHANNEL, "Transport.receive() default flag FIN");

				break;

			case 8: // RST
				dbg(GENERAL_CHANNEL, "Transport.receive() default flag RST");

				break;

			default:
				dbg(GENERAL_CHANNEL, "Transport.receive() Data packet?");
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
			dbg(GENERAL_CHANNEL, "\t\t\tBreaking before makeTCPPack\n");

			call Transport.makeSynPack(&tcp_msg,
						newConnection.dest.port,
						newConnection.src,
						call Random.rand16() % 65530,
						1);
			call Transport.makePack(&msg,
						(uint16_t)NULL,
						(uint16_t)NULL,
						(uint16_t)1,
						PROTOCOL_TCP,
						(uint16_t)1,
						(void*)tcp_msg,
						(uint8_t)sizeof(&tcp_msg));

			/* send() */
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
