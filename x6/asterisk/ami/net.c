/*/
 *  Copyright © Justin Camp 2006
 *
 *  This file is part of Asterisk Manager Proxy (AMP).
 *
 *  Asterisk Manager Proxy is free software; you can redistribute it 
 *  and/or modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 2 of 
 *  the License, or (at your option) any later version.
 *
 *  Asterisk Manager Proxy is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Asterisk Manager Proxy; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 *  Send bugs, patches, comments, flames, the phone number of a very lonely
 *  and very ritch supermodel or any other ideas or information worth
 *  communicating to j@intuitivecreations.com
/*/

/*/
 *    net.c
 *    Network Functions
/*/

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <netdb.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
//#include <libxml/parser.h>

#include "ami/ami.h"
#include "net.h"

/*
#include "utils.h"
#include "log.h"
#include "thread.h"
#include "configuration.h"
#include "client.h"
#include "event.h"
#include "xml.h"
#include "status.h"
*/


#define AMP_NET_MAX_BUFFER 256

/*
static int check_agent_event(proxy_thread *pt, ast_event *e);
static int compare_agent(const char *needle, const char *agent);
*/

int sock_connect(char *host, int port){
  int sock;
  struct hostent *h;
  struct sockaddr_in saddr;
  int flags = 0;
  saddr.sin_family = AF_INET;
  saddr.sin_port = htons(port);
  if(!inet_aton(host,&saddr.sin_addr)){
    h = gethostbyname(host);
    if(!h){
      //amp_log(LOG_ERROR,"Unable to look up hostname %s: %s",host,strerror(errno));
      return -1;
    }
    //amp_log(LOG_DEBUG,"Found host %s",host);
    memcpy(&saddr.sin_addr,h->h_addr,sizeof(saddr.sin_addr));
  }
  sock = socket(PF_INET,SOCK_STREAM,0);
  if(sock <= 0){
    //amp_log(LOG_ERROR,"Unable to open a socket to host %s: %s",host,strerror(errno));
    return -1;
  }
  if(connect(sock,(struct sockaddr *)&saddr,sizeof(saddr)) < 0){
    //amp_log(LOG_ERROR,"Unable to connect to host %s: %s",host,strerror(errno));
    shutdown(sock,2);
    return -1;
  }
  fcntl(sock,F_SETFL,flags|O_NONBLOCK);
  //amp_log(LOG_DEBUG,"Connected to host %s",host);
  return sock;
}

int sock_bind(char *host, int port){
  int sock;
  struct hostent *h;
  struct sockaddr_in saddr;
  int flags;
  int so_reuse_opt = 1;
  saddr.sin_family = AF_INET;
  saddr.sin_port = htons(port);
  if(!strcmp(host,"*")){
    saddr.sin_addr.s_addr = htonl(INADDR_ANY);
  }else{
    if(!inet_aton(host,&saddr.sin_addr)){
      h = gethostbyname(host);
      if(!h){
        //amp_log(LOG_ERROR,"Unable to look up hostname %s: %s",host,strerror(errno));
        return -1;
      }
      //amp_log(LOG_DEBUG,"Found host %s",host);
      memcpy(&saddr.sin_addr,h->h_addr,sizeof(saddr.sin_addr));
    }
  }
  sock = socket(PF_INET,SOCK_STREAM,0);
  if(sock <= 0){
    //amp_log(LOG_ERROR,"Unable to open a socket to host %s: %s",host,strerror(errno));
    return -1;
  }
  flags = fcntl(sock,F_GETFL,0);
  if(fcntl(sock,F_SETFL,flags|O_NONBLOCK) != 0){
    //amp_log(LOG_ERROR,"Error setting sock to non-block: %s",strerror(errno));
  }
  setsockopt(sock,SOL_SOCKET,SO_REUSEADDR,&so_reuse_opt,sizeof(so_reuse_opt));
  if(bind(sock,(struct sockaddr *)&saddr,sizeof(saddr)) < 0){
    //amp_log(LOG_ERROR,"Unable to connect to host %s: %s",host,strerror(errno));
    shutdown(sock,2);
    return -1;
  }
  //amp_log(LOG_INFO,"Listening on host %s:%i",host,port);
  return sock;
}

void sock_close(int sock){
  struct sockaddr_in saddr;
  socklen_t size;
  char *addr;
  if(sock <= 0){ return; }
  size = sizeof(saddr);
  if(getpeername(sock,(struct sockaddr *)&saddr,&size) > -1){
    addr = inet_ntoa(saddr.sin_addr);
    //amp_log(LOG_DEBUG,"Closing connection %s (sock #%i)",inet_ntoa(saddr.sin_addr),sock);
  }else{
    //amp_log(LOG_DEBUG,"Closing connection [unknown]");
  }
  shutdown(sock,2);
}


/*
char *sock_receive(int sock){
  char *resp = NULL;
  char *reall = NULL;
  char c;
  int buffLen = 0;
  int i = 0;
  int bytes;
  int total = 0;
  short int is_xml = 0;
  xmlDoc *doc;
  if(sock <= 0){ return NULL; }
  resp = (char *)malloc(sizeof(char) * AMP_NET_MAX_BUFFER);
  buffLen = AMP_NET_MAX_BUFFER;
  if(!resp){ return NULL; }
  resp[0] = '\0';
  while((bytes = recv(sock,&c,1,0))){
    if(bytes <= 0 && total <= bytes){
      free(resp);
      return NULL;
    }else if(c == '\0' && i == 0){
      return NULL;
    }else if(bytes <= 0){
      continue;
    }else{
      total += bytes;
    }
    if(i >= (buffLen - 1)){
      reall = (char *)realloc((void *)resp,(buffLen + AMP_NET_MAX_BUFFER));
      if(!reall){
        free(resp);
        return NULL;
      }
      resp = reall;
      reall = NULL;
      buffLen += AMP_NET_MAX_BUFFER;
    }
    if(i == 0 && (c == '\n' || c == ' ' || c == '\r')){
      resp[i] = c;
      resp[i+1] = '\0';
      break;
    }
    if(c == '<' && i == 0){ is_xml = 1; }
    resp[i] = c;
    resp[i+1] = '\0';
    if(is_xml){
      if(c == '>'){
        if((doc = xmlParseMemory(resp,strlen(resp)))){
          xmlFreeDoc(doc);
          break;
        }else{
          ami_sock_readable(sock,-1);
        }
      }
    }else{
      if(i > 3 && resp[i-3] == '\r' && resp[i-2] == '\n' && resp[i-1] == '\r' && resp[i] == '\n'){
        break;
      }else{
        ami_sock_readable(sock,-1);
      }
    }
    i++;
  }
  if(!strlen(resp)){
    free(resp);
    return NULL;
  }
  return resp;
}
*/


/*
void proxy_server(void *unused){
  int sock = 0;
  char *host;
  short int *port;
  pthread_t tid;
  short int error = 0;
  int client_sock = 0;
  struct sockaddr client_addr;
  struct sockaddr_in client_addr_trans;
  socklen_t client_addr_size;
  struct client_conn *client;
  int flags;
  
  client_addr_size = (socklen_t)sizeof(client_addr);
  
  tid = pthread_self();
  if(thread_register(&tid,1,CLIENT_REG_TYPE_UNKNOWN,CLIENT_COM_FORMAT_UNKNOWN,NULL)){
    amp_log(LOG_ERROR,"Unable to register proxy server thread");
    error = 1;
  }
  
  host = (char *)get_config_param("server host");
  port = (short int *)get_config_param("server port");

  if(!host || !strlen(host)){
    amp_log(LOG_ERROR,"Unable to bind to server address: Missing a hostname to bind to");
    error = 1;
  }
  if(!port || !*port){
    amp_log(LOG_ERROR,"Unable to bind to server address: Missing the port to bind to");
    error = 1;
  }

  if(!error){
    sock = sock_bind(host,*port);
    if(sock <= 0){
      amp_log(LOG_ERROR,"Unable to bind to server address %s:%i",host,*port);
      error = 1;
    }
  }
  
  if(error){ proxy_stop(); }
  
  if(!error){
    listen(sock,10);
    while(1){
      if(!proxy_continue()){ break; }
      if(!client_proxy_continue()){ break; }
      if(ami_sock_readable(sock,NET_WAIT_TIMEOUT_MIL * 4)){
        client_sock = accept(sock,&client_addr,&client_addr_size);
        if(client_sock){
          client = (struct client_conn *)malloc(sizeof(struct client_conn));
          if(!client){
            amp_log(LOG_ERROR,"Unable to allocate memory for a new client connection");
            sock_close(client_sock);
          }else{
            client->sock = client_sock;
            memcpy(&client->addr,&client_addr,sizeof(client_addr));
            flags = fcntl(client->sock,F_GETFL,0);
            fcntl(client->sock,F_SETFL,flags|O_NONBLOCK);
	          client_addr_trans = *(struct sockaddr_in *)&client_addr;
	          amp_log(LOG_INFO,"Accepting new client connection: %s",inet_ntoa(client_addr_trans.sin_addr));
            if(thread_create((void *)proxy_client,(void *)client)){
              amp_log(LOG_ERROR,"Unable to spawn asterisk event connection thread!");
              sock_close(client->sock);
              free(client);
            }
            client_sock = 0;
          }
        }else{
          amp_log(LOG_ERROR,"Unable to accept client connection: %s",strerror(errno));
        }
      }
    }
  }
  
  if(sock){ sock_close(sock); }
  
  thread_remove(&tid);
  amp_log(LOG_DEBUG,"Proxy Server Thread Ending");
}
*/

/*
void proxy_client(void *cinfo){
  struct client_conn *c;
  proxy_thread *pt;
  char *resp;
  pthread_t tid;
  short int error = 0;
  int last_event_id = 0;
  ast_event *e;
  xml_root *rn;
  short int f = -1;
  char *xmlStr;
  ast_packet_item *iptr;
  char *cptr;
  short int closeCount = 0;
  struct sockaddr_in client_addr_trans;

  c = (struct client_conn *)cinfo;
  
  tid = pthread_self();
  if(thread_register(&tid,0,CLIENT_REG_TYPE_UNKNOWN,CLIENT_COM_FORMAT_UNKNOWN,NULL)){
    amp_log(LOG_ERROR,"Unable to register thread");
    error = 1;
  }
  
  xmlSetGenericErrorFunc((void *)devnull,NULL);

  pt = thread_self();
  
  while(!error){
    if(!proxy_continue()){ break; }
    if(!client_proxy_continue()){ break; }
    if(ami_sock_readable(c->sock,(NET_WAIT_TIMEOUT_MIL * 2))){
      resp = sock_receive(c->sock);
      if(!resp){
        if(closeCount > 2){ break;
        }else{ closeCount++; }
      }else{
        closeCount = 0;
        trim(resp);
        if(!isempty(resp)){
          amp_log(LOG_DEBUG,"Got size(%i): %s",strlen(resp),resp);
          client_command(resp);
        }
        free(resp);
      }
    }
    if(pt->registration_type && pt->events){
      e = event_get_next(&tid);
      f = client_cmd_format(pt);
      while(e){
        if(pt->registration_type == CLIENT_REG_TYPE_AGENT){
          if(!check_agent_event(pt,e)){
            event_destroy(e);
            e = event_get_next(&tid);
            continue;
          }
        }
        if(f == CLIENT_COM_FORMAT_XML){
          rn = xml_create_root("event");
          if(!rn){
            amp_log(LOG_ERROR,"Unable to create xml doc for response");
            event_destroy(e);
            e = event_get_next(&tid);
            continue;
          }
        }
        iptr = e->event->first_item;
        while(iptr){
          if(f == CLIENT_COM_FORMAT_ASTERISK){
            client_send_format(c->sock,"%s: %s\r\n",iptr->name,iptr->value);
          }else{
            xml_add_attr(rn->root,iptr->name,iptr->value);
          }
          iptr = iptr->next;
        }
        if(f == CLIENT_COM_FORMAT_ASTERISK){
          client_send(c->sock,"\r\n");
        }else{
          xmlStr = xml_tostring(rn->doc);
          client_send(c->sock,xmlStr);
          xml_destroy_doc(rn);
          free(xmlStr);
        }
        event_destroy(e);
        e = event_get_next(&tid);
      }
    }
  }
  
  client_addr_trans = *(struct sockaddr_in *)&c->addr;
  amp_log(LOG_INFO,"Closing client connection: %s",inet_ntoa(client_addr_trans.sin_addr));
  if(c->sock){ sock_close(c->sock); }
  thread_remove(&tid);
  free(c);
}
*/

/*
static int check_agent_event(proxy_thread *pt, ast_event *e){
  char *cptr;
  char *cptr1;
  char *cptr2;
  char buff[80];
  status_queue *qptr;
  if(!e || !pt || !strlen(pt->agentid)){ return 0; }
  cptr = ami_get_packet_item_value(e->event,"Event");
  if(!strcasecmp(cptr,"Agentcallbacklogoff") || !strcasecmp(cptr,"Agentlogin") ||
     !strcasecmp(cptr,"Agentcallbacklogin") || !strcasecmp(cptr,"Agentlogoff")){
    cptr1 = ami_get_packet_item_value(e->event,"Agent");
    if(compare_agent(cptr1, pt->agentid)){
      return 1;
    }
  }else if(!strcasecmp(cptr,"AgentCalled")){
    cptr1 = ami_get_packet_item_value(e->event,"AgentCalled");
    if(compare_agent(cptr1, pt->agentid)){
      return 1;
    }
  }else if(!strcasecmp(cptr,"AgentConnect")){
    cptr1 = ami_get_packet_item_value(e->event,"Member");
    if(compare_agent(cptr1, pt->agentid)){
      return 1;
    }
  }else if(!strcasecmp(cptr,"AgentComplete")){
    cptr1 = ami_get_packet_item_value(e->event,"Member");
    if(cptr1){
      if(compare_agent(cptr1, pt->agentid)){
        return 1;
      }
    }else{
      cptr = ami_get_packet_item_value(e->event, "Channel");
      strncpy(buff,cptr,sizeof(buff));
      cptr1 = strrchr(buff, '-');
      *cptr = '\0';
      if(compare_agent(buff, pt->agentid)){
        return 1;
      }
    }
  }else if(!strcasecmp(cptr,"Dial")){
    cptr = ami_get_packet_item_value(e->event,"Source");
    cptr1 = ami_get_packet_item_value(e->event,"Destination");
    if(strcasestr(cptr,"SIP/") && strcasestr(cptr1,"Zap/")){
      cptr+= 4;
      strncpy(buff,cptr,sizeof(buff));
      cptr2 = strrchr(buff,'-');
      *cptr2 = '\0';
      if(compare_agent(buff, pt->agentid)){
        return 1;
      }
    }
  }else if(!strcasecmp(cptr,"Hangup")){
    cptr = ami_get_packet_item_value(e->event,"Channel");
    if(strcasestr(cptr,"SIP/")){
      cptr += 4;
      strncpy(buff,cptr,sizeof(buff));
      cptr2 = strrchr(buff,'-');
      *cptr2 = '\0';
      if(compare_agent(buff, pt->agentid)){
        return 1;
      }
    }
  }else if(!strcasecmp(cptr,"Join") || !strcasecmp(cptr,"Leave")){
    cptr = ami_get_packet_item_value(e->event,"Queue");
    pthread_mutex_lock(&status_queue_m);
    qptr = status_queue_find(cptr);
    if(qptr){
      if(status_queue_member_find(qptr,pt->agentid)){
        pthread_mutex_unlock(&status_queue_m);
        return 1;
      }
    }
    pthread_mutex_unlock(&status_queue_m);
  }else if(!strcasecmp(cptr,"QueueMemberStatus") || !strcasecmp(cptr,"QueueMemberRemoved") ||
           !strcasecmp(cptr,"QueueMemberAdded") || !strcasecmp(cptr,"QueueMemberPaused")){
    cptr = ami_get_packet_item_value(e->event,"Queue");
    cptr1 = ami_get_packet_item_value(e->event,"Location");
    if(compare_agent(cptr1, pt->agentid)){
      return 1;
    }
  }
  return 0;
}
*/

/*
static int compare_agent(const char *needle, const char *agent){
  int ret = 0;
  status_agent *aptr;
  pthread_mutex_lock(&status_agent_m);
  aptr = status_agent_find(needle);
  if(aptr){
    if(!strcasecmp(aptr->agent, agent) || !strcasecmp(aptr->device_channel, agent)){
      ret = 1;
    }
  }
  pthread_mutex_unlock(&status_agent_m);
  return ret;
}
*/


