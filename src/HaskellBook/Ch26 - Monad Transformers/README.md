# Types you probably don't want to use

Not every type will necessarily be performant or make sense. ListT and
Writer/WriterT are examples of this.

## Why not use Writer or WriterT?

It's a bit too easy to get into a situation where Writer is either too lazy or
too strict for the problem you're solving, and then it will use more memory
than you would like. Writer can accumulate unevaluated thunks, causing memory
leaks. It's also inappropriate for logging long-running or ongoing programs due
to the fact that you cannot retrieve any of the logged values until the
computation is complete.

## Recovering an ordinary type from a transformer

I read the opening paragraph in the book on page 1022 where it reads:
"""
If you have a transformer variant of a type and want to use it as if it was the
non-transformer version, you need some `m` structure that doesn't really do
anything. 

"""

At first, I didn't understand what was meant by that paragraph but the following code (as
it were on page 1023) illustrates what was meant by that paragraph:
```haskell

runMaybeT $ (+1) <$> MaybeT (Identity (Just 1))
Identity { runIdentity = Just 2 }
runMaybeT $ (+1) <$> MaybeT (Identity Nothing)
Identity { runIdentity = Nothing }

```

The type that's being referred to is `Maybe a` that is now held by `Identity`;
which you can use in the non-transformer variant parts of your code.

The book goes along and makes the following statement:
```haskell
Given that, we can get Identity from IdentityT and so on in the following
manner:

type MyIdentity a = IdentityT Identity a
type Maybe      a = MaybeT Identity a
type Either e a   = EitherT e Identity a
type Reader r a   = ReaderT r Identity a
type State e a    = StateT s Identity a

This works fine for recovering the non-transformer varaint of each type as the
Identity type is acting as a bit of do-nothing structural paste for filling in
the gap.

```
which makes sense now.

# Let's talk about MonadTrans now 

We often want to lift functions into a larger context. We have been doing this
for a while with `Functor`, which lifts a function into a context (or,
alternatively, lifts the functions ovefr the context) and applies it to the
value inside. The facility to do this also undergirds Applicative, Functor,
Monad and Traversable. Howevr, fmap isn't always enough, so we have some
functions that are essentially `fmap` for different contexts:

```haskell

fmap :: Functor f => (a -> b) -> f a -> f b

liftA :: Applicative f => (a -> b) -> f a -> f b

liftM :: Monad m => (a -> r) -> m a -> m r

```

You might notice the latter two examples have lift in the function name. While
we have encouraged you not to get too excited about the meaning of function
names, in this case they do give you a clue of what they're doing. They are
lifting, just as `fmap` does, a function into some larger context. The
underlying structure of the bind function from Monad is also a lifting function
- `fmap` again! - composed with the crucial `join` function. 

In some cases, we want to talk about more or different structure than these
types permit. In other cases, we want something that does as much lifting as is
necessary to reach some (structurally) outermost position in a stack of monad
transformers. Monad transformers can be nested in order to compose various
effects into one monster function, but in order to manage those stacks, first,
we need to lift more.

# Monads do not commute 

Remember that monads in general do not commute, and you aren't guaranteed
something sensible for every possible combination of types. The kit we have for
constructing and using monad transformers is useful but is not a license to not
think!


The idea here is that we have to lift an Applicative `apply` over the outer
structure `f` to get the `g (a -> b)` into `g a -> g b` so that the 
Applicative instance for `f` can be leveraged. We can stretch this idea a bit
and use concrete types:

```haskell

innerMost:: [Maybe (Identity (a -> b))] -> [Maybe (Identity a -> Identity b)]
innerMost = (fmap . fmap)(<*>)

```

# Motivation

Monads provide a powerful to build computations with effects. Each of the
standard monads is specialized to do exactly one thing. In real code, we often
to be able to use several effects at once.

It would be ideal if we could somehow take the standard `State` monad and add
failure handling to it, without resorting to the wholesale construction of
custom monads by hand. The standard monads in the `mtl` library do not allow us
to combine thme. Instead, the library provides a set of monad transformers to
achieve the same result.


