# Package

version       = "0.2.0"
author        = "C-NERD"
description   = "Web frontend for tweetvibe app"
license       = "MIT"
srcDir        = "tweetvibe_frontend"
binDir        = "static/js"
bin           = @["homepage"]
backend       = "js"

# Dependencies

requires "nim == 1.6.0", "karax#head"
