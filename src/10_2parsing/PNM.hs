
import qualified Data.ByteString.Lazy.Char8 as L8
import qualified Data.ByteString.Lazy as L
import Data.Char (isSpace)
import Data.Int
import Data.Word (Word8)

data Greymap = Greymap {
greyWidth :: Int,
greyHeight :: Int,
greyMax :: Int, 
greyData :: L.ByteString 
                       } deriving (Eq)


instance Show Greymap where
  show (Greymap w h m _) = "Greymap" ++ show w ++ "x" ++ show h ++ " " ++ show m

-- the function (>>?) is defined as an operator so that we can use it to chain
-- functions together. No fixity declaration was done and hence it defaults to
-- infixl 9 (left-associative, strongest operator precedence). That is to say 
-- a >>? b >>? c is the same as ((a >>? b) >>? c).
--
(>>?) :: Maybe a -> (a -> Maybe b) -> Maybe b
Nothing >>? _ = Nothing
Just v >>? f = f v

data ParseState = ParseState {
string :: L.ByteString,
offset :: Int64 
                             } deriving (Show)

simpleParse :: ParseState -> (a, ParseState) -- this is a precursor to the State Monad
simpleParse = undefined 

betterParse :: ParseState -> Either String (a, ParseState)
betterParse = undefined 

newtype Parse a = Parse {
runParse :: ParseState -> Either String (a, ParseState) 
                        } 

identity :: a -> Parse a
identity a = Parse(\s -> Right(a, s))

parse :: Parse a -> L.ByteString -> Either String a
parse parser initState = 
  case runParse parser (ParseState initState  0) of
      Left err -> Left err
      Right (result, _) -> Right result


{- 
    Let's see how this can be applied.
    let before = ParseState (L8.packk "hello") 0
    let after = modifyOffset before 9 

    It's a lot like how case-classes in Scala work when you 
    are copying from 1 case class to another.
    -}
modifyOffset :: ParseState -> Int64 -> ParseState
modifyOffset initState newOffset = initState { offset = newOffset }


getState :: Parse ParseState
getState = Parse (\s -> Right(s, s))

putState :: ParseState -> Parse()
putState s = Parse (\_ -> Right((), s))

bail :: String -> Parse a
bail err = Parse $ \s -> Left $ "byte offset " ++ show (offset s) ++ ": " ++ err

parseByte :: Parse Word8
parseByte = 
  getState ==> \initState -> 
    case L.uncons (string initState) of 
        Nothing -> 
          bail "no more input"
        Just (byte, remainder) -> 
          putState newState ==> \_ ->
            identity byte
              where newState = initState { string = remainder, offset = newOffset } 
                    newOffset = offset initState + 1


(==>) :: Parse a -> (a -> Parse b) -> Parse b
(==>) firstParser secondParser = Parse chainedParser
  where chainedParser initState = 
          case runParse firstParser initState of
              Left errMessage -> Left errMessage
              Right (firstResult, newState) -> runParse (secondParser firstResult) newState
