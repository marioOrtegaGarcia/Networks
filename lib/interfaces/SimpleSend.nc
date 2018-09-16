#include "../../includes/packet.h"

interface SimpleSend{
  //  This is just a simple send function
   command error_t send(pack msg, uint16_t dest );
}
