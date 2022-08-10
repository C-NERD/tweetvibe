import dotenv
from pathlib import Path
from tweetvibe.utils import datatypes, utils
from tweetvibe.twitter import twitter
from tweetvibe.detectvibe import detectvibe
from tweetvibe.database import database
from flask import Flask, request, make_response, render_template
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from multiprocessing import Process
from logging import getLogger
from os import environ

env_file = Path(__file__).parent / ".env"
dotenv.load_dotenv(env_file)

HOST = environ.get("SERVER_HOST")
PORT = environ.get("SERVER_PORT")

if utils.isemptyorspace(HOST):

    HOST = "localhost" # default host

if utils.isemptyorspace(PORT):

    PORT = 5000 # default port

else:

    PORT = int(PORT)

def server():

    db = database.Database()
    app = Flask(__name__)
    #app.config.from_object("config.Production")
    app.config.from_object("config.Development")

    limiter = Limiter(app, key_func = get_remote_address)

    @app.route("/")
    async def home():
        
        context = {
            "path" : "static/",
            "file" : "homepage",
            "description" : "Tweet vibe, what vibe does your tweet give off ?"
        }
        return render_template("siteviews.html", context = context)

    @app.route("/tweetvibe.json", methods=['POST'])
    @limiter.limit("80/hour") ## limit api to 80 calls per hour
    async def tweetvibe():
        
        LIMIT = 15 ## to minimize polling the google api count will determine the number of replies to be analysed
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

    app.run(HOST, PORT, True)

if __name__ == "__main__":
    import argparse
    from os import cpu_count

    def validate_threads(threads) -> int :

        if threads == None:

            return 1

        threads = int(threads)
        cpus = cpu_count()
        if threads < 1:

            return 1
        
        elif threads > cpus:

            return cpus
        
        return threads

    parser = argparse.ArgumentParser("tweet vibe", usage = "python main.py <options>", description = "Web server for Tweet-Vibe")
    parser.add_argument("--cleardb", action = "store_true", help = "clear db cache")
    parser.add_argument("--run", action = "store_true", help = "run server")
    parser.add_argument("-t", "--threads", type = int, help = "number of processes to spawn (defaults to 1)")

    args = None
    logger = getLogger()
    try:

        args = parser.parse_args()

    except Exception:

        parser.print_help()
        quit()
    
    if args.cleardb:
        ## clear db cache

        logger.info("clearing db cache...")
        db = database.Database()
        db.clear_cache(True)
    
    elif args.run:

        threads = validate_threads(args.threads)
        for _ in range(threads):

            process = Process(target = server)
            process.start()
            process.join()
