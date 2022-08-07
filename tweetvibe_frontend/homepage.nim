import utils, karax / [karax, karaxdsl, vdom], asyncjs
#from jsre import newRegExp, contains
from strutils import isEmptyOrWhitespace, split, contains
#from tables import getOrDefault

var analysis_node : VNode = buildHtml span(id = "tweet_analysis")
proc isValidTweetUrl(url : string) : bool =
    ## checks if url is a valid tweet url
    
    let part_url = url.split("/")
    if "twitter.com" in part_url and "status" in part_url:

        return true

#[proc getIdFromUrl(url : string) : string =
    ## gets tweet id from url

    let part_url = url.split({'/', '?'})
    let regex = newRegExp("^([0-9])+?([0-9])", "gm")
    for partition in part_url:

        if regex in partition.cstring:

            return partition]#

proc tweet(tweet : Tweet) : VNode =

    result = buildHtml span(class = "tweet-meta"):

        for word in tweet.text.split():

            if '@' in word:

                em(class = "coloured-text"):

                    text word

            else:

                text word

proc analyseTweet(url : string) =

    fetchJsonImpl[ErrorData[VibeAnalysis]]("/tweetvibe.json", ($toJson((tweet_url : url))).cstring, Post, 10000):

        analysis_node = buildHtml span(id = "tweet_analysis"): 
            
            span:

                tweet(resp_obj.data)

                span:

                    span:

                        h3:
                            text "% vibe rating"
                        canvas(id = "vibe-mean-rating")

                    span:

                        h3:
                            text "Mean vibe rating"
                        em(id = "Tweet-mean-vibe")

            span(id = "replies-charts"):

                span:

                    h3:
                        text "Vibe rating (0-9)"
                    canvas(id = "replies-bar-chart")

                span:

                    h3:
                        text "Vibe rating (-ve, ve, +ve)"
                    canvas(id = "replies-vibe-bar-char")

proc homepage() : VNode =

    result = buildHtml main():

        navbar()

        main(id = "mainbody"):

            span(id = "contentbody"):

                span(id = "searchbar"):

                    input(`type` = "text", id = "tweet-url", placeholder = "Tweet Url")
                    button(`type` = "button", class = "coloured-btn"):

                        proc onclick() {.closure.} =

                            let tweet_url = $(getVNodeById("tweet-url").getInputText())
                            if not tweet_url.isValidTweetUrl():

                                showToast("Invalid tweet url")
                                return
                            
                            #[let tweet_id = tweet_url.getIdFromUrl()
                            if tweet_id.isEmptyOrWhitespace():

                                showToast("Cannot get tweet id from tweet url")
                                return]#

                            analyseTweet(tweet_url)

                        text "Analyse"

                if not analysis_node.isNil():

                    analysis_node

        footbar()
        overlay()
        toast()

proc callback() =

    #[let tweet_id = url_query.getOrDefault("tweet_id")
    if not tweet_id.isEmptyOrWhitespace():

        analyseTweet(tweet_id)]#
    
    discard

setRenderer homepage, "ROOT", callback