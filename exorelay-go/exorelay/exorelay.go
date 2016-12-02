package exorelay

import (
	"errors"
	"fmt"

	uuid "github.com/satori/go.uuid"

	"golang.org/x/net/websocket"
	// HandlerManager
	// MessageSender
)

type Message struct {
	Name         string      `json:"name,omitempty"`
	Sender       string      `json:"sender,omitempty"`
	Payload      interface{} `json:"payload,omitempty"`
	ResponseTo   string      `json:"responseTo,omitempty"`
	ID           string      `json:"id,omitempty"`
	Timestamp    int         `json:"timestamp,omitempty"`
	ResponseTime int         `json:"timestamp,omitempty"`
}

type Relay struct {
	ServiceName string
	ExocomHost  string
	ExocomPort  int
	websocket   *websocket.Conn
}

func New(ServiceName, ExocomHost string, ExocomPort int) (*Relay, error) {
	ws, err := websocket.Dial(url(ExocomHost, ExocomPort), "", origin(ExocomHost))
	if err != nil {
		return nil, err
	}
	message := Message{
		Name:    "exocom.register-service",
		Sender:  ServiceName,
		Payload: fmt.Sprintf("name: \"%s\"", ServiceName),
		ID:      uuid.NewV4().String(),
	}
	websocket.JSON.Send(ws, message)
	return &Relay{ServiceName, ExocomHost, ExocomPort, ws}, err
}

func (relay *Relay) Close() error {
	return relay.websocket.Close()
}

func (relay *Relay) Send(name, payload string) (string, error) {
	if payload == "" && name == "" {
		return "", errors.New("ExoRelay.Send cannot send empty messages")
	}
	message := Message{
		Name:    name,
		Sender:  relay.ServiceName,
		Payload: payload,
		ID:      uuid.NewV4().String(),
	}
	err := websocket.JSON.Send(relay.websocket, message)
	return message.ID, err
}

func (relay *Relay) OnIncomingMessage(request string) (string, error) {
	fmt.Println("OnIncomingMessage is unimplemented")
	return "error", errors.New("OnIncomingMessage is unimplemented\n")
}

func (relay *Relay) SendRoutingConfig() error {
	fmt.Println("SendRoutingConfig is unimplemented")
	return errors.New("SendRoutingConfig is unimplemented\n")
}

func origin(host string) string {
	return fmt.Sprintf("http://%s/", host)
}

func url(host string, port int) string {
	return fmt.Sprintf("ws://%s:%d/services", host, port)
}

func NewMessage(name, sender, payload string) Message {
	return Message{
		Name:    name,
		Sender:  sender,
		Payload: payload,
		ID:      uuid.NewV4().String(),
	}
}
