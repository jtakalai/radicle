module Radicle.Internal
    ( createImpureBindings
    ) where

import           Protolude
import           Radicle.Daemon.Client (createDaemonClientPrimFns)
import           Radicle.Lang.Core (Bindings, PrimFns)
import           Radicle.Lang.PrimFns (addPrimFns, pureEnv)
import           Radicle.Repl (ReplM, replPrimFns)

-- | Create all impure bindings. This is in IO so as to create a
-- manager for the HTTP requests to the daemon.
createImpureBindings :: (MonadIO m, ReplM m) => [Text] -> IO (Bindings (PrimFns m))
createImpureBindings scriptArgs' = do
    daemonClientPrimFns <- createDaemonClientPrimFns
    pure $ addPrimFns (replPrimFns scriptArgs' <> daemonClientPrimFns) pureEnv
