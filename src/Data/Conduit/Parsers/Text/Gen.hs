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

-- | Despite binary's 'S.Put' is fully-functional construction (unlike 'S.Get'),
-- we decided to provide this module for symmetry with 'Data.Binary.Conduit.Get'.

module Data.Conduit.Parsers.Text.Gen
  ( PutM
  , TextGen
  , runTextGen
  , genText
  , genLazyText
  , genShow
  , genDigit
  , genHexDigit
  , genHexByte
  ) where

import Data.Bits
import Data.Char
import Data.Conduit
import qualified Data.Text as S (Text)
import qualified Data.Text as ST hiding (Text, head, last, tail, init)
import Data.Text.Lazy (Text)
import qualified Data.Text.Lazy as T hiding (Text, head, last, tail, init)
import Data.Word
import Data.Conduit.Parsers.PutS

class (EncodingState s, EncodingToken s ~ ()) => DefaultTextGenState s where

instance (EncodingState s, EncodingToken s ~ ()) => DefaultTextGenState s where

-- | The shortening of 'PutM' for the most common use case.
type TextGen = forall s i m. (DefaultTextGenState s, Monad m) => PutM s i S.Text m ()

-- | Run an encoder presented as a 'Put' monad.
-- Returns 'Producer'.
runTextGen :: PutM VoidEncodingState i o m () -> ConduitM i o m ()
runTextGen !p = runEncoding $ snd $ runPutS p $ startEncoding VoidEncodingState
{-# INLINE runTextGen #-}

genText :: S.Text -> TextGen
genText !x = putS $ \ !t -> ((), encoded (yield x, ()) t)
{-# INLINE genText #-}

genLazyText :: Text -> TextGen
genLazyText !x = putS $ \ !t -> ((), encoded (mapM_ yield $ T.toChunks x, ()) t)
{-# INLINE genLazyText #-}

genShow :: Show a => a -> TextGen
genShow = genLazyText . T.pack . show
{-# INLINE genShow #-}

genDigit :: Integral a => a -> TextGen
genDigit = genText . ST.singleton . chr . (ord '0' +) . fromIntegral
{-# INLINE genDigit #-}

genHexDigit :: Integral a => Bool -> a -> TextGen
genHexDigit !uppercase =
  genText . ST.singleton . chr . toCharCode . fromIntegral
  where
  toCharCode !x
    | x < 10 = ord '0' + x
    | otherwise = (if uppercase then ord 'A' else ord 'a') + x
{-# INLINE genHexDigit #-}

genHexByte :: Bool -> Word8 -> TextGen
genHexByte !uppercase !c = do
  genHexDigit uppercase $ c `shiftR` 4
  genHexDigit uppercase $ c .&. 0xF
{-# INLINE genHexByte #-}
