--
-- Copyright 2017 Warlock <internalmike@gmail.com>
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

module Data.Binary.Conduit.Put.Spec
  ( tests
  ) where

import Control.Monad hiding (fail)
import Control.Monad.Error.Class
import Control.Monad.Fix
import Control.Monad.Trans.Class
import Data.Bits
import Data.Conduit
import qualified Data.Conduit.Combinators as N
import Test.HUnit.Base hiding (Label)
import Data.Binary.Conduit.Get
import Data.Binary.Conduit.Put

tests :: Test
tests = TestList
  [ TestCase testExample
  ]

putWithSize :: Monad m => PutM i m () -> PutM i m ()
putWithSize !p = void $ mfix $ \size -> do
  putWord64le size
  before <- bytesWrote
  p
  after <- bytesWrote
  return $ after - before

testPut1 :: Int -> Put
testPut1 n = do
  forM_ [1 .. n] putInthost

testExample :: Assertion
testExample = do
  runPut (putWithSize $ testPut1 3) $$ testResult
  where
  testResult = do
    (\x -> lift $ assertEqual "" (Right $ 3 * fromIntegral (finiteBitSize (0 :: Word))) x) =<< fst <$> runGet getWord64le
    (\x -> lift $ assertEqual "" (Right 1) x) =<< fst <$> runGet getWordhost
    (\x -> lift $ assertEqual "" (Right 2) x) =<< fst <$> runGet getWordhost
    (\x -> lift $ assertEqual "" (Right 3) x) =<< fst <$> runGet getWordhost
    (\x -> lift $ assertEqual "" (Right ()) x) =<< fst <$> runGet (ensureEof ())

ensureEof :: e -> Get e ()
ensureEof e = do
  eof <- N.nullE
  if eof then return () else throwError e
