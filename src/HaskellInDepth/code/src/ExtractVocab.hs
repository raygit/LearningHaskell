import Data.Char
import Data.List
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.Environment

type Entry = (T.Text, Int) -- one entry 
type Vocabulary = [Entry]


--
-- Run: cabal run -- texts/hamlet.txt
--
main = do
  args <- getArgs
  case args of 
    [fname] -> processTextFile fname
    _ -> putStrLn "Usage: vocab-builder filename"

extractVocab :: T.Text -> Vocabulary
extractVocab t = map buildEntry $ group $ sort ws
  where
    ws = map T.toCaseFold $ filter (not . T.null) $ map cleanWord $ T.words t
    buildEntry ws@(w:_) = (w, length ws)
    cleanWord = T.dropAround (not . isLetter)

printAllWords :: Vocabulary -> IO ()
printAllWords vocab = do
  putStrLn "All words: "
  TIO.putStrLn $ T.unlines $ map fst vocab


processTextFile :: FilePath -> IO ()
processTextFile fname = do
  text <- TIO.readFile fname
  let vocab = extractVocab text
  printAllWords vocab

