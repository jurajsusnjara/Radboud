module serialize3Start

/*
  Definitions for assignment 3 in AFP 2016
  Kind indexed gennerics
  Pieter Koopman, pieter@cs.ru.nl
  September 2016
*/

import StdEnv, StdMaybe

:: Write a :== a [String] -> [String]
:: Read a  :== [String] -> Maybe (a,[String])

class isUNIT a :: a -> Bool
instance isUNIT UNIT where
	isUNIT _ = True
instance isUNIT a where
	isUNIT _ = False

// use this as serialize0 for kind *
class serialize a where
  write :: a [String] -> [String]
  read  :: [String] -> Maybe (a,[String])

// ---
class serialize1 t where
	write1 :: (Write a) (t a) [String] -> [String]
	read1  :: (Read a) [String] -> Maybe (t a,[String])

class serialize2 t where
	write2 :: (Write a) (Write b) (t a b) [String] -> [String]
	read2  :: (Read a) (Read b) [String] -> Maybe (t a b, [String])

class serializeCONS a where
	writeCons :: (Write a) (CONS a) [String] -> [String]
	readCons  :: String (Read a) [String] -> Maybe (CONS a, [String])

instance serialize Bool where
  write b c = [toString b:c]
  read ["True":r] = Just (True,r)
  read ["False":r] = Just (False,r)
  read _ = Nothing

instance serialize Int where
  write i c = [toString i:c]
  read [s:r]
    # i = toInt s
    | s == toString i
      = Just (i,r)
      = Nothing
  read _ = Nothing

// ---
instance serialize1 [] where
	write1 wa l c = write2 (writeCons write) (writeCons (write2 wa (write1 wa))) (fromList l) c
	read1 ra l = case read2 (readCons NilString read) (readCons ConsString (read2 ra (read1 ra))) l of
		Just (g,m) = Just (toList g,m)
		_ = Nothing

instance serialize1 Bin where
	write1 wa b c = write2 (write1 write) (write1 (write2 (write1 wa) (write2 wa (write1 wa)))) (fromBin b) c
	read1 ra l = case read2 (read1 read) (read1 (read2 (read1 ra) (read2 ra (read1 ra)))) l of
		Just (g,m) = Just (toBin g,m)
		_ = Nothing

:: UNIT       = UNIT
:: EITHER a b = LEFT a | RIGHT b
:: PAIR   a b = PAIR a b
:: CONS   a   = CONS String a

// ---
instance serialize2 EITHER where
	write2 wa wb (LEFT a) c = wa a c
	write2 wa wb (RIGHT a) c = wb a c
	read2 ra rb l = case ra l of
		Just (a,m) = Just (LEFT a,m)
		_ = case rb l of
			Just(b,m) = Just (RIGHT b,m)
			_ = Nothing

instance serialize UNIT where
	write UNIT c = c
	read l = Just (UNIT,l)

instance serialize2 PAIR where
	write2 wa wb (PAIR a b) c = wa a (wb b c)
	read2 ra rb l = case ra l of
		Just (a,m) = case rb m of
			Just (b,n) = Just (PAIR a b,n)
			_ = Nothing
		_ = Nothing

instance serialize1 CONS where
	write1 wa (CONS s a) c = ["(",s:wa a [")":c]]
	read1 ra ["(",s:l] = case ra l of
		Just(a,[")":m]) = Just (CONS s a,m)
		_ = Nothing
	read1 _ _ = Nothing

instance serializeCONS UNIT where
	writeCons wa (CONS s a) c = [s:c]
	readCons n ra [s:l] | n == s
		= Just (CONS s UNIT,l)
	readCons _ _ _ = Nothing

instance serializeCONS a where
	writeCons wa (CONS s a) c = ["(",s," ":wa a [")":c]]
	readCons n ra ["(",s," ":l] | n == s
		= case ra l of
			Just (a,[")":m]) = Just (CONS s a,m)
			_ = Nothing
	readCons _ _ _ = Nothing

/*instance serializeCONS (PAIR a b) where
	writeCons wa (CONS s a) c = [s:wa a c]
	readCons n ra [s:l] | n == s = case ra l of
		Just(a,m) = case ra m of
			Just(b,x) = Just (CONS s (PAIR a b), x)
			_ = Nothing
		_ = Nothing
	readCons _ _ _ = Nothing
*/

instance serialize (EITHER a b) | serialize a & serialize b where
	write e c = write2 write write e c
	read l = read2 read read l

instance serialize (PAIR a b) | serialize a & serialize b where
	write (PAIR a b) c = write2 write write (PAIR a b) c
	read l = read2 read read l

instance serialize (CONS a) | serialize a where
	write (CONS s a) c = write1 write (CONS s a) c
	read l = read1 read l

:: ListG a :== EITHER (CONS UNIT) (CONS (PAIR a [a]))

fromList :: [a] -> ListG a
fromList []  = LEFT  (CONS NilString  UNIT)
fromList [a:x] = RIGHT (CONS ConsString (PAIR a x))

toList :: (ListG a) -> [a]
toList (LEFT  (CONS NilString  UNIT)) = []
toList (RIGHT (CONS ConsString (PAIR a x))) = [a:x]

NilString :== "Nil"
ConsString :== "Cons"

instance serialize [a] | serialize a where
	write a s = write1 write a s
	read s = read1 read s

// ---

:: Bin a = Leaf | Bin (Bin a) a (Bin a)

:: BinG a :== EITHER (CONS UNIT) (CONS (PAIR (Bin a) (PAIR a (Bin a))))

fromBin :: (Bin a) -> BinG a
fromBin Leaf = LEFT (CONS LeafString UNIT)
fromBin (Bin l a r) = RIGHT (CONS BinString (PAIR l (PAIR a r)))

toBin :: (BinG a) -> Bin a
toBin (LEFT (CONS _ UNIT)) = Leaf
toBin (RIGHT (CONS _ (PAIR l (PAIR a r)))) = Bin l a r

LeafString :== "Leaf"
BinString :== "Bin"

instance == (Bin a) | == a where
  (==) Leaf Leaf = True
  (==) (Bin l a r) (Bin k b s) = l == k && a == b && r == s
  (==) _ _ = False

instance serialize (Bin a) | serialize a where
	write a s = write1 write a s
	read s = read1 read s

// ---

:: Coin = Head | Tail
:: CoinG :== EITHER (CONS UNIT) (CONS UNIT)

fromCoin :: Coin -> CoinG
fromCoin Head = LEFT (CONS "Head" UNIT)
fromCoin Tail = RIGHT (CONS "Tail" UNIT)

toCoin :: CoinG -> Coin
toCoin (LEFT (CONS _ UNIT)) = Head
toCoin (RIGHT (CONS _ UNIT)) = Tail

instance == Coin where
  (==) Head Head = True
  (==) Tail Tail = True
  (==) _    _    = False

instance serialize Coin where
	write c s = write2 (write1 write) (write1 write) (fromCoin c) s
	read    l = case read2 (read1 read) (read1 read) l of
		Just (g,m) = Just (toCoin g,m)
		_ = Nothing

/*
	Define a special purpose version for this type that writes and reads
	the value (7,True) as ["(","7",",","True",")"]
*/
instance serialize2 (,) where
	write2 wa wb (a,b) c = ["(":wa a [",":wb b [")":c]]]
	read2 ra rb ["(":l] = case ra l of
		Just (a, [",":m]) = case rb m of
			Just (b, [")":n]) = Just ((a,b),n)
			_ = Nothing
		_ = Nothing
	read2 _ _ _ = Nothing

instance serialize (a,b) | serialize a & serialize b where
	write t c = write2 write write t c
	read l = read2 read read l

// ---
// output looks nice if compiled with "Basic Values Only" for console in project options
Start = 
  [test True
  ,test False
  ,test 0
  ,test 123
  ,test -36
  ,test [42]
  ,test [0..4]
  ,test [[True],[]]
  ,test (Bin Leaf True Leaf)
  ,test [Bin (Bin Leaf [1] Leaf) [2] (Bin Leaf [3] (Bin Leaf [4,5] Leaf))]
  ,test [Bin (Bin Leaf [1] Leaf) [2] (Bin Leaf [3] (Bin (Bin Leaf [4,5] Leaf) [6,7] (Bin Leaf [8,9] Leaf)))]
  ,test Head
  ,test Tail
  ,test (7,True)
  ,test (Head,(7,[Tail]))
  ,["End of the tests.\n"]
  ]

test :: a -> [String] | serialize, == a
test a = 
  (if (isJust r)
    (if (fst jr == a)
      (if (isEmpty (tl (snd jr)))
        ["Oke"]
        ["Not all input is consumed! ":snd jr])
      ["Wrong result: ":write (fst jr) []])
    ["read result is Nothing"]
  ) ++ [", write produces: ": s]
  where
    s = write a ["\n"]
    r = read s
    jr = fromJust r
