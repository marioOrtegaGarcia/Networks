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

https://docs.oracle.com/javase/tutorial/networking/sockets/definition.html



In component `Node':
lib/modules/TransportP.nc: In function `Transport.accept':
lib/modules/TransportP.nc:89: implicit declaration of function `connect'
lib/modules/TransportP.nc: In function `Transport.connect':
lib/modules/TransportP.nc:173: warning: return makes integer from pointer without a cast
/opt/tinyos-main/support/make/extras/sim.extra:67: recipe for target 'sim-exe' failed
make: *** [sim-exe] Error 1



*/
