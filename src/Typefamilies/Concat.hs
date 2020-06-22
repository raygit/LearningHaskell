{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE TypeSynonymInstances  #-}

import qualified Data.ByteString.Char8 as BS
import           Data.ByteString (ByteString)
import           Data.Monoid ((<>))
import qualified Data.Text as T
import           Data.Text (Text)

class Concat a b where
  type ConcatTy a b -- the declared type will replace this type synonym
  cat :: a -> b -> ConcatTy a b

instance Concat Text String where
  type ConcatTy Text String = Text
  cat x y = x <> (T.pack y)

instance Concat String Text where
  type ConcatTy String Text = Text
  cat x y = (T.pack x) <> y

instance Concat String ByteString where
  type ConcatTy String ByteString = String
  cat x y = x ++ (BS.unpack y)
  
main = print $ cat ("+Hello" :: String) (" +World!" :: ByteString)
-- main = print $ cat ("+Hello" :: String) (" +World!" :: Text)
-- main = print $ cat ("-Hello" :: Text) (" -World!" :: String)

