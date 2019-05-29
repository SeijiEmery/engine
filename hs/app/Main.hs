module Main (main) where
import Graphics.UI.GLFW as GLFW
import Control.Monad
import Control.Conditional
import Data.Maybe
import Data.Default

enforce :: String -> Bool -> IO ()
enforce msg action = if action then return () else fail msg

enforceM :: String -> (IO Bool) -> IO ()
enforceM msg action = action >>= (enforce msg)

data WindowParams = WindowParams
    { width  :: Int
    , height :: Int
    , title :: String }

instance Default WindowParams where
    def = WindowParams { width = 800, height = 600, title = "" }

or_default :: Default a => Maybe a -> a
or_default (Just x) = x
or_default Nothing = def

makeWindow :: Maybe WindowParams -> IO GLFW.Window
makeWindow wparams = window >>= getAndEnforceExists
    where
        params = or_default wparams
        window = GLFW.createWindow (width params) (height params) (title params) monitor parent_window
        monitor = Nothing
        parent_window = Nothing
        getAndEnforceExists :: Maybe GLFW.Window -> IO GLFW.Window
        getAndEnforceExists (Just window) = return window
        getAndEnforceExists Nothing = fail $ "Failed to create window '" ++ (title params) ++ "'"

runGLFW :: Maybe WindowParams -> IO () -> IO ()
runGLFW wparams body = init >> body >> teardown
    where
        init = do
            enforceM "Failed to initialize glfw window" GLFW.init
            window <- makeWindow wparams
            return ()

        teardown = do
            return ()

main :: IO ()
main = runGLFW Nothing body
    where
        body :: IO ()
        body = do
            print "Hello world!"
