import dotenv
from pathlib import Path
from tweetvibe.utils import datatypes, utils
from tweetvibe.twitter import twitter
from tweetvibe.detectvibe import detectvibe
from flask import Flask, request, make_response

env_file = Path(__file__).parent / ".env"
dotenv.load_dotenv(env_file)

def server():

    app = Flask(__name__, static_folder = "public/", template_folder = "public/html/")
    @app.route("/")
    async def home():

        return ""

    @app.route("/tweetvibe.json", methods=['POST'])
    async def tweetvibe():
        
        LIMIT = 10 ## to minimize polling the google api count will determine the number of replies to be analysed
        if 'application/json' not in request.headers.get('Content-Type').lower():
            
            return dict(datatypes.ErrorData(False, "Content-Type not supported!", None))

        body = request.json
        tweet_url = body.get("tweet_url")
        if utils.isemptyorspace(tweet_url):

            return dict(datatypes.ErrorData(False, "tweet_url not found in request body", None))

        replies = twitter.Twitter().get_replies(tweet_url)
        if not replies.status:

            return dict(replies)

        sentiment_cls = detectvibe.SentimentAnalyser()
        count = 0
        result = []
        for reply in replies.data:

            text = reply.get("text")
            if utils.isemptyorspace(text):

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

        response = make_response(dict(datatypes.ErrorData(True, "", result)))
        return response

    app.run("localhost", 5000, True)

server()

