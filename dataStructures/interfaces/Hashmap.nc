/**
 * ANDES Lab - University of California, Merced
 * This is an interface for Hashmaps.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */

interface Hashmap<t>{
   command void insert(uint32_t key, t input);
   command void remove(uint32_t key);
   command t get(uint32_t key);
   command bool contains(uint32_t key);
   command bool isEmpty();
   command uint16_t size();
   command uint32_t * getKeys();
}
/*
In component `TransportP':
lib/modules/TransportP.nc: In function `Transport.bind':
lib/modules/TransportP.nc:63: sockets.contains not connected
lib/modules/TransportP.nc:65: sockets.get not connected
lib/modules/TransportP.nc:69: sockets.remove not connected
lib/modules/TransportP.nc:70: sockets.insert not connected
lib/modules/TransportP.nc: In function `Transport.socket':
lib/modules/TransportP.nc:39: sockets.insert not connected
lib/modules/TransportP.nc:43: sockets.contains not connected
lib/modules/TransportP.nc: In function `Transport.accept':
lib/modules/TransportP.nc:91: sockets.get not connected
lib/modules/TransportP.nc:96: sockets.remove not connected
lib/modules/TransportP.nc:97: sockets.insert not connected

*/
