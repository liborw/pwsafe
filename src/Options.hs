module Options where

import Control.Monad
import System.Exit
import System.Environment (getEnv)
import System.FilePath (joinPath)
import System.Console.GetOpt
import Text.Printf (printf)

data Mode = Help | Add String | Query String | List | Edit | Dump | AcquireLock | ReleaseLock
  deriving (Eq, Show)

data Options = Options {
    mode          :: Mode
  , databaseFile  :: FilePath
  } deriving Show

defaultOptions :: Options
defaultOptions  = Options {
    mode          = Help
  , databaseFile  = ""
  }

options :: [OptDescr (Options -> Options)]
options = [
    Option []     ["help"]    (NoArg  (\  opts -> opts {mode = Help}))              "display this help and exit"
  , Option ['a']  ["add"]     (ReqArg (\s opts -> opts { mode = Add s })   "URL")   ""
  , Option ['q']  ["query"]   (ReqArg (\s opts -> opts { mode = Query s }) "TERM")  ""
  , Option []     ["list"]    (NoArg  (\  opts -> opts { mode = List}))             ""
  , Option ['e']  ["edit"]    (NoArg  (\  opts -> opts { mode = Edit}))             ""
  , Option []     ["dump"]    (NoArg  (\  opts -> opts { mode = Dump}))             "Dump database to stdout"
  , Option []     ["lock"]    (NoArg  (\  opts -> opts { mode = AcquireLock}))      "Acquire write lock for database"
  , Option []     ["unlock"]  (NoArg  (\  opts -> opts { mode = ReleaseLock}))      "Release write lock for database"

  , Option []     ["dbfile"]  (ReqArg (\s opts -> opts { databaseFile = s }) "FILE")  ""
  ]

defaultDatabaseFile :: IO String
defaultDatabaseFile = do
  home <- getEnv "HOME"
  return $ joinPath [home, ".pwsafe", "db"]

get :: [String] -> IO Options
get args = do
  let (opts_, files, errors) = getOpt Permute options args
  let opts__ = foldl (flip id) defaultOptions opts_
  opts <- case databaseFile opts__ of
    "" -> do
      db <- defaultDatabaseFile
      return opts__ {databaseFile = db}
    _  -> return opts__

  when ((not . null) errors)
    (tryHelp $ head errors)

  when ((not . null) files)
    (tryHelp $ printf "unrecognized option `%s'\n" $ head files)

  return opts

  where
    printAndExit :: String -> IO a
    printAndExit s = putStr s >> exitFailure

    tryHelp message = printAndExit $ "pwsafe: " ++ message
      ++ "Try `pwsafe --help' for more information.\n"

printHelp :: IO ()
printHelp = putStr $ usageInfo "Usage: pwsafe [OPTION]...\n" options
