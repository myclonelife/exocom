package exorelay

import (
	"errors"
	"fmt"

	uuid "github.com/satori/go.uuid"

	"golang.org/x/net/websocket"
	// HandlerManager
	// MessageSender
)

// Message struct to format messages. Mainly available for testing
type Message struct {
	Name         string      `json:"name,omitempty"`
	Sender       string      `json:"sender,omitempty"`
	Payload      interface{} `json:"payload,omitempty"`
	ResponseTo   string      `json:"responseTo,omitempty"`
	ID           string      `json:"id,omitempty"`
	Timestamp    int         `json:"timestamp,omitempty"`
	ResponseTime int         `json:"timestamp,omitempty"`
}

// information about an ExoRelay instance
type Relay struct {
	ServiceName string
	ExocomHost  string
	ExocomPort  int
	websocket   *websocket.Conn
}

// creates a new Relay instance connected to ExoCom
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

// closes the connection to ExoCom
func (relay *Relay) Close() error {
	return relay.websocket.Close()
}

// sends a message with the given name and payload to ExoCom
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

// handles incoming messages
func (relay *Relay) OnIncomingMessage(request string) (string, error) {
	fmt.Println("OnIncomingMessage is unimplemented")
	return "error", errors.New("OnIncomingMessage is unimplemented\n")
}

// sends the routing configuration to ExoCom
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
