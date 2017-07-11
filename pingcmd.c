#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>

#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>
#include <netinet/ip_icmp.h>
#include <sys/socket.h>

#define DEFAULT_ECHO_LEN 8
#define BUF_LEN 1024
#define EOK 0

static char *addr;
static char *dev;
static int verbose = 0;
static int err;

void help (const char *p) {
    fprintf(stderr, "%s [-i interface] [-h addr]\n", p);
    exit(err);
}

int send_ping (const char *data, int socket, struct sockaddr *saddr, const socklen_t addrlen) {
    struct icmphdr icmp_h;
    
    // fill header with zeros and info
    memset(&icmp_h, 0, sizeof(icmp_h));
    icmp_h.type = ICMP_ECHO;
    icmp_h.code = 0;
    icmp_h.un.echo.id = 1337;
    
    unsigned char hdr_data[BUF_LEN];
        
    // fill data
    memset(hdr_data, 0x90, BUF_LEN);
    memcpy(hdr_data, &icmp_h, sizeof(icmp_h));
    
    // send ICMP packets depending on data
    if ( (strcmp(data, "")) == 0 ) {
        if ( (sendto(socket, hdr_data, DEFAULT_ECHO_LEN, 0, saddr, addrlen)) < 0 )
            return errno;
        return EOK;
    }

    while (*data != '\0') {
        size_t s_data;
        s_data = sizeof(icmp_h)+(int)*data;

        if ( (sendto(socket, hdr_data, s_data, 0, saddr, addrlen)) < 0 )
            return errno;
        data++;
        usleep(500);
    }

    return EOK;
}

int main (int argc, char *argv[]) {
    struct hostent *host;
    struct sockaddr_in sin; 
    int ret = EOK;
    int optc;
    int sock;

    while( (optc = getopt(argc, argv, "i:h:v") ) != -1 ) {
        switch (optc) {
            case 'i':
                dev = optarg;
                break;
            case 'h':
                addr = optarg;
                break;
            case 'v':
                verbose++;
                break;
            default:
                err = EINVAL;
                help(argv[0]);
        }
    }

    // dev && addr must be specified
    if (dev == NULL || addr == NULL) {
        err = ECANCELED;
        help(argv[0]);
    }

    if (verbose)
        printf("[i] dev:%s addr:%s\n", dev, addr);

    // get host
    if ( (host = gethostbyname(addr)) == NULL) {
        fprintf(stderr, "[-] error getting host information.\n");
        goto RET;
    }

    memset(&sin, 0, sizeof(sin));
    sin.sin_family = AF_INET;
    inet_pton(AF_INET, host->h_name, &sin.sin_addr);

    // socket creation
    sock = socket( sin.sin_family, SOCK_DGRAM, IPPROTO_ICMP);
    setsockopt(sock, SOL_SOCKET, SO_BINDTODEVICE, dev, strlen(dev));

    // enter main loop
    while(1) {
        printf("(cmd) $ ");
        
        char buf[BUF_LEN];
        if ( (fgets(buf, BUF_LEN-1, stdin)) != NULL ) {
            // let's clean that newline if there's any
            char *p = buf;
            while( *p != '\0' ) {
                if (*p == '\n') {
                    *p = '\0';
                    break;
                }
                p++;
            }
            
            // if buf is not empty
            if (buf[0] != '\0') {
                // quitting
                if( (strcmp(buf, "quit") == 0) ||
                    (strcmp(buf, "q") == 0) ) {
                    goto RET;
                }
                
                if (verbose)
                    printf("[i] command: %s\n", buf);
                if (send_ping(buf, sock, (struct sockaddr *)&sin, sizeof(sin)) < EOK) {
                    perror("[-] error:");
                    ret = errno;
                    goto RET;
                }
                if (send_ping("", sock, (struct sockaddr *)&sin, sizeof(sin)) < EOK) {
                    perror("[-] error:");
                    ret = errno;
                    goto RET;
                }

                continue;

                RET:
                    break;
            }
        }
    }

    return(ret);
}

