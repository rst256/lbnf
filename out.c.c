#define List__next(CNTR) CNTR->next
//#define

/*@ NEXT(CNTR){
		return vardefs[CNTR]..'__next('..CNTR..')'
}@*/

typedef struct list {
	void * value; struct list * next;
} List;


int main(int argc, char **argv){
	List l1;
	printf("l1 type is %s, %p\n", "List", List__next(l1));
	return 0;
}



//eof