package main

import (
	"context"
	"log"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	pingproto "github.com/cre8ivejp/bazel-sample/proto/ping"
)

const (
	address = "localhost:8080"
)

func main() {
	conn, err := grpc.Dial(address, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()

	c := pingproto.NewPingClient(conn)

	req := &pingproto.PingRequest{}
	resp, err := c.Ping(context.Background(), req)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("Timestamp: ", resp.Timestamp)
}
