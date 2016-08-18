module Network.Exocom where

import System.ZMQ4
import Control.Concurrent.MVar
import Data.ByteString as B
import Data.HashMap as HM
import Control.Concurrent.Chan
import Control.Concurrent


type ListenHandler = B.ByteString -> IO ()

data ExoRelay = ExoRelay {
  port :: Int,
  serviceName :: String,
  sendChan :: Chan B.ByteString,
  recieveHandlers :: MVar (HM.Map String ListenHandler)
}

newExoRelay :: Int -> String -> IO ExoRelay
newExoRelay portNum service = do
  let handlerMap = HM.empty
  handlerMapLock <- newMVar handlerMap
  sendchan <- newChan
  newContext <- context
  oSock <- socket newContext Push
  iSock <- socket newContext Pull
  let exo = ExoRelay portNum service sendchan handlerMapLock
  _ <- forkIO (senderThread exo oSock)
  return exo


senderThread :: ExoRelay -> Socket Push -> IO ()
senderThread exo sock = do
  let address = "tcp://localhost:" ++ (show (port exo))
  connect sock address
  waitAndSend exo sock

waitAndSend :: ExoRelay -> Socket Push -> IO ()
waitAndSend exo sock = do
  toSend <- readChan $ sendChan exo
  send sock [] toSend
  waitAndSend exo sock

sendMsg :: ExoRelay -> ByteString -> IO ()
sendMsg exo toSend = writeChan (sendChan exo) toSend
