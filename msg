//创建一个消息队列

1.Makefile

.PHONY:all
all:client server
client:client.c comm.c
	gcc -o $@ $^
server:server.c comm.c
	gcc -o $@ $^
.PHONY:clean
clean:
	rm -f client server
  
2.comm.h

#ifndef _COMM_H_
#define _COMM_H_

#include <stdio.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/msg.h>
#include <string.h>
#include <sys/socket.h>

#define PATHNAME "."
#define PROJ_ID 0x6666

#define SERVER_TYPE 1
#define CLIENT_TYPE 2

struct msgbuf{
    long mtype;
    char mtext[1024];
};

int createMsgQueue();  //创建消息队列
int getMsgQueue();  //获取消息队列
int destroyMsgQueue(int msgid);
int sendMsg(int msgid,int flags,char *msg);  //发送消息
int recvMsg(int msgid,int recvType,char out[]);  //接收消息

#endif

3.comm.c

#include "comm.h"

//success > 0 failed == -1
static int commMsgQueue(int flags)
{
	key_t key=ftok(PATHNAME,PROJ_ID);  //ftok用来创建key值
	if(key<0)
	{
		perror("ftok");
		return -1;
	}
	int msgid=msgget(key,flags);  //获取消息队列标识符
	if(msgid<0){
	    perror("msgget");
	}
	return msgid;
}

int createMsgQueue()
{
	return commMsgQueue(IPC_CREAT|IPC_EXCL|0666);
}

int getMsgQueue()
{
	return commMsgQueue(IPC_CREAT);
}

int destroyQueue(int msgid)
{
	if(msgctl(msgid,IPC_RMID,NULL)<0)  //消息队列控制函数，第二个参数显示需要删除，第三个参数默认为0
	{
		perror("msgctl");
		return -1;
	}
	return 0;
}

int sendMsg(int msgid,int flags,char* msg)
{
	struct msgbuf buf;//创建消息结构
	buf.mtype=flags;  //表示谁发的类型
	strcpy(buf.mtext,msg);
	if(msgsnd(msgid,(void*)&buf,sizeof(buf.mtext),0)<0)
	{
		perror("msgsnd");
		return -1;
	}
	return 0;
}

int recvMsg(int msgid,int recvType,char out[])
{
	struct msgbuf buf;
	if(msgrcv(msgid,(void*)&buf,sizeof(buf.mtext),recvType,0)<0){
		perror("msgrcv");
		return -1;
	}
	strcpy(out,buf.mtext);  //将消息队列中的消息拷贝到out数组中
	return 0;
}

4.server.c

#include "comm.h"

int main()
{
	int msgid=createMsgQueue();
	char buf[1024];
	while(1){
		buf[0]=0;
		recvMsg(msgid,CLIENT_TYPE,buf);  //server先接受后发送。
		printf("client: %s\n",buf);

		printf("Please Enter: ");
		fflush(stdout);
		ssize_t s=read(0,buf,sizeof(buf));  //从键盘读入到buf中，含有换行符
		if(s>0){
			buf[s-1]=0;
			sendMsg(msgid,SERVER_TYPE,buf);
			printf("send done,wait recv...\n");
		}
	}
		destroyMsgQueue(msgid);
		return 0;
}

5.client

#include "comm.h"

int main()
{
	int msgid=getMsgQueue();
	char buf[1024];
	while(1){
		buf[0]=0;
		printf("Please Enter: ");
		fflush(stdout);
		ssize_t s=read(0,buf,sizeof(buf));
		if(s>0)
		{
			buf[s-1]=0;
			sendMsg(msgid,CLIENT_TYPE,buf);  //client先发送后接受
			printf("send done,wait recv...\n");
		}
		
		recvMsg(msgid,SERVER_TYPE,buf);
		printf("server: %s\n",buf);
	}
		return 0;
}


