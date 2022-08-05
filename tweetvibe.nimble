# Package

version       = "0.1.0"
author        = "C-NERD"
description   = "Web frontend for tweetvibe app"
license       = "MIT"
srcDir        = "tweetvibe_frontend"
binDir        = "public/js"
bin           = @["homepage"]
backend       = "js"

# Dependencies

requires "nim >= 1.4.0", "karax == 1.2.1"
