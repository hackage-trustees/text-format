{-# LANGUAGE BangPatterns, OverloadedStrings #-}

--module Main (main) where

import Control.Monad
import Data.Char
import Data.Bits
import System.Environment
import Data.Text.Format as T
import Data.Time.Clock
import Data.Text (Text)
import qualified Data.Text as T
import Data.Text.Lazy.Encoding
import qualified Data.ByteString.Lazy as L
import System.IO

counting :: Int -> (Int -> () -> IO ()) -> IO ()
counting count act = loop 0
    where loop !i | i < count = act i () >> loop (i+1)
                  | otherwise = return ()
{-# NOINLINE counting #-}
  
idle count = counting count $ \_ x -> return ()

plain count = counting count $ \_ x -> do
  L.putStr . encodeUtf8 $ "hi mom\n"

unit count = counting count $ \_ x -> do
  let t = T.format "hi mom\n" x
  L.putStr . encodeUtf8 $ t

int count = counting count $ \i x -> do
  let t = T.format "hi mom {}\n" (Only i)
  L.putStr . encodeUtf8 $ t

bigint count = counting count $ \i x -> do
  let t = T.format "hi mom {}\n" (Only (i+100000))
  L.putStr . encodeUtf8 $ t

double count = counting count $ \i x -> do
  let t = T.format "hi mom {}\n" (Only (fromIntegral i * dpi))
  L.putStr . encodeUtf8 $ t

p6 count = counting count $ \i x -> do
  let t = T.format "hi mom {}\n" (Only (prec 6 $! fromIntegral i * dpi))
  L.putStr . encodeUtf8 $ t

arg :: Int -> Text
arg i = "fnord" `T.append` (T.take (i `mod` 6) "foobar")
{-# NOINLINE arg #-}

one count = counting count $ \i x -> do
  let k = arg i
  let t = {-# SCC "one/format" #-} T.format "hi mom {}\n" (Only k)
  L.putStr . encodeUtf8 $ t

two count = counting count $ \i x -> do
  let k = arg i
  let t = {-# SCC "two/format" #-} T.format "hi mom {} {}\n" (k,k)
  L.putStr . encodeUtf8 $ t

three count = counting count $ \i x -> do
  let k = arg i
  let t = {-# SCC "three/format" #-} T.format "hi mom {} {} {}\n" (k,k,k)
  L.putStr . encodeUtf8 $ t

four count = counting count $ \i x -> do
  let k = arg i
  let t = {-# SCC "four/format" #-} T.format "hi mom {} {} {} {}\n" (k,k,k,k)
  L.putStr . encodeUtf8 $ t

five count = counting count $ \i x -> do
  let k = arg i
  let t = {-# SCC "five/format" #-} T.format "hi mom {} {} {} {} {}\n" (k,k,k,k,k)
  L.putStr . encodeUtf8 $ t

dpi :: Double
dpi = pi

main = do
  args <- getArgs
  let count = case args of
                (_:x:_) -> read x
                _       -> 100000
  let bm = case args of
             ("idle":_)   -> idle
             ("plain":_)  -> plain
             ("unit":_)   -> unit
             ("double":_) -> double
             ("p6":_) -> p6
             ("int":_)    -> int
             ("bigint":_) -> bigint
             ("one":_)    -> one
             ("two":_)    -> two
             ("three":_)  -> three
             ("four":_)   -> four
             ("five":_)   -> five
             _            -> error "wut?"
  start <- getCurrentTime
  bm count
  elapsed <- (`diffUTCTime` start) `fmap` getCurrentTime
  T.hprint stderr "{} iterations in {} secs ({} thousand/sec)\n"
       (count, elapsed,
        fromRational (toRational count / toRational elapsed / 1e3) :: Double)
