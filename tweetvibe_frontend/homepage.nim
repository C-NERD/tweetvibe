import utils, karax / [karax, karaxdsl, vdom, vstyles], asyncjs
from std / strutils import isEmptyOrWhitespace, split, contains
from std / sugar import `=>`

var 
    tweet_analysis_data : tuple[data : VibeAnalysis, hasdata : bool]
    load_screen_style = style(display, "none")
    reactive_replies : tuple[data : seq[TweetVibe], isdown : bool]
    charts_style : Display = Display.None
    total_vibes : tuple[negative, neutral, positive : int]
    vibe_ratings : seq[cint]
    tweets, tweet_ids, bar_colors, bar_borders : seq[cstring]
    chart_calc : bool

proc isValidTweetUrl(url : string) : bool =
    ## checks if url is a valid tweet url
    
    let part_url = url.split("/")
    if "twitter.com" in part_url and "status" in part_url:

        return true

proc tweet(tweet : Tweet, vibe : Vibe) : VNode =

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

        tdiv(class = "vibe_status"):

            tdiv(class = "vibe-color-code", style = vibe_color)
            h3():

                text $vibe

        span(class = "tweet-meta"):

            text tweet.text

proc homepage() : VNode =

    result = buildHtml main():
        
        span(id = "nav_container"):

            navbar()
        
            main(id = "mainbody"):

                span(id = "contentbody"):

                    span(id = "searchbar"):

                        input(`type` = "text", id = "tweet-url", placeholder = "Tweet Url")
                        button(`type` = "button", class = "coloured-btn"):

                            proc onclick() {.closure.} =

                                let tweet_url = $(getVNodeById("tweet-url").getInputText())
                                if not tweet_url.isValidTweetUrl():

                                    setToast("Invalid tweet url")
                                    return

                                load_screen_style = style(display, "flex")
                                onfetch_failed = () => (load_screen_style = style(display, "flex"))
                                redraw()

                                fetchJsonImpl[ErrorData[VibeAnalysis]]("/tweetvibe.json", ($toJson((tweet_url : tweet_url))).cstring, Post, 90000):

                                    if not resp_obj.status:

                                        setToast(resp_obj.msg)

                                    else:

                                        tweet_analysis_data = (data : resp_obj.data, hasdata : true)
                                        if reactive_replies.isdown:

                                            reactive_replies.data = resp_obj.data.replies

                                        chart_calc = true

                                    load_screen_style = style(display, "none")

                            text "Analyse"

                    if tweet_analysis_data.hasdata:

                        span(id = "tweet_analysis"):

                            span(id = "parent_tweet"):

                                tweet(
                                    tweet_analysis_data.data.parent_tweet.tweet, 
                                    tweet_analysis_data.data.parent_tweet.analysis.vibe
                                )

                            span(id = "tweet_replies"):

                                span(class = "dropdown_container"):

                                    h3:

                                        text "Replies"

                                    span(class = "dropdown"):

                                        proc onclick() =

                                            if reactive_replies.isdown:

                                                reactive_replies.data = @[]
                                                reactive_replies.isdown = false

                                            else:

                                                reactive_replies.data = tweet_analysis_data.data.replies
                                                reactive_replies.isdown = true

                                        tdiv(class = "fa-solid fa-down-long")

                                span(id = "tweet_replies_container"):

                                    for reply in reactive_replies.data:

                                        tweet(
                                            reply.tweet, 
                                            reply.analysis.vibe
                                        )

                            span(id = "analysis_charts"):

                                span(class = "dropdown_container"):

                                    h3:

                                        text "Charts"

                                    span(class = "dropdown"):

                                        proc onclick() =

                                            if charts_style == Display.None:

                                                charts_style = Display.Flex

                                            else:

                                                charts_style = Display.None

                                        tdiv(class = "fa-solid fa-down-long")

                                span(id = "charts_container", style = style(display, ($charts_style).cstring)):

                                    span(id = "replies-scores-container"):

                                        h3:
                                            text "Replies scores"

                                        canvas(id = "replies-scores")

                                    span(id = "vibe-ratings-container"):

                                        h3:
                                            text "Vibe ratings"

                                        canvas(id = "vibe-ratings")

        span(id = "footbar"):

            footbar()
            footbar2()

        toastVnode()
        
        span(id = "loadscreen", style = loadscreen_style):

            tdiv(id = "load-spiner"):

                tdiv()
                tdiv()

proc callBack() =

    if chart_calc:

        for each in tweet_analysis_data.data.replies:

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
            #tweets.add(each.tweet.text.cstring)
            tweet_ids.add(each.tweet.tweet_id.cstring)

        chart_calc = false

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

setRenderer homepage, "ROOT", callBack