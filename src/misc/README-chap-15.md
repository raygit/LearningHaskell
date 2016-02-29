# Monoid

A monoid is a binary associative operatio with an identity.
In plain english, a monoid is a function that takes two arguments
and follows two laws: associativity and identity. Associativity
means the arguments can be regrouped (or reparenthesized or reassociated)
in different orders and give the same result, as in addition.

Identity means there exist some value such that when we pass it as input to 
our function, the operation is rendered moot and the other value is returned
such as when we add zero or multiply by one. Monoid is the typeclass that
generalizes these laws across types.

```haskell
> :browse Data.Monoid
(<>) :: Monoid m => m -> m -> m
newtype All = All {getAll :: Bool}
type role Alt representational nominal
newtype Alt (f :: k -> *) (a :: k) = Alt {getAlt :: f a}
newtype Any = Any {getAny :: Bool}
newtype Dual a = Dual {getDual :: a}
newtype Endo a = Endo {appEndo :: a -> a}
newtype First a = First {getFirst :: Maybe a}
newtype Last a = Last {getLast :: Maybe a}
newtype Product a = Product {getProduct :: a}
newtype Sum a = Sum {getSum :: a}
class Monoid a where
  mempty :: a
  mappend :: a -> a -> a
  mconcat :: [a] -> a
```

and you can do things like this:

```haskell

> mconcat [(Product 2), (Product 45)]
Product {getProduct = 90}
> mconcat [Just(Product 2), Just(Product 45)]
Just (Product {getProduct = 90})

> mappend (Just(Product 2)) (Just(Product 45))
Just (Product {getProduct = 90})

> mempty :: Maybe (Sum Integer)
Nothing

> foldr mappend mempty ([2,4,5]::[Product Int])
Product { getProduct = 40 }

> foldr mappend mempty ["blah", "blah"]
"blahblah"

```

## Why Integer doesn't have a Monoid

The type `Integer` does not have a `Monoid` instance. None of the
numeric types do. Yet it's clear that numbers have monoidal operations 
so what is up with that Haskell?


While in mathematics, the monoid of numbers is summation, there's
 not a clear reason why it cannot be multiplication. Both operations
are monoidal (binary, associative and having an identity value) but 
each type should only have one unique instance for a given typeclass, not 
two (one instance for a sum, one for a product)

# Why you might use newtype

- Signal intent: using `newtype` makes it clear that you only intend for
  it to be wrapper for the underlying type. The newtype cannot eventually
  grow into a more complicated sum or product type, while a normal
  datatype can.

- Improve type safety: avoid mixing up many values of the same representation
  such as `Text` and `Integer`.

- Add different typeclass instances to a type that is otherwise
  unchanged representationally.

# Laws 

Laws dictates what constitutes a valid instance or concrete instance of 
the algebra or set of operations we are working with. We care about the laws a 
Monoid must adhere to because mathematicians care about the laws. That matters
because mathematicians often want the same things programmers
want ! A proof that is inelegant, a proof term that doesn't compose well
or that cannot be understood is not very good or useful to a mathematician.

`Monoid` instances must abide by the following laws:

```haskell
mappend mempty x = x

mappend x mempty = x

mappend x (mappend y z) = mappend (mappend x y) z

mconcat = foldr mappend mempty
```
