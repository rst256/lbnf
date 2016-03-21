#define List__next(CNTR) CNTR->next
//#define

/*@ NEXT(CNTR){
		return vardefs[CNTR]..'__next('..CNTR..')'
}@*/

typedef struct list {
	void * value; struct list * next;
} List;
struct list3;
typedef struct list1 {
	void * value; struct list * next;
} **List1;

int main(int argc, char **argv){
	List l1;
	printf("l1 type is %s, %p\n", $l1, NEXT(l1));
	если(
	return 0;
}



//eof