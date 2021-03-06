{-#LANGUAGE InstanceSigs #-}

-- Directly inspired from the "Effect Handlers in Scope" 2014 paper by Nicholas
-- Wu, Tom Schrijvers & Ralf Hinze.
--
module Main where

import EffectHandler    (allsolutions2, knapsack2) 
import DataALarteCarte  (eval, addExample, addExample',
                         addExample2, complexExample1, complexExample2,
                         pretty, distributeExample1, distributeExample2 )

data Backtr a =
  Return a |
  Fail     |
  (Backtr a) :| (Backtr a) deriving Show

instance Functor Backtr where
  fmap f (Return a) = Return (f a)
  fmap _ Fail = Fail
  fmap f (p :| q) = (fmap f p) :| (fmap f q)

instance Applicative Backtr where
  pure = Return
  (<*>) :: Backtr (a -> b) -> Backtr a -> Backtr b
  (<*>) (Fail)_    = Fail
  (<*>) f (p :| q) = (f <*> p) :| (f <*> q)

instance Monad Backtr where
  return :: a -> Backtr a
  return = Return
  (>>=) :: Backtr a -> (a -> Backtr b) -> Backtr b
  (>>=) Fail       _ = Fail
  (>>=) (Return a) r = r a
  (>>=) (p :| q)   r = (p >>= r) :| (q >>= r)


knapsack :: Int -> [Int] -> Backtr [Int]
knapsack w vs | w < 0 = Fail
              | w == 0 = return []
              | w > 0 = do v <- select vs
                           vs <- knapsack (w - v) vs
                           return (v:vs)
select :: [a] -> Backtr a
select = foldr (:|) Fail . map Return

-- Discover all solutions to the "knapsack problem"
allsolutions :: Backtr a -> [a]
allsolutions (Return a) = [a]
allsolutions Fail       = []
allsolutions (p :| q) = allsolutions p ++ allsolutions q

main :: IO ()
main = do
  putStrLn . show $ allsolutions (knapsack 3 [3,2,1])
  putStrLn . show $ allsolutions2 (knapsack2 3 [3,2,1])
  putStrLn . show $ eval addExample  -- straightforward, easy to read.
  putStrLn . show $ eval addExample'  -- straightforward, easy to read.
  putStrLn . show $ eval addExample2 -- insightful
  putStrLn . show $ eval complexExample1
  putStrLn . show $ eval complexExample2
  putStrLn . show $ pretty complexExample1
  putStrLn . show $ pretty complexExample2
  putStrLn . show $ distributeExample1
  putStrLn . show $ distributeExample2

