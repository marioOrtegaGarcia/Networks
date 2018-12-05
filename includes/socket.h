#ifndef __SOCKET_H__
#define __SOCKET_H__

enum{
    MAX_NUM_OF_SOCKETS = 10,
    ROOT_SOCKET_ADDR = 255,
    ROOT_SOCKET_PORT = 255,
    SOCKET_BUFFER_SIZE = 128,
};

enum socket_state{
    CLOSED = 0,
    LISTEN = 1,
    ESTABLISHED = 3,
    SYN_SENT  = 4,
    SYN_RCVD = 5
};


typedef nx_uint8_t nx_socket_port_t;
typedef uint8_t socket_port_t;

// socket_addr_t is a simplified version of an IP connection.
typedef nx_struct socket_addr_t{
    nx_uint16_t port;
    nx_uint16_t addr;
}socket_addr_t;


// File descripter id. Each id is associated with a socket_store_t
typedef uint8_t socket_t;

// State of a socket.
typedef struct socket_store_t {
    uint8_t flag;
    enum socket_state state;
    uint16_t src;
    socket_addr_t dest;

    // This is the sender portion.
    uint8_t sendBuff[SOCKET_BUFFER_SIZE];
    uint16_t lastWritten;
    uint16_t lastAck;
    uint16_t lastSent;

    // This is the receiver portion
    uint8_t rcvdBuff[SOCKET_BUFFER_SIZE];
    uint16_t lastRead;
    uint16_t lastRcvd;
    uint16_t nextExpected;

    uint16_t RTT;
    uint8_t effectiveWindow;
} socket_store_t;

#endif
