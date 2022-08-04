import requests
from tweetvibe.utils import datatypes
from enum import IntEnum, unique
from os import getenv
from json import dumps

@unique
class Vibe(IntEnum):

    Negative = 1
    Neutral = 2
    Positive = 3

class SentimentAnalyser:
    """
    Uses google natural language analyser api
    """

    def __init__(self):

        self.ROOT_URL = "https://language.googleapis.com"
        self.KEY = getenv("GOOGLE_API_KEY")

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

    def score_to_vibe(self, score : float) -> Vibe :

        if score in range(0, 3):

            return Vibe.Negative

        elif score in range(3, 7):

            return Vibe.Neutral

        elif score in range(7, 10):

            return Vibe.Positive

        else:

            return Vibe.Negative

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

            return datatypes.ErrorData(False, "Failed to get text sentiment", {})

        resp_body = resp.json()
        score = resp_body["documentSentiment"]["score"]
        score = self.refine_score(score)

        return datatypes.ErrorData(True, "", {
            "vibe" : self.score_to_vibe(score),
            "score" : score
        })
