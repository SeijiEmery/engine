module Main (main) where
import Graphics.UI.GLFW as GLFW
import Control.Monad
import Control.Conditional

enforce :: Bool -> String -> IO ()
enforce action msg = if action then return () else fail msg

run_glfw :: IO () -> IO ()
run_glfw body = init >> body >> teardown
    where
        init = do
            ok <- GLFW.init
            enforce ok "Failed to initialize GLFW window"
        teardown = do
            return ()

main :: IO ()
main = run_glfw $ do
    print "Hello world!"
