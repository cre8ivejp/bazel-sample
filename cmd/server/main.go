package main

import (
	"fmt"
	"log"

	"net/http"

	"github.com/cre8ivejp/bazel-sample/pkg/uuid"
)

type HttpHandler struct{}

func (h HttpHandler) ServeHTTP(res http.ResponseWriter, req *http.Request) {
	id, err := uuid.Generate()
	if err != nil {
		log.Fatal(err)
	}
	message := fmt.Sprintf("Hello World! UUID: %s", id)
	data := []byte(message)
	_, err = res.Write(data)
	if err != nil {
		log.Fatal(err)
	}
}

func main() {
	handler := HttpHandler{}
	if err := http.ListenAndServe(":9000", handler); err != nil {
		log.Fatal(err)
	}
}
