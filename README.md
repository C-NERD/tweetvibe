# TweetVibe

web application tool to analyse tweet replies vibe

## Setup

You need python >= 3.7 and nim >= 1.4.0 to setup and run this project, so install them before anything.

1. Update your system
2. Clone this repository
3. Navigate to the root directory
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
6. create a `.env` file with the following variables

   ```env
   SERVER_HOST=0.0.0.0
   SERVER_PORT=5000
   TWITTER_API_KEY=
   TWITTER_API_SECRET=
   TWITTER_BEARER_TOKEN=
   GOOGLE_API_KEY=
   SECRET_KEY=
   DATABASE_URI=mongodb://localhost:27017/
   ```

or you could just run the setup.py script if you are on debian of arch. Also make sure to install and setup mongodb before running the code

## Run

After setup use `main.py` as the entry file to run the server
