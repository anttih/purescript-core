module Test.Effect where

import Prelude

foreign import data Effect :: Type -> Type

type role Effect representational

instance functorEffect :: Functor Effect where
  map = liftA1

instance applyEffect :: Apply Effect where
  apply = ap

instance applicativeEffect :: Applicative Effect where
  pure = pureE

foreign import pureE :: forall a. a -> Effect a

instance bindEffect :: Bind Effect where
  bind = bindE

instance monadEffect :: Monad Effect

foreign import bindE :: forall a b. Effect a -> (a -> Effect b) -> Effect b
