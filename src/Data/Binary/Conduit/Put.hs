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

module Data.Binary.Conduit.Put
  ( Encoding
  , startEncoding
  , encodingBytesWrote
  , encodingPut
  , PutC
  , ByteChunk
  , Put
  , runPutC
  , putC
  , putChunk
  , putChunkOr
  , runPut
  , bytesWrote
  , castPut
  ) where

#include <haskell>

import Data.Binary.Conduit.Put.PutC

-- | The shortening of 'PutM' for the most common use case.
type Put a = forall i m. Monad m => a -> PutM i m ()

-- | Run an encoder presented as a 'Put' monad.
-- Returns encoder result and produced bytes count.
runPut :: Monad m => PutM i m a -> ConduitM i S.ByteString m (a, Word64)
runPut !p = (\(!r, !s) -> (r, encodingBytesWrote s)) <$> runPutC (startEncoding 0) p
{-# INLINE runPut #-}

-- | Get the total number of bytes wrote to this point.
bytesWrote :: Monad m => PutM i m Word64
bytesWrote = putC $ \ !x -> return (encodingBytesWrote x, x)
{-# INLINE bytesWrote #-}

-- | Run the given 'S.PutM' monad from binary package
-- and convert result into 'Put'.
castPut :: (a -> S.Put) -> Put a
castPut !p = mapM_ putChunk . B.toChunks . S.runPut . p
{-# INLINE castPut #-}
