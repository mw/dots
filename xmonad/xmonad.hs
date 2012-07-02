import XMonad
import XMonad.Actions.GridSelect
import XMonad.Layout.DwmStyle
import XMonad.Layout.TwoPane
import XMonad.Config.Gnome
import XMonad.Util.EZConfig
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Prompt
import XMonad.Prompt.Theme

import qualified Data.Map as M

main = xmonad $ gnomeConfig
    { terminal = "urxvtcd"
    , borderWidth = 1
    , normalBorderColor = "black"
    , focusedBorderColor = "white"
    , manageHook = manageHook gnomeConfig <+> (isFullscreen --> doFullFloat)
        <+> (className =? "Do" --> doIgnore)
    , keys = newKeys
    , layoutHook = (avoidStruts . dwmStyle shrinkText defaultTheme) $ myLayoutHook
    }

newKeys x = M.union (keys defaultConfig x) (M.fromList (myKeys x))
myKeys conf@(XConfig {XMonad.modMask = modm}) =
    [ ((modm, xK_g), goToSelected defaultGSConfig) 
    , ((0, 0x1008ff17), spawn "mpc next")
    , ((0, 0x1008ff16), spawn "mpc prev")
    , ((0, 0x1008ff14), spawn "mpc toggle")
    , ((modm .|. controlMask, xK_t), themePrompt defaultXPConfig)
    ]

myLayoutHook = Tall 1 (3/100) (1/2) ||| Full ||| TwoPane (3/100) (1/2)
