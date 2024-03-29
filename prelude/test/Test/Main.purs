module Test.Prelude.Main where

import Prelude
import Test.Effect (Effect)
import Data.HeytingAlgebra (ff, tt, implies)
import Data.Ord (abs)
import Test.Data.Generic.Rep (testGenericRep)
import Test.Utils (assert)

main :: Effect Unit
main = do
    -- testNumberShow show
    testOrderings
    testArray
    testOrdUtils
    testIntDivMod
    testIntDegree
    testRecordInstances
    testGenericRep

foreign import testNumberShow :: (Number -> String) -> Effect Unit

testOrd :: forall a. Ord a => Show a => a -> a -> Ordering -> Effect Unit
testOrd x y ord =
    assert
        ("(compare " <> show x <> " " <> show y <> " ) is not equal to " <> show ord)
        $ (compare x y) == ord

nan :: Number
nan = 0.0/0.0

plusInfinity :: Number
plusInfinity = 1.0/0.0

minusInfinity :: Number
minusInfinity = -1.0/0.0

testOrderings :: Effect Unit
testOrderings = do
    assert "NaN shouldn't be equal to itself" $ nan /= nan
    assert "NaN shouldn't be equal to itself" $ (compare nan nan) /= EQ
    testOrd 1.0    2.0 LT
    testOrd 2.0    1.0 GT
    testOrd 1.0    (-2.0) GT
    testOrd (-2.0) 1.0 LT
    testOrd minusInfinity plusInfinity LT
    testOrd minusInfinity 0.0 LT
    testOrd plusInfinity  0.0 GT
    testOrd plusInfinity  minusInfinity GT
    testOrd 1.0 nan GT
    testOrd nan 1.0 GT
    testOrd nan plusInfinity GT
    testOrd plusInfinity nan GT
    assert "1 > NaN should be false" $ (1.0 > nan) == false
    assert "1 < NaN should be false" $ (1.0 < nan) == false
    assert "NaN > 1 should be false" $ (nan > 1.0) == false
    assert "NaN < 1 should be false" $ (nan < 1.0) == false
    assert "NaN == 1 should be false" $ nan /= 1.0
    testOrd (1 / 0) 0 EQ
    testOrd (mod 1 0) 0 EQ
    testOrd 'a' 'b' LT
    testOrd 'b' 'A' GT
    testOrd "10" "0" GT
    testOrd "10" "2" LT
    testOrd true  true EQ
    testOrd false false EQ
    testOrd false true LT
    testOrd true  false GT
    testOrd ([] :: Array Int) [] EQ
    testOrd [1, 0]  [1] GT
    testOrd [1]     [1, 0] LT
    testOrd [1, 1]  [1, 0] GT
    testOrd [1, -1] [1, 0] LT

testArray :: Effect Unit
testArray = do
  assert "map empty array" $ ((+) 1 <$> []) == []
  assert "map non-empty array" $ ((+) 1 <$> [ 1, 2, 3 ]) == [ 2, 3, 4]

  assert "apply empty array" $ (pure ((+) 1) <*> []) == []
  assert "apply non-empty array" $ (pure ((+) 1) <*> [ 1 ]) == [ 2 ]
  assert "apply longer array" $ ([(+) 1, (+) 1] <*> [ 1, 2 ]) == [ 2, 3, 2, 3 ]

  assert "bind empty array" $ ([] >>= pure) == ([] :: Array Int)
  assert "bind non-empty array" $ ([ 1 ] >>= \x -> [ x, x + 1 ]) == ([ 1, 2 ] :: Array Int)
  assert "bind longer array" $ ([ 1, 2 ] >>= \x -> [ x, x + 1 ]) == ([ 1, 2, 2, 3 ] :: Array Int)

testOrdUtils :: Effect Unit
testOrdUtils = do
  assert "-5 clamped between 0 and 10 should be 0" $ clamp 0 10 (-5) == 0
  assert "5 clamped between 0 and 10 should be 5" $ clamp 0 10 5 == 5
  assert "15 clamped between 0 and 10 should be 10" $ clamp 0 10 15 == 10
  assert "-5 should not be between 0 and 10" $ between 0 10 (-5) == false
  assert "5 should be between 0 and 10" $ between 0 10 5 == true
  assert "15 should not be between 0 10" $ between 0 10 15 == false

testIntDivMod :: Effect Unit
testIntDivMod = do
  -- Check when dividend goes into divisor exactly
  go 8 2
  go (-8) 2
  go 8 (-2)
  go (-8) (-2)

  -- Check when dividend does not go into divisor exactly
  go 2 3
  go (-2) 3
  go 2 (-3)
  go (-2) (-3)

  where
  go a b =
    let
      q = a / b
      r = a `mod` b
      msg = show a <> " / " <> show b <> ": "
    in do
      assert (msg <> "Quotient/remainder law") $
        q * b + r == a
      assert (msg <> "Remainder should be between 0 and `abs b`, got: " <> show r) $
        0 <= r && r < abs b

testIntDegree :: Effect Unit
testIntDegree = do
    assert "degree returns absolute integers" $ degree (-4) == 4
    assert "degree returns absolute integers" $ degree 4 == 4
    -- `degree bot` overflows a fixnum since purescm does not do
    -- clamping or bounds checking on `Int`.
    -- let bot = bottom :: Int
    -- assert "degree returns absolute integers" $ degree bot >= 0
    -- assert "degree does not return out-of-bounds integers" $ degree bot <= top

testRecordInstances :: Effect Unit
testRecordInstances = do
  assert "Record equality" $ { a: 1 } == { a: 1 }
  assert "Record inequality" $ { a: 2 } /= { a: 1 }
  assert "Record show" $ show { a: 1 } == "{ a: 1 }"
  assert "Record +" $ ({ a: 1, b: 2.0 } + { a: 0, b: (-2.0) }) == { a: 1, b: 0.0 }
  assert "Record *" $ ({ a: 1, b: 2.0 } * { a: 0, b: (-2.0) }) == { a: 0, b: -4.0 }
  assert "Record one" $ one == { a: 1, b: 1.0 }
  assert "Record zero" $ zero == { a: 0, b: 0.0 }
  assert "Record sub" $ { a: 2, b: 2.0 } - { a: 1, b: 1.0 } == { a: 1, b: 1.0 }
  assert "Record append" $ { a: [], b: "T" } <> { a: [1], b: "OM" } == { a: [1], b: "TOM" }
  assert "Record mempty" $ mempty == { a: [] :: Array Int, b: "" }
  assert "Record ff" $ ff == { a: false, b: false }
  assert "Record tt" $ tt == { a: true, b: true }
  assert "Record not" $ not { a: true, b: false } == { a: false, b: true }
  assert "Record conj" $ conj
    { a: true, b: false, c: true, d: false }
    { a: true, b: true, c: false, d: false }
    == { a: true, b: false, c: false, d: false }
  assert "Record disj" $ disj
    { a: true, b: false, c: true, d: false }
    { a: true, b: true, c: false, d: false }
    == { a: true, b: true, c: true, d: false }
  assert "Record implies" $ implies
    { a: true, b: false, c: true, d: false }
    { a: true, b: true, c: false, d: false }
    == { a: true, b: true, c: false, d: true }
  testOrd { a: 0, b: "hello" } { a: 42, b: "hello" } LT
  testOrd { a: 42, b: "hello" } { a: 0, b: "hello" } GT
  testOrd { a: 42, b: "hello" } { a: 42, b: "hello" } EQ
  testOrd { a: 42, b: "hell" } { a: 42, b: "hello" } LT
  testOrd { a: 42, b: "hello" } { a: 42, b: "hell" } GT
  assert "Record bottom" $
    (bottom :: { a :: Boolean }).a
    == bottom
  assert "Record top" $
    (top :: { a :: Boolean }).a
    == top
