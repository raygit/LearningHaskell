module Chat (
  replyBack,
  logMessage,
  localBind,
  launchChat
  ) where

import Control.Concurrent (threadDelay)
import Control.Exception
import Control.Monad (forever)
import Control.Monad.IO.Class
import qualified Control.Distributed.Process as P
import Control.Distributed.Process.Node
import Control.Distributed.Process.Closure
import Network.Socket (ServiceName, HostName)
import Network.Transport
import Network.Transport.TCP (createTransport, defaultTCPParameters)

replyBack :: (P.ProcessId, String) -> P.Process ()
replyBack (sender, msg) = P.send sender msg

logMessage :: String -> P.Process ()
logMessage msg = P.say $ "handling " ++ msg

launchChat :: HostName -> ServiceName -> IO ()
launchChat h p = do
  Right t <- localBind h p -- e.g. "127.0.0.1" "10501" 
  node <- newLocalNode t initRemoteTable
  runProcess node $ do
    echoPid <- P.spawnLocal $ forever $ do
      P.receiveWait [P.match logMessage, P.match replyBack]
    P.say "Send some messages!"
    P.send echoPid "++ HELLO ++"
    self <- P.getSelfPid
    P.send echoPid (self, "hello")
    m <- P.expectTimeout 1000000
    case m of
        Nothing -> P.die "nothing came back!"
        Just x -> P.say $ "got " ++ x ++ " back! "
    liftIO $ threadDelay 2000000

-- Regardless of [[host]] provided, we will map to the IPv4 address
-- but the port to be bound will be respected.
localBind :: HostName ->
             ServiceName ->
             IO (Either IOException Transport)
localBind host service = createTransport host service (\_ -> ("0.0.0.0", service)) defaultTCPParameters

