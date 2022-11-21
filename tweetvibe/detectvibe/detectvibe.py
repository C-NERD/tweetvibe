import requests, logging
from tweetvibe.utils import datatypes
from enum import IntEnum, unique
from os import environ
from json import dumps

class SentimentAnalyser:
    """
    Uses google natural language analyser api
    """

    def __init__(self):

        handler = logging.FileHandler(environ.get("SENTIMENT_LOG"))
        handler.formatter = logging.Formatter("%(levelname)s :: %(asctime)s -> %(message)s")
        
        self.logger = logging.Logger("sentiment_logger")
        self.logger.addHandler(handler)

        self.ROOT_URL = "https://language.googleapis.com"
        self.KEY = environ.get("GOOGLE_API_KEY")

    def refine_score(self, score : float) -> int :
        """
        Refines google sentiment score into a scale of 0-9

        :param score: google sentiment score

        retype:
            - int
        """

        score = score + 1 ## make score scale into positive
        score = round((score / 2) * 9)

        return score

    def score_to_vibe(self, score : float) -> datatypes.Vibe :

        if score in range(0, 3):

            return datatypes.Vibe.Negative

        elif score in range(3, 7):

            return datatypes.Vibe.Neutral

        elif score in range(7, 10):

            return datatypes.Vibe.Positive

        else:

            return datatypes.Vibe.Negative

    def get_text_vibe(self, text : str) -> datatypes.ErrorData :
        """
        Perform sentiment analysis on text

        :param text: text on which sentiment analysis will be performed

        retype: 
            -ErrorData class
        """

        url = self.ROOT_URL + f"/v1/documents:analyzeSentiment?key={self.KEY}"
        headers = {
            "Content-Type": "application/json; charset=utf-8"
        }
        payload = {
            "document": {
                "type": "PLAIN_TEXT",
                "content": text
            },
            "encodingType": "UTF8"
        }

        resp = requests.post(url, data = dumps(payload), headers = headers)
        if resp.status_code != 200:

            self.logger.error(f"request to google api failed with code {resp.status_code}")
            return datatypes.ErrorData(False, "Failed to get text sentiment", {})

        resp_body = resp.json()
        score = resp_body["documentSentiment"]["score"]
        score = self.refine_score(score)

        return datatypes.ErrorData(True, "", {
            "vibe" : self.score_to_vibe(score),
            "score" : score
        })
