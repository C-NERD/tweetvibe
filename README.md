# TweetVibe

web application tool to analyse a tweet's vibe

## Setup

You need python >= 3.7 and nim >= 1.6.0 to setup and run this project, so install them before anything.

To install the python3 interpreter download it from [python downloads](https://www.python.org/downloads/https:/).

To install the nim compiler download a compiler of version greater or equals to 1.6.0 at [nim downloads](https://nim-lang.org/install.htmlhttps:/).

Make sure that the python interpreter and the nim compiler are in your system's path, you can confirm that by simply typing `python3` or `nim` in your terminal respectively.

After installing both compilers follow these steps to setup the project

1. Update your system (optional)
2. Clone this repository
3. Navigate to the root directory of this cloned repository
4. run

   ```bash
   pip install -r requirements.txt
   ```

   to install the python dependencies
5. run

   ```bash
   nimble build
   ```

   to install the nim dependencies and build the frontend js files
6. update the values in the `.env_public` file to configure settings to be used by the tweetvibe server. For your twitter api key you can apply for them by signing up for a developer account at [twitter dev account](https://developer.twitter.com/en/docs/twitter-api/getting-started/getting-access-to-the-twitter-api)
   and you can get your google api keys and secret for the sentiment analysis at [google sentiment analysis](https://cloud.google.com/natural-language/docs/analyzing-sentiment)

   ```env
   SERVER_HOST=localhost
   SERVER_PORT=5000
   TWITTER_API_KEY=""
   TWITTER_API_SECRET=""
   TWITTER_BEARER_TOKEN=""
   GOOGLE_API_KEY=""
   SECRET_KEY=""
   DATABASE_LOG=logs/db.log.txt
   SENTIMENT_LOG=logs/sentiment.log.txt
   TWITTER_LOG=logs/twitter.log.txt
   DATABASE=tweetvibe.db
   ```

## Run

After setting up the project run you'd want to initialise the tables for the project's database. To do that run

```bash
python3 main.py --initdb
```

After initialising the project's database you can then run the tweetvibe server with the following

```bash
python3 main.py --run
```
