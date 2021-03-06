{-# LANGUAGE InstanceSigs #-}

module Chapter_27 where

-- Technically, Haskell is only obligated to be non-strict, not lazy. A truly
-- lazy language memoizes, or holds in memory, the results of all the functions
-- it does evaluate, and outside of toy programs, this tends to use
-- unacceptably large amounts of memory.
--
-- Implementations of Haskell, such as GHC Haskell, are only obligated to be
-- non-strict s.t. they have the same behavior w.r.t bottom; they are not
-- required to take a particular approach to how the program executes or how
-- efficiently it does so.
--
--

-- Prelude> :t fst
-- fst :: (a, b) -> a
-- Prelude> fst (1, undefined)
-- 1
-- Prelude> snd (1, undefined)
-- *** Exception: Prelude.undefined
-- CallStack (from HasCallStack):
  -- error, called at libraries/base/GHC/Err.hs:79:14 in base:GHC.Err
  -- undefined, called at <interactive>:3:9 in interactive:Ghci2
-- Prelude>
-- 
-- Prelude> snd (undefined, 2)
-- 2

possiblyKaboom = \f -> f fst snd (42, undefined)

true :: a -> a -> a
true = \a -> (\b -> a)

false :: a -> a -> a
false = \a -> (\b -> b)

-- let's dissect the function application `possiblyKaboom true` which gives 42, actually.
-- (\f -> f fst snd (42, undefined)) (\a -> (\b -> a))
-- (\a -> (\b -> a)) fst snd (42, undefined)
-- (\b -> fst) snd (42, undefined)
-- fst (42, undefined) 
-- 42 !!!
--
-- Another example of the function, is written here which does exactly the same
-- thing as 'possiblyKaboom'. A little writeup is in order here. The bottom is
-- inside a tuple, and the tuple is bound inside of a lambda that cases on a
-- boolean value and returns either the first or second of element of the
-- tuple. Since we start evaluating from the outside, as long as this function
-- is only ever applied to True, that bottom will never cause a problem.
-- However, at the risk of starting the obvious, we do not encourage you to
-- write programs with bottoms lying around willy-nilly.
--
-- When we say evaluation works outside in, we are talking about evaluatig a
-- series of nested expressions, and not only are we starting from the outside
-- and working in, but we are also only evaluating some of the expressions some
-- of the time. In haskell, we evaluate expressions when we need them rather
-- than when they are first referred to or constructed. This is one of the ways
-- in which non-strictness makes haskell programs expressive - we can refer to
-- values before we have done the work to create them.
-- 
possiblyKaboom' b =
  case b of
      True -> fst tup
      False -> snd tup
      where tup = (42, undefined)
            
-- The function, hypo, illustrates the classical problem of non-strict
-- evaluation. For a strict language, the following code is going to be a
-- problem. A strict language cannot evaluate `hypo` successfully unless the x
-- isn't bottom. This is because strict languages will force the bottom before
-- binding x. A strict language is evaluating each binding as it comes into
-- scope, not when a binding is used.
--
-- 
hypo :: IO ()
hypo = do
  let x :: Int
      x = undefined
  s <- getLine
  case s of 
    "hi" -> print x
    _    -> putStrLn "hello"
    
-- The idea is that evaluation is driven by demand, not by construction. We
-- don't get the exception unless we are forcing evaluation of 'x' outside in.
--
--


hypo' :: IO ()
hypo' = do
  let x :: Integer
      x = undefined
  s <- getLine
  case x `seq` s of 
      "hi" -> print x
      _    -> putStrLn "hello"

--
-- seq :: Eval a => a -> b -> b
--
-- Eval is short for "evaluation for weak head normal form", and it provided a
-- method for forcing evaluation. Instances were provided for all the types in
-- `base`. It was elided in part so you could use `seq` in your code without
-- churning your polymorphic type variables and forcing a bunch of changes.
-- W.r.t bottom, seq is defined as behaving in the following manner:
--
-- seq bottom b = bottom
-- seq anythingbutbottom b = b
--
-- Evaluation in Haskell is demand driven, we cannot guarantee that something
-- will ever be evaluated period. Instead we have to create links between nodes
-- in the graph of expressions where forcing one expression will force yet
-- another expression.
--
{-
  Another way to understand what is meant by "forcing the bottom" can probably be understood as follows:
  let {x = undefined, y = 2} in seq x y  <--- throws an exception because to get 'y', ghc will eval 'x'
  let {x = undefined, y = 2, z = (x `seq` y `seq` 10, 11)} in snd z <--- DOES not throw an error because 'snd z' does not eval the first element of the pair but if you changed the expression to:
  let {x = undefined, y = 2, z = (x `seq` y `seq` 10, 11)} in fst z <--- throws an exception because to eval the first element
  of the pair, means it has to eval "x `seq` y `seq` 10" which triggers the evaluation of 'x' eventually which is undefined.
-}


-- This returns 11 and why? The information around `seq` infixr 0
-- The expression below is the same as...
--
-- snd $ (seq undefined seq 2 10, 11)
--
notGonnaHappenBru :: Int
notGonnaHappenBru = 
  let x = undefined
      y = 2
      z = (x `seq` y `seq` 10, 11)
  in snd z

hypo'' :: IO ()
hypo'' = do
  let x :: Integer
      x = undefined
  s <- seq x getLine  -- forced the evaluation of 'x'
  case s of 
    "hi" -> print x
    _ -> putStrLn "hello"

-- Lazy patterns
-- these kinds of patterns are irrefutable.
--
strictPattern :: (a, b) -> String
strictPattern (a ,b) = const "Cousin it" a

lazyPattern :: (a, b) -> String
lazyPattern ~(a,b) = const "Cousin it" a

-- the tilde (i.e. ~) is how one makes a pattern match lazy. A caveat is that
-- since it makes the pattern irrefutable, you cannot use it to discriminate
-- cases of a sum - it's useful for unpackig products that might not get used.
--

{-
  
  seq and weak head normal form

  What seq does is evaluate your expression up to weak head normal form. We have discussed it before but if you like a deeper 
  investigation and contrast of weak head normal form and normal form, Simon Marlow's book has a good section which explains
  what is meant. In a nutshell, WHNF evaluation means it stops at the first data constructor or lambda.

-}
