#ifndef DVRTABLE_H
#define DVRTABLE_H

enum {
  //maximum node id value
  MAX_NODE_ID = 255,
  //maximum # of hops before considered "infinity"
  MAX_COST = 16
};

typedef nx_struct DVRTable{
  //Array length 255, each element should directly correspond to a matching nodeid
  nx_uint8_t nodeIDs[MAX_NODE_ID][3];
}DVRtable;



#endif
