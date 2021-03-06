{-# OPTIONS_GHC -fno-warn-orphans #-}
module Radicle.Lang.Internal.Arbitrary where

import           Protolude

import qualified Data.IntMap as IntMap
import qualified Data.Map as Map
import           Data.Scientific (Scientific)
import           Test.QuickCheck
import           Test.QuickCheck.Instances ()

import           Radicle
import qualified Radicle.Lang.Doc as Doc
import           Radicle.Lang.Identifier (isValidIdentFirst, isValidIdentRest)
import           Radicle.Lang.PrimFns (purePrimFns)

instance Arbitrary r => Arbitrary (Env r) where
    arbitrary = Env <$> arbitrary

instance Arbitrary Value where
    arbitrary = sized go
      where
        -- There's no literal syntax for dicts, only the 'dict' primop. If we
        -- generated them directly, we would generate something that can only
        -- be got at after an eval, and which doesn't really correspond to
        -- anything a user can write. So we don't generate dicts directly,
        -- instead requiring they go via the primop.
        freqs = [ (3, Atom <$> (arbitrary `suchThat` (\x -> not (isPrimop x || isNum x))))
                , (3, String <$> arbitrary)
                , (3, Boolean <$> arbitrary)
                , (3, Number <$> arbitrary)
                , (1, List <$> sizedList)
                , (6, PrimFn <$> elements (Map.keys $ getPrimFns prims))
                , (1, Lambda <$> lambdaArgs
                             <*> scale (`div` 3) arbitrary
                             <*> scale (`div` 3) arbitrary)
                ]
        go n | n == 0 = frequency $ first pred <$> freqs
             | otherwise = frequency freqs
        sizedList :: Arbitrary a => Gen [a]
        sizedList = sized $ \n -> do
            k <- choose (0, n)
            scale (`div` (k + 1)) $ vectorOf k arbitrary
        prims :: PrimFns Identity
        prims = purePrimFns
        isPrimop x = x `elem` Map.keys (getPrimFns prims)
        isNum x = isJust (readMaybe (toS $ fromIdent x) :: Maybe Scientific)
        lambdaArgs = oneof [ PosArgs <$> sizedList, VarArgs <$> arbitrary ]

instance Arbitrary UntaggedValue where
    arbitrary = untag <$> (arbitrary :: Gen Value)

instance Arbitrary Ident where
    arbitrary = ((:) <$> firstL <*> rest) `suchThatMap` (mkIdent . toS)
      where
        allChars = take 100 ['!' .. maxBound]
        firstL = elements $ filter isValidIdentFirst allChars
        rest = sized $ \n -> do
          k <- choose (0, n)
          vectorOf k . elements $ filter isValidIdentRest allChars

instance Arbitrary a => Arbitrary (Bindings a) where
    arbitrary = do
        refs <- arbitrary
        env <- arbitrary
        prims <- arbitrary
        pure $ Bindings env prims (IntMap.fromList $ zip [0..] refs)
            (length refs) mempty 0 mempty 0

instance Arbitrary a => Arbitrary (Doc.Docd a) where
    arbitrary = Doc.Docd Nothing <$> arbitrary
