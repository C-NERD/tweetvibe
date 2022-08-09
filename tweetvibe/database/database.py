import pymongo, logging
from logging import getLogger
from os import environ

logger = getLogger("database")
class Database:

    def __init__(self):

        logger.info("initializing db instance")
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

            logger.error(f"failed to cache tweet {data.get('tweet_id')}")
            return False

    def clear_cache(self, terminate : bool = False) :
        ## clear db cache
        
        self.collection.delete_many({})
        if terminate:

            self.__del__()

    def __del__(self):
        ## destructor to close mongodb instance

        self.connection.close()