include ../auth

prefix := /usr/local

# The recommended compiler flags for the Raspberry Pi
CXXFLAGS=-Wall -Ofast -mfpu=vfp -mfloat-abi=hard -march=armv6zk -mtune=arm1176jzf-s -fno-strict-aliasing  -g
CPPFLAGS=-I$(prefix)/include -I/usr/include/mysql -I../tinysensor -DBIG_JOINS=1 -DHOST=\"${HOST}\" -DDATABASE=\"${DATABASE}\" -DUSER=\"${USER}\" -DPASS=\"${PASSWORD}\"
LDFLAGS=-L$(prefix)/lib -lrf24-bcm -lrf24-network -lmysqlclient -lpthread -lz -lm -lrt -ldl

PROGRAMS = sensorhub mux nrf24listener
SOURCES = ${PROGRAMS:=.cpp}
OBJECTS = ${PROGRAMS:=.o}

all: ${PROGRAMS}

nrf24listener: nrf24listener.o

sensorhub: sensorhub.o

mux: mux.o

clean:
	rm -rf $(PROGRAMS) $(OBJECTS)

