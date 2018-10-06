

generic module DVRTableC(typedef t,int h, int n){
     provides interface DVRTable<t>;
}

implementation{
     const uint8_t MAX_DIST = h;
     const uint8_t DVR_MAX_SIZE = n;

     typedef struct DVRtouple{
        t dest;
        t dist;
        t nextHop;
     }hashmapEntry;

     DVRtouple table[DVR_MAX_SIZE];




     command void DVRTable.insert(uint8_t dest, uint8_t cost, uint8_t nextHop){
          //input data to a touple
          DVRtouple input = {dest, cost, nextHop};
     }

     command void remove(uint8_t dest){

     }

     command void clear(){

     }


}
