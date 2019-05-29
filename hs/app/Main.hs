module Main (main) where
import Graphics.UI.GLFW as GLFW
import Control.Monad
import Control.Conditional
import Data.Maybe

enforce :: String -> Bool -> IO ()
enforce msg action = if action then return () else fail msg

enforceM :: String -> (IO Bool) -> IO ()
enforceM msg action = action >>= (enforce msg)

data WindowParams = WindowParams
    { width :: Int
    , height :: Int
    , title :: String
    }

makeWindow :: WindowParams -> IO GLFW.Window
makeWindow params = window >>= getAndEnforceExists
    where
        window = GLFW.createWindow (width params) (height params) (title params) monitor parent_window
        monitor = Nothing
        parent_window = Nothing
        getAndEnforceExists :: Maybe GLFW.Window -> IO GLFW.Window
        getAndEnforceExists (Just window) = return window
        getAndEnforceExists Nothing = fail $ "Failed to create window '" ++ (title params) ++ "'"

runGLFW :: WindowParams -> IO () -> IO ()
runGLFW wparams body = init >> body >> teardown
    where
        init = do
            enforceM "Failed to initialize glfw window" GLFW.init
            window <- makeWindow wparams
            return ()

        teardown = do
            return ()

main :: IO ()
main = runGLFW window body
    where
        window = WindowParams { 
            width = 1000, height = 800, 
            title = "test" }
        body :: IO ()
        body = do
            print "Hello world!"
