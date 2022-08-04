import dotenv
from pathlib import Path
from tweetvibe.utils import datatypes 
from tweetvibe.twitter import twitter
#from flask import App

env_file = Path(__file__).parent / ".env"
dotenv.load_dotenv(env_file)

#vibe = twitter.Twitter()
#replies = vibe.get_replies("https://twitter.com/toluogunlesi/status/1554943412100530177")
#if replies.status:

    #for reply in replies.data:

        #print(reply)

