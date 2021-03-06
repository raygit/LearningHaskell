{-# LANGUAGE InstanceSigs #-}

module Chapter26_StateT where

newtype StateT s m a = StateT { runStateT :: s -> m (a ,s) }

-- This is slightly trickier than the previous ones because of the simple fact
-- that ((->), a) ∈ Functor.
--
-- That means there's already an implicit `fmap` i.e. (<$>)
--
-- Let's dissect it a little again what it exactly means and how im crafted the
-- expression.
--
-- g :: s -> m (a, s)
-- (g s) :: m (a, s) <-- m ∈ Functor
--
-- what i need to do is extract the 'a' from the tuple '(a,s)' embedded in the
-- Functor. This should reveal that you actually need a `fmap` | `<$>` but
-- after since fmapping on tuples actually operate on the RHS of the 2-tuple,
-- so i need to unpack and re-pack it back into the 2-tuple
--
-- (\pair -> (,) ((f . fst) pair) (snd pair)) :: (a,b)
--
-- allows me to do exactly that. Next, i `fmap` the above ↑ expression and
-- would give me a `m (a , b)` where b ∈ s.
--
--
instance Functor m => Functor (StateT s m) where
  fmap :: (a -> b) -> StateT s m a -> StateT s m b
  fmap f (StateT g) =
    StateT $ (\s -> fmap (\pair -> (,) ((f . fst) pair) (snd pair)) (g s))

--
-- Constructing this Applicative is slightly more complicated because the 'm'
-- is "embedded" in a function.
-- 
-- By declaring that m ∈ Applicative means that now i can conveniently add
-- `pure` into the body of the function like this :
--
-- (\s -> (a , s)) but the 'm' is missing and we need it!
--
-- Next, declare m ∈ Applicative and then i can invoke `pure`
--
-- (\s -> pure (a , s)) <--- Haskell knows that the 'pure' refers to the 'm'.
--
instance Monad m => Applicative (StateT s m) where
  pure :: a -> StateT s m a
  pure a = StateT $ (\s -> pure (a, s))

  (<*>) :: StateT s m (a -> b) -> StateT s m a -> StateT s m b
  (StateT f) <*> (StateT ma) =
    -- f :: s -> m ((a -> b), s)
    -- ma :: s -> m (a, s)
    StateT $
      (\s -> do
        ff <- (f s) -- ff :: ((a->b), s)
        gg <- (ma s) -- gg :: (a, s)
        return ((fst ff) (fst gg), s))

-- Write a monad instance for StateT
--
instance (Monad m) => Monad (StateT s m) where
  return :: a -> StateT s m a
  return = pure

  
  (>>=) :: StateT s m a -> (a -> StateT s m b) -> StateT s m b
  (StateT ma) >>= f = 
    StateT $ (\s -> do
      a <- ma s -- (ma s) :: m a, a :: (a ,s)
      -- (f (fst a)) :: StateT s m b
      -- runStateT (f (fst a)) :: s -> m (a, s)
      -- consuming 's' right after invoking runStateT gives `m (a , s)`
      (runStateT (f (fst a)) $ s) ) 




