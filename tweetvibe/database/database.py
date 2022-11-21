import pymongo, logging, sqlite3
from tweetvibe.utils import datatypes
from os import environ
from json import loads, dumps
from base64 import b64encode, b64decode

class Database:

    def __init__(self):

        handler = logging.FileHandler(environ.get("DATABASE_LOG"))
        handler.formatter = logging.Formatter("%(levelname)s :: %(asctime)s -> %(message)s")
        
        self.logger = logging.Logger("db_logger")
        self.logger.addHandler(handler)

        self.logger.info("initializing db instance")

        self.conn = sqlite3.connect(environ.get("DATABASE"))
        self.cur = self.conn.cursor()

    def init_db(self):

        self.logger.info("initialise new db tables")

        self.cur.execute(
            """
            CREATE TABLE IF NOT EXISTS Analysis(
                id INTEGER PRIMARY KEY,
                tweet_id VARCHAR(100) NOT NULL,
                data TEXT NOT NULL
            )
            """
        )
        self.conn.commit()

    def get_tweet_vibe(self, tweet_id : int) -> datatypes.VibeAnalysis:

        self.logger.info(f"getting data for tweet {tweet_id} from db")

        self.cur.execute("SELECT data FROM Analysis WHERE tweet_id = ?", [tweet_id])
        data = self.cur.fetchone()
        self.conn.commit()

        if data is None:

            return

        data = b64decode(data[0].encode("utf-8"))
        data = data.decode("utf-8")
        
        result = datatypes.VibeAnalysis()
        result.from_dict(loads(data))

        return result

    def cache_tweet_vibe(self, data : datatypes.VibeAnalysis):

        tweet_id = data.parent_tweet.tweet.tweet_id
        self.logger.info(f"caching tweet data for tweet {tweet_id}")

        data = b64encode(dumps(dict(data)).encode("utf-8"))
        self.cur.execute("INSERT INTO Analysis (tweet_id, data) VALUES (?, ?);", [tweet_id, data.decode("utf-8")])
        self.conn.commit()

    def clear_cache(self):
        ## clear db cache
        
        self.logger.info("clearing tweet cache")

        self.cur.execute("DELETE FROM Analysis;")
        self.conn.commit()

    def __del__(self):
        ## destructor to close sqlite instance

        self.conn.close()