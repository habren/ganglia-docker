file=docker-compose.yaml
begin_seq=$1
end_seq=$2
cluster=$3
grid=$4
let total=end_seq-begin_seq+1
let top10=begin_seq+9
echo "total="$total
echo "version: '2.0'
networks:
  gmetad-net:
  gmond-net1:
  gmond-net2:
  gmond-net3:
  gmond-net4:
  gmond-net5:
  gmond-net6:
  gmond-net7:
  gmond-net8:
  gmond-net9:
  gmond-net10:
services:
  gmetad:
    build:
      context: .
      dockerfile: gmetad.Dockerfile
    image: jason/gmetad:3.7.2
    container_name: gmetad
    hostname: gmetad
    ports:
      - \"18080:8080\"
      - \"18649:8649/udp\"
      - \"18649:8649/tcp\"
      - \"18651:8651/tcp\"
    environment:
      CLUSTER_NAME: "$cluster"
      GRID_NAME: "$grid"
      LOCATION: gmetad
      HTTP_PORT: 8080
    networks:
      - gmetad-net
      - gmond-net1
      - gmond-net2
      - gmond-net3
      - gmond-net4
      - gmond-net5
      - gmond-net6
      - gmond-net7
      - gmond-net8
      - gmond-net9
      - gmond-net10" > $file
let index=begin_seq
while [[ index -le $end_seq ]]
do
	let net_seq=index/10+1
	let seq_in_net=index%10
	if [[ seq_in_net -eq 0 ]]
	then
		let seq_in_net=10
		let net_seq-=1
	fi
	name="gmond"$index
	echo "  "$name":
    build:
      context: .
      dockerfile: gmond.Dockerfile
    image: jason/gmond:3.7.2
    container_name: "$name"
    hostname: "$name"
    environment:
     LOCATION: "$name"
     CLUSTER_NAME: "$cluster"
    networks:
      - gmond-net"$seq_in_net >> $file

    if [[ index -le $top10 ]]
    then
    	echo "      - gmetad-net" >> $file
    fi

    let index+=1
done




