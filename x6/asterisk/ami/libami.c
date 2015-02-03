#include <errno.h>

#include "ami/ami.h"
#include "admin.c"
#include "channel.c"
#include "core.c"
#include "info.c"
#include "manager.c"
#include "net.c"

#include "mor_functions.c"



int asterisk_connect(char *host, int port){
  int sock;
  char buff[30];
  char welcome_string[] = "Asterisk Call Manager";
  int i = 0;
  char c;
  int bytes;
  char buff2[1024] = "";
  
  buff[0] = '\0';
  sock = sock_connect(host, port);
  
  if(sock <= 0){
    return -1;
  }
  
  if(ami_sock_readable(sock,NET_WAIT_TIMEOUT_MIL)){
    while((bytes = recv(sock,(void *)&c,1,0))){
      if(bytes <= 0){
      
	sprintf(buff2, "An error occurred reading from the asterisk socket: %s", strerror(errno));
        my_debug(buff2);
        sock_close(sock);
        return -1;
      }
      if(i >= sizeof(buff)){
        break;
      }
      if(c == '\n'){ break; }
      buff[i+1] = buff[i];
      buff[i] = c;
      i++;
    }
  }else{
    sprintf(buff2, "Something bad happened.. either a timeout or an error: %s",strerror(errno));
    my_debug(buff2);
    sock_close(sock);
    return -1;
  }
  if(strstr(buff,welcome_string) == NULL){
    sprintf(buff2, "Did not recieve the welcome message from asterisk!");
    my_debug(buff2);
    sock_close(sock);
    return -1;
  }
  return sock;
}



void asterisk_close(int sock){
  sock_close(sock);
}

