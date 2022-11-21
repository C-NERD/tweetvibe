from dataclasses import dataclass, field
from enum import IntEnum, unique

@dataclass
class Tweet:

    id : str = ""
    author_id : str = ""
    conversation_id : str = ""
    created_at : str = ""
    tweet_id : str = ""
    in_reply_to_user_id : str = ""
    text : str = ""

    def from_dict(self, data : dict):
        
        self.id = data.get("id")
        self.author_id = data["author_id"]
        self.conversation_id = data["conversation_id"]
        self.created_at = data["created_at"]
        self.tweet_id = data.get("tweet_id")
        self.in_reply_to_user_id = data.get("in_reply_to_user_id")
        self.text = data["text"]

    def __iter__(self) -> dict:

        yield "id", self.id
        yield "author_id", self.author_id
        yield "conversation_id", self.conversation_id
        yield "created_at", self.created_at
        yield "tweet_id", self.tweet_id
        yield "in_reply_to_user_id", self.in_reply_to_user_id
        yield "text", self.text

@unique
class Vibe(IntEnum):

    Negative = 1
    Neutral = 2
    Positive = 3

@dataclass
class Analysis:

    score : int = 0
    vibe : Vibe = Vibe.Negative

    def from_dict(self, data : dict):

        self.score = data["score"]
        self.vibe = Vibe(data["vibe"])

    def __iter__(self) -> dict:

        yield "score", self.score
        yield "vibe", self.vibe

@dataclass
class TweetVibe:

    analysis : Analysis = Analysis()
    tweet : Tweet = Tweet()

    def from_dict(self, data : dict):

        self.analysis = Analysis()
        self.analysis.from_dict(data["analysis"])

        self.tweet = Tweet()
        self.tweet.from_dict(data["tweet"])

    def __iter__(self) -> dict:

        yield "analysis", dict(self.analysis)
        yield "tweet", dict(self.tweet)

@dataclass
class VibeAnalysis():

    parent_tweet : TweetVibe = TweetVibe()
    replies : list = field(default_factory = list) # list[TweetVibe]

    def from_dict(self, data : dict):

        self.parent_tweet.from_dict(data["parent_tweet"])
        for reply in data["replies"]:

            reply_obj = TweetVibe()
            reply_obj.from_dict(reply)
            self.replies.append(reply_obj)

    def __iter__(self) -> dict :

        replies = []
        for reply in self.replies:

            replies.append(dict(reply))

        yield "parent_tweet", dict(self.parent_tweet)
        yield "replies", replies

@dataclass
class ErrorData:

    status : bool = False
    msg : str = ""
    data : any = None

    def __iter__(self) -> dict :

        yield "status", self.status
        yield "msg", self.msg
        yield "data", self.data

