#include <RF24Network.h>
#include <RF24.h>
#include <my_global.h>
#include <mysql.h>
#include <getopt.h>
#include <unistd.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/stat.h>


static int ss, cs;
int channel = 90;

void close_exit()
{
	printf("Closing connections\n");

	if (cs > 0)
		close(cs);
	if (ss > 0)
		close(ss);
	exit(1);
}

void fatal(const char *op, const char *error)
{
	fprintf(stderr, "%s: %s\n", op, error);
	close_exit();
}

void signal_handler(int signo)
{
	fatal("caught", strsignal(signo));
}

int main(int argc, char *argv[])
{
        printf("Starting");
	bool verbose = false, sock = true, daemon = true;
	int opt;
	while ((opt = getopt(argc, argv, "vs")) != -1)
		switch(opt) {
		case 'v':
			verbose = true;
			daemon = false;
			break;
		case 's':
			sock = false;
			break;
		default:
			fprintf(stderr, "Usage: %s [-v] [-s]\n", argv[0]);
			exit(1);
		}

	if (daemon) {
		pid_t pid = fork();

		if (pid < 0)
			exit(-1);
		if (pid > 0)
			exit(0);
		if (setsid() < 0)
			exit(-1);

		pid = fork();
		if (pid < 0)
			exit(-1);
		if (pid > 0)
			exit(0);

		umask(0);
		chdir("/tmp");
		close(0);
		close(1);
		close(2);
	}

	signal(SIGINT, signal_handler);

	// set up server socket for clients to connect to, to receive text data
	if (sock) {
		ss = socket(AF_INET, SOCK_STREAM, 0);
		if (ss < 0)
			fatal("socket", strerror(errno));

		struct sockaddr_in serv;
		memset(&serv, 0, sizeof(serv));
		serv.sin_family = AF_INET;
		serv.sin_addr.s_addr = htonl(INADDR_ANY);
		serv.sin_port = htons(5555);
		if (0 > bind(ss, (struct sockaddr *)&serv, sizeof(struct sockaddr)))
			fatal("bind", strerror(errno));

		if (0 > listen(ss, 1))
			fatal("listen", strerror(errno));
	}

	// set up radio details
	RF24 radio(RPI_V2_GPIO_P1_15, RPI_V2_GPIO_P1_26, BCM2835_SPI_CLOCK_DIVIDER_32);	
	radio.begin();
	radio.enableDynamicPayloads();
	radio.setAutoAck(true);
	radio.powerUp();

	const uint16_t this_node = 0;
	RF24Network network(radio);
	network.begin(channel, this_node);

	printf("node_id\t0\t1\t2\t3\t4\t5\t6\t7\t8\t9\t10\t11\t12\n");

	for (;;) {
		network.update();

		while (network.available()) {
			RF24NetworkHeader header;
			uint8_t buf[1024];
			network.read(header, &buf, sizeof(buf));

			// if client connected to socket, send data
			/*
			if (cs > 0) {
				char buf[1024];
				int n = sprintf(buf, "%d\t%d\t%3.1f\t%3.1f\t%d\t%4.2f\t%u\t%d\t%u\n", 
						header.from_node, payload.light, temperature, humidity, payload.status, 
						battery, header.type, header.id, payload.ms / 1000);
				if (0 > write(cs, buf, n)) {
					perror("write");
					close(cs);
					cs = 0;
				}
			}
			*/
			
			// dump received data
			printf("%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", 
					header.from_node, buf[0], buf[1], buf[2], buf[3], buf[4], buf[5], buf[6], buf[7], buf[8], buf[9], buf[10], buf[11], buf[12]);
		}

		// if server socket has received connection, set up client socket and send header
		struct timeval timeout;
		timeout.tv_usec = 100000;
		timeout.tv_sec = 0;
		fd_set rd;
		FD_ZERO(&rd);
		if (ss > 0)
			FD_SET(ss, &rd);
		if (select(ss + 1, &rd, 0, 0, &timeout) > 0) {
			struct sockaddr_in client;
			socklen_t addrlen = sizeof(struct sockaddr_in);
			cs = accept(ss, (struct sockaddr *)&client, &addrlen);
			if (cs < 0)
				fatal("accept", strerror(errno));

			const char *header = "node\tlight\tdegC\thum%\tstat\tVbatt\ttype\tmsg-id\ttime\n";
			write(cs, header, strlen(header));
		}
	}
	return 0;
}
