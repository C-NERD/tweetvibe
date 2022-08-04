import requests
from tweetvibe.utils import datatypes
from enum import Enum, unique
from os import getenv

@unique
class Vibe(Enum):

    Negative = 1
    Neutral = 2
    Positive = 3

class SentimentAnalyser:
    """
    Uses google natural language analyser api
    """

    def __init__(self):

        self.root_url = "https://language.googleapis.com"

    def get_text_vibe(text : str) -> Vibe :
        """
        Perform sentiment analysis on text

        :param text: text on which sentiment analysis will be performed

        retype: 
            -Vibe object
        """

        url = self.root_url + "/v1/documents:analyzeSentiment"
        body = {
            "document": {
                "type": "PLAIN_TEXT",
                #"language": string,
                "content": text,
                #"gcsContentUri": string # location of content file
            },
            "encodingType": "UTF8"
        }

        resp = requests.post(url, data = body)
        
