import pytwitter, logging
from tweetvibe.utils import datatypes
from tweetvibe.utils.utils import isemptyorspace
from re import match, split
from os import environ

def isvalid_tweet_url(url : str) -> bool :
    """
    Checks if url contains twitter.com and the string status

    :param url: tweet url

    retype :
        - bool, True if url is valid tweet url else False
    """

    part_url = url.split("/")
    if "twitter.com" in part_url and "status" in part_url:

        return True

    else:

        return False

def getidfromurl(url : str) -> str :
    """
    Gets tweetid from tweet url

    :param url: tweet url

    retype :
        - tweet id
        - empty string when id not found
    """

    part_url = split(r"(/|\?)", url)
    for partition in part_url:

        if match(r"[0-9]", partition) != None:

            return partition

    return ""

class Twitter:

    def __init__(self):

        handler = logging.FileHandler(environ.get("TWITTER_LOG"))
        handler.formatter = logging.Formatter("%(levelname)s :: %(asctime)s -> %(message)s")
        
        self.logger = logging.Logger("sentiment_logger")
        self.logger.addHandler(handler)
        
        self.api = pytwitter.Api(
            bearer_token = environ.get("TWITTER_BEARER_TOKEN"),
            consumer_key = environ.get("TWITTER_API_KEY"),
            consumer_secret = environ.get("TWITTER_API_SECRET")
        )
    
    def getdirect_children(self, author_id : str, tweet_id : str, conversation_id : str, tweets : list) -> dict :
        """
        Generator to get direct replies from a tweet
        """

        for tweet in tweets:

            if tweet["conversation_id"] != conversation_id:
                ## If tweet is not a reply to the head tweet

                continue
            
            elif tweet["id"] == conversation_id:
                ## If tweet is the head tweet

                continue

            elif tweet["id"] == tweet_id:
                ## If tweet is the original tweet

                continue

            elif tweet["in_reply_to_user_id"] != author_id:
                ## If tweet is not a direct reply of original tweet

                continue

            yield tweet

    def get_tweet(self, tweet_id : str) -> datatypes.ErrorData :

        tweet = self.api.get_tweet(
            tweet_id, tweet_fields = ("conversation_id", "author_id", "created_at"), 
            return_json = True
        )
        conversation_id = ""
        author_id = ""
        created_at = ""
        tweet_id = ""

        try:
            
            conversation_id = tweet["data"]["conversation_id"]
            author_id = tweet["data"]["author_id"]
            created_at = tweet["data"]["created_at"]
            tweet_id = tweet["data"]["id"]
            if isemptyorspace(conversation_id) or isemptyorspace(author_id) or isemptyorspace(created_at) or isemptyorspace(tweet_id):
                ## If conversation_id, author_id or created_at is empty or whitspace raise keyerror

                raise KeyError()
            
            return datatypes.ErrorData(True, "", {
                "tweet_id" : tweet_id, "author_id" : author_id, 
                "conversation_id" : conversation_id, "created_at" : created_at,
                "text" : tweet["data"]["text"]
                })
        except KeyError as e:
            
            self.logger.error(f"failed to get tweet {tweet_id}")
            self.logger.debug(e)
            return datatypes.ErrorData(False, "Could not get tweet's data", None)

    def get_replies(self, data : dict, limit : int = 100) -> datatypes.ErrorData :
        """
        Gets direct replies for a tweet or tweet reply,
        
        :param data: data of tweet returned by self.get_tweet
        :param limit: maximum amount of replies to scrape. default 100

        retype:  
            - ErrorData with data as list of tweet object or None
        """

        conversation_id = data["conversation_id"]
        author_id = data["author_id"]
        created_at = data["created_at"]
        tweet_id = data["tweet_id"]

        replies = self.api.search_tweets(
            f"conversation_id:{conversation_id}", start_time = created_at, max_results = limit, sort_order = "relevancy", 
            tweet_fields = ("conversation_id", "in_reply_to_user_id", "author_id", "created_at"), return_json = True
        )
        return datatypes.ErrorData(True, "", self.getdirect_children(author_id, tweet_id, conversation_id, replies["data"]))
