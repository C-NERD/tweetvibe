#! /bin/python3

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

env_file = Path(__file__).parent / ".env_public"
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

    app = Flask(__name__)
    #app.config.from_object("config.Production")
    app.config.from_object("config.Development")

    limiter = Limiter(app, key_func = get_remote_address)

    @app.route("/")
    @limiter.limit("5000/hour") ## limit api to 50 calls per hour
    async def home():
        
        context = {
            "path" : "static/",
            "file" : "homepage",
            "description" : "Tweet vibe, what vibe does your tweet give off ?"
        }
        return render_template("siteviews.html", context = context)

    @app.route("/tweetvibe.json", methods=['POST'])
    @limiter.limit("5000/hour") ## limit api to 50 calls per hour
    async def tweetvibe():

        db = database.Database()        
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

            return dict(datatypes.ErrorData(False, "Could not find tweet id from url", None))

        ## check cache for tweet_vibe 
        data = db.get_tweet_vibe(tweet_id)
        if data != None:

            return dict(datatypes.ErrorData(True, "", data))

        twitter_cls = twitter.Twitter()
        tweet = twitter_cls.get_tweet(tweet_id)
        if not tweet.status:

            return dict(tweet)

        replies = twitter_cls.get_replies(tweet.data)
        if not replies.status:

            return dict(replies)

        sentiment_cls = detectvibe.SentimentAnalyser()
        tweet_analysis = sentiment_cls.get_text_vibe(tweet.data.get("text"))
        if not tweet_analysis.status:

            return dict(tweet_analysis)

        count = 0
        replies_vibes = []
        for reply in replies.data:

            text = reply.get("text")
            if text == None:

                continue

            analysis = sentiment_cls.get_text_vibe(text)
            if not analysis.status:

                continue
            
            reply_analysis = datatypes.Analysis()
            reply_analysis.from_dict(analysis.data)

            replies_vibes.append(
                datatypes.TweetVibe(
                    analysis = reply_analysis,
                    tweet = reply
                )
            )
            count += 1

            if count == LIMIT:

                break
        
        parent_tweet = datatypes.Tweet()
        parent_tweet.from_dict(tweet.data)

        tweet_analysis_obj = datatypes.Analysis()
        tweet_analysis_obj.from_dict(tweet_analysis.data)
        
        analysis = datatypes.VibeAnalysis(
            datatypes.TweetVibe(tweet_analysis_obj, parent_tweet),
            replies_vibes
        )

        db.cache_tweet_vibe(analysis)
        response = make_response(dict(datatypes.ErrorData(True, "", dict(analysis))))
        return response

    app.run(HOST, PORT, True)

if __name__ == "__main__":

    import argparse
    
    parser = argparse.ArgumentParser("tweet vibe", usage = "python main.py <options>", description = "Web server for Tweet-Vibe")
    parser.add_argument("--initdb", action = "store_true", help = "initialize sqlite db")
    parser.add_argument("--cleardb", action = "store_true", help = "clear db cache")
    parser.add_argument("--run", action = "store_true", help = "run server")

    args = None
    try:

        args = parser.parse_args()

    except Exception:

        parser.print_help()
        quit()

    if args.initdb:

        print("initializing sqlite db for tweetvibe")
        db = database.Database()
        db.init_db()

    elif args.cleardb:
        ## clear db cache

        print("clearing db cache...")
        db = database.Database()
        db.clear_cache()
    
    elif args.run:

        server()
        
