import pymongo, logging
from os import environ

class Database:

    def __init__(self):

        self.connection = pymongo.MongoClient(environ.get("DATABASE_URI"))
        self.collection = self.connection["tweetvibe"]["vibecache"]

    def get_tweet_vibe(self, tweet_id : int) -> dict:

        return self.collection.find_one({"tweet_id" : tweet_id})

    def cache_tweet_vibe(self, data : dict) -> bool :

        result = self.collection.insert_one(data)
        if data.get("_id") != None:

            del data["_id"]

        if result != None:

            return True
        
        else:

            return False

    def __del__(self):
        ## destructor to close mongodb instance

        self.connection.close()