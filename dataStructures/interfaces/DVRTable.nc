interface DVRTable{


     uint8_t MAX_DIST = 16;

     command void insert(uint8_t dest, uint8_t cost, uint8_t nextHop);
     command void remove(uint8_t dest);
     command void clear();
}
