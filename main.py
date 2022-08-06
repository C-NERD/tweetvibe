import dotenv
from pathlib import Path
from tweetvibe.utils import datatypes, utils
from tweetvibe.twitter import twitter
from tweetvibe.detectvibe import detectvibe
from tweetvibe.database import database
from flask import Flask, request, make_response, render_template
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

env_file = Path(__file__).parent / ".env"
dotenv.load_dotenv(env_file)

def server():

    db = database.Database()
    app = Flask(__name__)
    #app.config.from_object("config.Production")
    app.config.from_object("config.Development")

    limiter = Limiter(app, key_func = get_remote_address)

    @app.route("/")
    async def home():
        
        context = {
            "path" : "/public/",
            "file" : "homepage",
            "description" : "Tweet vibe, what vibe does your tweet give off ?"
        }
        return render_template("siteviews.html", context = context)

    @app.route("/tweetvibe.json", methods=['POST'])
    @limiter.limit("80/hour") ## limit api to 80 calls per hour
    async def tweetvibe():
        
        LIMIT = 10 ## to minimize polling the google api count will determine the number of replies to be analysed
        body = request.json
        tweet_url = body.get("tweet_url")
        tweet_id = twitter.getidfromurl(tweet_url)
        if 'application/json' not in request.headers.get('Content-Type').lower():
            
            return dict(datatypes.ErrorData(False, "Content-Type not supported!", None))

        elif utils.isemptyorspace(tweet_url):

            return dict(datatypes.ErrorData(False, "tweet_url not found in request body", None))
        
        elif not twitter.isvalid_tweet_url(tweet_url):

            return dict(datatypes.ErrorData(False, "Invalid tweet url", None))

        elif utils.isemptyorspace(tweet_id):

            return datatypes.ErrorData(False, "Could not find tweet id from url", None)

        ## check cache for tweet_vibe 
        data = db.get_tweet_vibe(tweet_id)
        if data != None:

            del data["_id"]
            return dict(datatypes.ErrorData(True, "", data))

        twitter_cls = twitter.Twitter()
        tweet = twitter_cls.get_tweet(tweet_id)
        if not tweet.status:

            return dict(tweet)

        replies = twitter_cls.get_replies(tweet.data)
        if not replies.status:

            return dict(replies)

        sentiment_cls = detectvibe.SentimentAnalyser()
        count = 0
        result = []
        for reply in replies.data:

            text = reply.get("text")
            if text == None:

                continue

            analysis = sentiment_cls.get_text_vibe(text)
            if not analysis.status:

                continue

            result.append({
                "reply" : reply,
                "analysis" : analysis.data
            })
            count += 1

            if count == LIMIT:

                break
        
        tweet.data["result"] = result
        db.cache_tweet_vibe(tweet.data)
        response = make_response(dict(datatypes.ErrorData(True, "", tweet.data)))
        return response

    app.run("localhost", 5000, True)

server()

#[if __name__ == "__main__":

    #pass