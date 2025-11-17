docker image build
docker build -t freeswtich_new .
docker run command
sudo docker run -d  -p 6060:6060/udp   -p 6060:6060/tcp   -p 8022:8022/tcp  --name freeswitch_alt  freeswitch_new

freeswitch terminal:
docker exec -it freeswitch_alt bash
change directiry:
usr/local/freeswich/bin: ./fs_cli -H 127.0.0.1 -P 8022 -p ClueCon

then connect softphones using public ip , username, password and sip port.
