#ifndef TCP_PACKET_H
#define TCP_PACKET_H
enum {
        TCP_HEADER_LENGTH = 9,
        TCP_MAX_PAYLOAD_SIZE = PACKET_MAX_PAYLOAD_SIZE;
};

enum {
        SYN = 1,
        ACK = 2,
        FIN = 4,
        RST = 8
};

typedef nx_struct tcp_packet {

  nx_uint8_t destPort;
  nx_uint8_t srcPort;
  nx_uint16_t seq;
  nx_uint16_t ack;
  nx_uint8_t flag;
  nx_uint8_t advertisedWindow;
  nx_uint8_t numBytes;
  nx_uint8_t payload[TCP_MAX_PAYLOAD_SIZE]
} tcp_packet;
//Include any  tcp_packet functions
#endif
