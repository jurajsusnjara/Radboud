module student

import StdEnv, StdMaybe, monad
/*
	Pieter Koopman, pieter@cs.ru.nl
	Advanced Programming, week 4, 2016
*/

// ---- an IO monad with maybe results --- //

:: *State = {w :: *World, c :: *Maybe *File}
:: IO a = IO (State -> *(Maybe a, State))

open :: State -> State
open {w, c=Nothing}
	# (console, w) = stdio w
	= {w = w, c = Just console}
open s = s

close :: State -> State
close { w, c=Just f} = { w = snd (fclose f w), c = Nothing}
close s = s

unIO :: (IO a) -> State -> *(Maybe a, State)
unIO (IO f) = f

// ---- reading from console --- //

class read a :: IO a

instance read String where
	read = IO r where
		r s 
		#! {w,c=Just c} = open s
		   (line, c) = freadline c
		   s = rmNL line
		| size s > 0
			= (Just s,{w = w, c = Just c})
			#! c = c <<< "String must be not empty "
			   (line, c) = freadline c
			   s = rmNL line
			| size s > 0
				= (Just s,  {w = w, c = Just c})
				= (Nothing, {w = w, c = Just c})

instance read Int where
	read = IO r where
		r s
		#! {w,c=Just c} = open s
		   (b,i, c) = freadi c
		| b
			= (Just i, {w = w, c = Just c})
			#! c = c <<< "An integer please "
			   (b,i, c) = freadi c
			| b
				= (Just i,  {w = w, c = Just c})
				= (Nothing, {w = w, c = Just c})

write :: String -> IO String
write mess = IO w where
	w s
	#! {w,c=Just c} = open s
	= (Just mess,{w=w,c=Just (c <<< mess)})

// ---- make IO a monad --- //

instance Functor IO where
	fmap f (IO g)
		= IO \s.case g s of
					(Just a, s) = (Just (f a),s)
					(Nothing,s) = (Nothing  , s)

instance Applicative IO where
  pure a = IO \s.(Just a, s)
  (<*>) (IO f) (IO g)
   = IO \s.case f s of
        (Just f,s) = case g s of
  					(Just a,s) = (Just (f a),s)
  					(n,     s) = (Nothing, s)
        (n,     s) = (Nothing, s)

instance Monad IO where
	bind (IO f) g
	 = IO \s.case f s of
	 	(Just a, s) = unIO (g a) s
	 	(n,      s) = (Nothing, s)

instance fail IO where fail = IO \s.(Nothing,s)

// ---- reading a student record --- //

Start w = unIO f2 {w=w,c=Nothing}

:: Student =
  { fname :: String
  , lname :: String
  , snum  :: Int
  }

f0 :: *World -> (Student, *World)
f0 world = ({fname = rmNL fname, lname = rmNL lname, snum = snum}, world2) where
	 (console1, world1) = stdio world
	 console2 = console1 <<< "Your first name please: "
	 (fname,console3) = freadline console2
	 console4 = console3 <<< "Your last name please: "
	 (lname,console5) = freadline console4
	 console6 = console5 <<< "Your student nmber please: "
	 (b1,snum,console7) = freadi console6
	 (b2, world2) = fclose console7 world1

f1 :: *World -> (Student, *World)
f1 world
  #! (console, world) = stdio world
     console = console <<< "Your first name please: "
     (fname,console) = freadline console
     console = console <<< "Your last name please: "
     (lname,console) = freadline console
     console = console <<< "Your student nmber please: "
     (b1,snum,console) = freadi console
     (b2, world) = fclose console world
  = ({fname = rmNL fname, lname = rmNL lname, snum = snum}, world)

f2 :: IO Student
f2 
	=          write "Your first name please: "
	>>| read
	>>= \fname.write "Your last name please: "
	>>| read
	>>= \lname.write "Your student nmber please: "
	>>| read
	>>= \snum. rtrn {fname = rmNL fname, lname = rmNL lname, snum = snum}
  			  

rmNL :: String -> String
rmNL string
  # len = size string
  | len > 0 && string.[len-1] == '\n'
    = string % (0, len - 2)
    = string

