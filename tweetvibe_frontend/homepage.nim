import utils, karax / [karax, karaxdsl, vdom, vstyles], asyncjs, dom
#from jsre import newRegExp, contains
from strutils import isEmptyOrWhitespace, split, contains
from strformat import fmt
from sugar import `=>`
#from tables import getOrDefault

type

    TweetReplies = ref object of VComponent

        show : bool

var 
    analysis_node : VNode = buildHtml span(id = "tweet_analysis")
    tweet_replies : TweetReplies
    #show_replies : Vstyle = style(display, "none")
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

proc tweet(tweet : Tweet, vibe : Vibe, main_tweet : bool = false) : VNode =

    let vibe_color : Vstyle = block :

        var vibe_color : VStyle
        case vibe

        of Negative:

            vibe_color = style(backgroundColor, "rgb(211, 24, 63)")

        of Neutral:

            vibe_color = style(backgroundColor, "rgb(24, 63, 211)")

        of Vibe.Positive:

            vibe_color = style(backgroundColor, "rgb(63, 211, 24)")

        vibe_color

    result = buildHtml span(class = "root_tweet"):

        if not main_tweet:

            tdiv(class = "vibe_status"):

                tdiv(class = "vibe-color-code", style = vibe_color)
                h3:

                    text fmt"Tweet gives {vibe} vibes"

        span(class = "tweet-meta"):

            text tweet.text

proc replies(tweet_replies : var TweetReplies = tweet_replies, reply_vibes : seq[ReplyVibe]) : TweetReplies =

    proc render(tweet_replies : VComponent) : VNode =

        let self = TweetReplies(tweet_replies)
        self.markDirty()

        let replies_style : VStyle = block:

            var replies_style : VStyle
            if self.show:

                replies_style = style(display, "content")

            else:

                replies_style = style(display, "none")

            replies_style

        result = buildHtml span(id = "tweet_replies", style = replies_style):

            for tweet_data in reply_vibes:

                tweet(tweet_data.reply, tweet_data.analysis.vibe)

    if tweet_replies.isNil():

        tweet_replies = newComponent(TweetReplies, render)

    return tweet_replies

proc analyseTweet(url : string) =

    fetchJsonImpl[ErrorData[VibeAnalysis]]("/tweetvibe.json", ($toJson((tweet_url : url))).cstring, Post, 60000):

        var 
            total_vibes : tuple[negative, neutral, positive : int]
            vibe_ratings : seq[cint]
            tweets, tweet_ids, bar_colors, bar_borders : seq[cstring]

        for each in resp_obj.data.result:

            case each.analysis.vibe

            of Negative:

                total_vibes.negative.inc()
                bar_colors.add("rgb(211, 24, 63)".cstring)

            of Neutral:

                total_vibes.neutral.inc()
                bar_colors.add("rgb(24, 63, 211)".cstring)

            of Vibe.Positive:

                total_vibes.positive.inc()
                bar_colors.add("rgb(63, 211, 24)".cstring)

            bar_borders.add("#1e1f22".cstring)
            vibe_ratings.add(each.analysis.score.cint)
            tweets.add(each.reply.text.cstring)
            tweet_ids.add(each.reply.tweet_id.cstring)

        let tweet_vibe : Vibe = block :

            var tweet_vibe : Vibe 
            if total_vibes.negative > total_vibes.neutral:
                
                if total_vibes.negative > total_vibes.positive:

                    tweet_vibe = Negative

                else:

                    tweet_vibe = Vibe.Positive
            
            elif total_vibes.neutral > total_vibes.negative:

                if total_vibes.neutral > total_vibes.positive:

                    tweet_vibe = Neutral
                
                else:

                    tweet_vibe = Vibe.Positive

            elif total_vibes.positive > total_vibes.negative:

                if total_vibes.positive > total_vibes.neutral:

                    tweet_vibe = Vibe.Positive

                else:

                    tweet_vibe = Neutral

            elif total_vibes.negative == total_vibes.neutral:

                if total_vibes.positive > 0:

                    tweet_vibe = Neutral

                else:

                    tweet_vibe = Negative

            elif total_vibes.negative == total_vibes.positive:

                if total_vibes.neutral > 0:

                    tweet_vibe = Neutral

                else:

                    tweet_vibe = Negative

            elif total_vibes.neutral == total_vibes.positive:

                if total_vibes.negative > 0:

                    tweet_vibe = Neutral

                else:

                    tweet_vibe = Vibe.Positive

            tweet_vibe

        analysis_node = buildHtml span(id = "tweet_analysis"): 

            tweet(resp_obj.data, tweet_vibe, true)

            span(id = "analysis-charts"):

                span(id = "replies-scores-container"):

                    h3:
                        text "Replies scores"
                    canvas(id = "replies-scores")

                span(id = "vibe-ratings-container"):

                    h3:
                        text "Vibe ratings"
                    canvas(id = "vibe-ratings")

            span(id = "reply-controller"):

                text "Replies"
                tdiv(id = "drop-btn"):

                    proc onclick() {.closure.} =

                        tweet_replies.markDirty()
                        if tweet_replies.show:

                            tweet_replies.show = false
                        
                        else:
                            
                            tweet_replies.show = true
                            
            replies(reply_vibes = resp_obj.data.result)

        proc display_charts() {.closure.} =

            setForeignNodeId("vibe-ratings-container")
            setForeignNodeId("replies-scores-container")

            showDoughnutChart(
                "vibe-ratings".cstring, "Mean vibe rating".cstring,
                @[total_vibes.negative.cint, total_vibes.neutral.cint, total_vibes.positive.cint],
                @["Negative".cstring, "Neutral".cstring, "Positive".cstring],
                @[
                    "rgb(211, 24, 63)".cstring,
                    "rgb(24, 63, 211)".cstring,
                    "rgb(63, 211, 24)".cstring
                ],
                @[
                    "#1e1f22".cstring,
                    "#1e1f22".cstring,
                    "#1e1f22".cstring
                ]
            )

            showBarChart(
                "replies-scores".cstring, "Replies vibe ratings".cstring,
                vibe_ratings, tweet_ids,
                bar_colors, bar_borders
            )

        show_loading_screen = false
        onfetch_complete = () => (
            var interval : Interval;
            interval = window.setInterval(
                () => (
                    if not getElementById("vibe-ratings").isNil() and not getElementById("replies-scores").isNil():

                        display_charts();
                        interval.clearInterval();
                ), 50
            );
        )

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
                            
                            show_loading_screen = true
                            redraw()

                            analyseTweet(tweet_url)

                        text "Analyse"

                if not analysis_node.isNil():

                    analysis_node

        footbar()
        overlay()
        toast()
        loadingScreen()

#[proc callback() =

    let tweet_id = url_query.getOrDefault("tweet_id")
    if not tweet_id.isEmptyOrWhitespace():

        analyseTweet(tweet_id)]#

setRenderer homepage, "ROOT"