module Network.Ethereum.Web3.Types.Types where

import Prelude
import Control.Monad.Eff (kind Effect, Eff)
import Control.Monad.Eff.Class (class MonadEff)
import Control.Monad.Aff (Aff)
import Control.Monad.Error.Class (class MonadThrow)
import Control.Monad.Eff.Exception (Error, EXCEPTION, throwException)
import Control.Monad.Trans.Class (lift)
import Control.Monad.Reader.Trans (ReaderT, runReaderT)
import Control.Monad.Reader.Class (class MonadAsk)
import Data.Monoid (class Monoid)
import Data.Foreign.Class (class Decode, class Encode, encode, decode)
import Data.Foreign.NullOrUndefined (NullOrUndefined(..), unNullOrUndefined)
import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Data.Foreign.Generic (defaultOptions, genericDecode, genericEncode)
import Data.Lens.Lens (Lens', lens)
import Data.Maybe (Maybe(..))
import Data.String (stripPrefix,  Pattern(..))
import Data.String (length) as S

import Network.Ethereum.Web3.Types.BigNumber (BigNumber)

--------------------------------------------------------------------------------
-- * Signed Values
--------------------------------------------------------------------------------

data Sign = Pos | Neg

derive instance eqSign :: Eq Sign

data Signed a = Signed Sign a

instance showSigned :: Show a => Show (Signed a) where
  show (Signed s a) = s' <> show a
    where
      s' = case s of
        Pos -> ""
        Neg -> "-"

instance eqSigned :: Eq a => Eq (Signed a) where
  eq (Signed s a) (Signed s' a') = (s `eq` s') && (a `eq` a')

instance mapSigned :: Functor Signed where
  map f (Signed s a) = Signed s (f a)

asSigned :: forall a . a -> Signed a
asSigned a = Signed Pos a

--------------------------------------------------------------------------------
-- * HexString
--------------------------------------------------------------------------------

newtype HexString = HexString String

instance showHexString :: Show HexString where
  show (HexString hx) = "0x" <> hx

derive newtype instance hexStringEq :: Eq HexString

derive newtype instance semigpStringEq :: Semigroup HexString

derive newtype instance monoidStringEq :: Monoid HexString

instance decodeHexString :: Decode HexString where
  decode s = do
    str <- decode s
    case stripPrefix (Pattern "0x") str of
      Nothing -> pure <<< HexString $ str
      Just res -> pure <<< HexString $ res

instance encodeHexString :: Encode HexString where
  encode = encode <<< append "0x" <<< unHex

unHex :: HexString -> String
unHex (HexString hx) = hx

hexLength :: HexString -> Int
hexLength (HexString hx) = S.length hx

--------------------------------------------------------------------------------
-- * Addresses
--------------------------------------------------------------------------------

newtype Address = Address HexString

derive newtype instance addressShow :: Show Address

derive newtype instance addressEq :: Eq Address

derive newtype instance decodeAddress :: Decode Address

derive newtype instance encodeAddress :: Encode Address

--------------------------------------------------------------------------------
-- * Block
--------------------------------------------------------------------------------

data CallMode =
    Latest
  | Pending
  | Earliest
  | BlockNumber BigNumber

instance encodeCallMode :: Encode CallMode where
  encode cm = case cm of
    Latest -> encode "latest"
    Pending -> encode "pending"
    Earliest -> encode "earliest"
    BlockNumber n -> encode n

data Block
  = Block { difficulty :: BigNumber
          , extraData :: HexString
          , gasLimit :: BigNumber
          , gasUsed :: BigNumber
          , hash :: HexString
          , logsBloom :: HexString
          , miner :: HexString
          , mixHash :: HexString
          , nonce :: HexString
          , number :: BigNumber
          , parentHash :: HexString
          , receiptsRoot :: HexString
          , sha3Uncles :: HexString
          , size :: BigNumber
          , stateRoot :: HexString
          , timestamp :: BigNumber
          , totalDifficulty :: BigNumber
          , transactions :: Array HexString
          , transactionsRoot :: HexString
          , uncles :: Array HexString
          }

derive instance genericBlock :: Generic Block _

instance showBlock :: Show Block where
  show = genericShow

instance decodeBlock :: Decode Block where
  decode x = genericDecode (defaultOptions { unwrapSingleConstructors = true }) x

--------------------------------------------------------------------------------
-- * Transaction
--------------------------------------------------------------------------------

data Transaction =
  Transaction { hash :: HexString
              , nonce :: BigNumber
              , blockHash :: HexString
              , blockNumber :: BigNumber
              , transactionIndex :: BigNumber
              , from :: Address
              , to :: NullOrUndefined Address
              , value :: BigNumber
              , gas :: BigNumber
              , gasPrice :: BigNumber
              , input :: HexString
              }

derive instance genericTransaction :: Generic Transaction _

instance showTransaction :: Show Transaction where
  show = genericShow

instance decodeTransaction :: Decode Transaction where
  decode x = genericDecode (defaultOptions { unwrapSingleConstructors = true }) x

--------------------------------------------------------------------------------
-- * TransactionOptions
--------------------------------------------------------------------------------

data TransactionOptions =
  TransactionOptions { from :: NullOrUndefined Address
                     , to :: NullOrUndefined Address
                     , value :: NullOrUndefined BigNumber
                     , gas :: NullOrUndefined BigNumber
                     , gasPrice :: NullOrUndefined BigNumber
                     , data :: NullOrUndefined HexString
                     , nonce :: NullOrUndefined BigNumber
                     }

derive instance genericTransactionOptions :: Generic TransactionOptions _

instance showTransactionOptions :: Show TransactionOptions where
  show = genericShow

instance encodeTransactionOptions :: Encode TransactionOptions where
  encode = genericEncode (defaultOptions { unwrapSingleConstructors = true })

defaultTransactionOptions :: TransactionOptions
defaultTransactionOptions =
  TransactionOptions { from : NullOrUndefined Nothing
                     , to : NullOrUndefined Nothing
                     , value : NullOrUndefined Nothing
                     , gas : NullOrUndefined Nothing
                     , gasPrice : NullOrUndefined Nothing
                     , data : NullOrUndefined Nothing
                     , nonce : NullOrUndefined Nothing
                     }

-- * Lens Boilerplate
_from :: Lens' TransactionOptions (Maybe Address)
_from = lens (\(TransactionOptions txOpt) -> unNullOrUndefined $ txOpt.from)
          (\(TransactionOptions txOpts) addr -> TransactionOptions $ txOpts {from = NullOrUndefined addr})

_to :: Lens' TransactionOptions (Maybe Address)
_to = lens (\(TransactionOptions txOpt) -> unNullOrUndefined $ txOpt.to)
           (\(TransactionOptions txOpts) addr -> TransactionOptions $ txOpts {to = NullOrUndefined addr})

_data :: Lens' TransactionOptions (Maybe HexString)
_data = lens (\(TransactionOptions txOpt) -> unNullOrUndefined $ txOpt.data)
           (\(TransactionOptions txOpts) dat -> TransactionOptions $ txOpts {data = NullOrUndefined dat})

_value :: Lens' TransactionOptions (Maybe BigNumber)
_value = lens (\(TransactionOptions txOpt) -> unNullOrUndefined $ txOpt.value)
           (\(TransactionOptions txOpts) val -> TransactionOptions $ txOpts {value = NullOrUndefined val})

_gas :: Lens' TransactionOptions (Maybe BigNumber)
_gas = lens (\(TransactionOptions txOpt) -> unNullOrUndefined $ txOpt.gas)
           (\(TransactionOptions txOpts) g -> TransactionOptions $ txOpts {gas = NullOrUndefined g})

_gasPrice :: Lens' TransactionOptions (Maybe BigNumber)
_gasPrice = lens (\(TransactionOptions txOpt) -> unNullOrUndefined $ txOpt.gasPrice)
              (\(TransactionOptions txOpts) gp -> TransactionOptions $ txOpts {gasPrice = NullOrUndefined gp})

_nonce :: Lens' TransactionOptions (Maybe BigNumber)
_nonce = lens (\(TransactionOptions txOpt) -> unNullOrUndefined $ txOpt.nonce)
           (\(TransactionOptions txOpts) n -> TransactionOptions $ txOpts {nonce = NullOrUndefined n})
--------------------------------------------------------------------------------
-- | Web3M
--------------------------------------------------------------------------------

foreign import data Provider :: Type

-- | Synchronous Web3 Actions

foreign import data ETH :: Effect

newtype Web3M e a = Web3M (ReaderT Provider (Eff (eth :: ETH , exception :: EXCEPTION | e)) a)

derive newtype instance functorWeb3M :: Functor (Web3M e)

derive newtype instance applyWeb3M :: Apply (Web3M e)

derive newtype instance applicativeWeb3M :: Applicative (Web3M e)

derive newtype instance bindWeb3M :: Bind (Web3M e)

derive newtype instance monadWeb3M :: Monad (Web3M e)

derive newtype instance monadEffWeb3M :: MonadEff (eth :: ETH, exception :: EXCEPTION | e) (Web3M e)

derive newtype instance monadAskWeb3M :: MonadAsk Provider (Web3M e)

instance monadThrowWeb3M :: MonadThrow Error (Web3M e) where
    throwError = Web3M <<< lift <<< throwException

runWeb3M :: forall eff a . Provider -> Web3M eff a -> Eff (eth :: ETH , exception :: EXCEPTION | eff) a
runWeb3M p (Web3M action) = runReaderT action p

-- | Asynchronous Web3 Actions

newtype Web3MA e a = Web3MA (ReaderT Provider (Aff (eth :: ETH | e)) a)

derive newtype instance functorWeb3MA :: Functor (Web3MA e)

derive newtype instance applyWeb3MA :: Apply (Web3MA e)

derive newtype instance applicativeWeb3MA :: Applicative (Web3MA e)

derive newtype instance bindWeb3MA :: Bind (Web3MA e)

derive newtype instance monadWeb3MA :: Monad (Web3MA e)

derive newtype instance monadEffWeb3MA :: MonadEff (eth :: ETH | e) (Web3MA e)

derive newtype instance monadAskWeb3MA :: MonadAsk Provider (Web3MA e)

derive newtype instance monadThrowWeb3MA :: MonadThrow Error (Web3MA e)

runWeb3MA :: forall eff a . Provider -> Web3MA eff a -> Aff (eth :: ETH | eff) a
runWeb3MA p (Web3MA action) = runReaderT action p
