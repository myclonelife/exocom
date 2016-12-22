package exorelay

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/DATA-DOG/godog"
	"github.com/DATA-DOG/godog/gherkin"
	"github.com/Originate/exocom/exocom-mock-go"
)

func FeatureContext(s *godog.Suite) {
	var relay *Relay
	var exocom *exocomMock.ExoCom
	var lastMessageID string // message ID of last message
	var lastErr error        // Last error returned

	s.AfterScenario(func(interface{}, error) {
		relay.Close()
		exocom.Close()
		fmt.Println("EXOCOM CLOSED")
	})

	s.Step(`^ExoCom runs at port (\d+)$`, func(port int) error {
		exocom = exocomMock.New()
		go exocom.Listen(port)
		return nil
	})

	s.Step(`^an ExoRelay instance running inside the "([^"]*)" service on port (\d+)$`, func(serviceName string, port int) error {
		var err error
		relay, err = New(serviceName, "localhost", port)
		if err != nil {
			return err
		}
		timeout := time.After(500 * time.Millisecond)
		for {
			select {
			case <-timeout:
				return fmt.Errorf("service %s could not be registered", serviceName)
			default:
				if _, registered := exocom.Services[serviceName]; registered {
					return nil
				}
			}
		}
	})

	s.Step(`^sending a message with the name "([^"]*)" and no payload$`, func(name string) error {
		var err error
		lastMessageID, lastErr = relay.Send(name, "")
		return err
	})

	s.Step(`^sending the message:$`, func(message *gherkin.DocString) error {
		var err error
		var outgoing Message
		if err := json.Unmarshal([]byte(message.Content), &outgoing); err != nil {
			return err
		}
		payload, err := json.Marshal(outgoing.Payload)
		if err != nil {
			return err
		}
		lastMessageID, err = relay.Send(outgoing.Name, string(payload))
		return err
	})

	s.Step(`^trying to send an empty message$`, func() error {
		lastMessageID, lastErr = relay.Send("", "")
		if lastErr == nil {
			return errors.New("Sending empty message was successful")
		}
		return nil
	})

	s.Step(`^ExoRelay makes the WebSocket request:$`, func(message *gherkin.DocString) error {
		var expected exocomMock.Message
		json.Unmarshal([]byte(message.Content), &expected)
		if expected.Payload == nil {
			expected.Payload = ""
		} else {
			temp, _ := json.Marshal(expected.Payload)
			expected.Payload = string(temp)
		}
		timeout := time.After(500 * time.Millisecond)
		for {
			select {
			case <-timeout:
				return errors.New("expected message not received")
			default:
				for _, received := range exocom.ReceivedMessages {
					expected.ID = received.ID
					if reflect.DeepEqual(received, expected) {
						return nil
					}
				}
			}
		}
	})

	s.Step(`^ExoRelay emits the error "([^"]*)"$`, func(errMsg string) error {
		if lastErr.Error() == errMsg {
			return nil
		}
		return fmt.Errorf(`Expected last error to be "%s", but it was "%s"`, errMsg, lastErr)
	})

}

func TestMain(m *testing.M) {
	var paths []string
	if len(os.Args) == 2 {
		paths = append(paths, strings.Split(os.Args[1], "=")[1])
	} else {
		paths = append(paths, "features")
	}
	status := godog.RunWithOptions("godogs", func(s *godog.Suite) {
		FeatureContext(s)
	}, godog.Options{
		Format:        "pretty",
		NoColors:      false,
		StopOnFailure: true,
		Paths:         paths,
	})

	os.Exit(status)
}
