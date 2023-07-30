
void main()
{
	int a;
	scanf("%d",&a);
	for( int i = a; i < 11 ; i++ ){
		a = i;
		printf("cur a = %d\n",a);
		switch(a){
			case 1:
				printf("case 1:%d\n",a);
				break;
			case 2:
				printf("case 2:%d\n",a);
				break;
			case 3:
				printf("case 3:%d\n",a);
				break;
			case 4:
				printf("case 4:%d\n",a);
				break;
			case 5:
				printf("case 5:%d\n",a);
				break;
			case 6:
				printf("case 6:%d\n",a);
				break;
			case 7:
				printf("case 7:%d\n",a);
				break;
			case 8:
				printf("case 8:%d\n",a);
				break;	
			case 9:
				printf("case 9:%d\n",a);
				break;	
			case 10:
				printf("case 10:%d\n",a);
				break;								
			case 0:
				printf("case 0:%d\n",a);
				break;						
			default:
				break;
		}
	}
	printf("%d\n",a);
}
