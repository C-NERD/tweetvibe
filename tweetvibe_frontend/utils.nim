{.experimental : "codeReordering".}

import karax / [karax, karaxdsl, vdom, vstyles], dom, asyncjs
from uri import Uri, parseUri, decodeQuery
from json import `$`, parseJson, JsonNode
from std / jsonutils import fromJson, toJson, Joptions
from tables import Table, `[]=`
from sugar import `=>`
#from std / jsonutils import toJson

export parseJson, fromJson, toJson, JsonNode, `$` ## export json for fetch templates

type

    Toast = ref object of VComponent

        msg : string
        show : bool
        timer : TimeOut

    Overlay = ref object of VComponent

        child : VNode
        show : bool

    ReqMethod* {.pure.} = enum

        Get, Post, Put, Delete, Head, Patch

    Response* = object

        ok* : bool
        status* : cint
        text* : cstring

    Tweet* = ref object of RootObj

        author_id*, conversation_id*, created_at*, tweet_id*, in_reply_to_user_id*, text* : string

    Vibe* {.pure.} = enum

        Negative = 1
        Neutral = 2
        Positive = 3

    ReplyVibe* = object

        analysis* : tuple[score : int, vibe : Vibe]
        reply* : Tweet

    VibeAnalysis* = ref object of Tweet

        result* : seq[ReplyVibe]

    ErrorData*[T] = object

        status* : bool
        msg* : string
        data* : T

## Reactive variables
var
    onfetch_complete* : proc() {.closure.} = nil
    url_query* : Table[string, string]
    show_loading_screen* : bool = false
    generaltoast : Toast
    generaloverlay : Overlay

## Vanila js procs
proc showBarChart*(id, label : cstring, data : seq[cint], labels, bg, bc : seq[cstring]) {.importc.}

proc showDoughnutChart*(id, label : cstring, data : seq[cint], labels, bg, bc : seq[cstring]) {.importc.}

proc fetchWithTimeOut*(url, body, content_type, meth : cstring, timeout : cint) : Response {.importc, async.}

## Helper procs
template fetchImpl*(url, body, content_type : cstring = "text/html", meth : ReqMethod, timeout : cint = 10000, code : untyped) {.dirty.} =

    proc action() {.async.} =

        let 
            resp = newPromise() do(resolve : proc(response : Response)):
                resolve(fetchWithTimeOut(url, body, content_type, ($meth).cstring, timeout))
            response = await resp

        if not response.ok:

            showToast("Request failed")
        
        else:

            code
            redraw()
            if not onfetch_complete.isNil():

                onfetch_complete()
                onfetch_complete = nil

    discard action()

template fetchJsonImpl*[T](url, body : cstring, meth : ReqMethod, timeout : cint = 10000, code : untyped) =

    fetchImpl(url, body, "application/json", meth, timeout):

        var resp_obj {.inject.} : T
        resp_obj.fromJson(parseJson($response.text), Joptions(allowExtraKeys : true, allowMissingKeys: true))
        
        code

proc showToast*(msg : string, timems : int = 2000) =
    ## displays toast
    
    if generaltoast.isNil():
        ## do noting if toast var is nil
        
        return

    if not generaltoast.timer.isNil():
        ## destroys previous toast
        
        generaltoast.timer.clearTimeout()
        generaltoast.timer = nil

    generaltoast.markDirty()
    generaltoast.show = true
    generaltoast.msg = msg

    generaltoast.timer = setTimeout(
        () => (
            generaltoast.markDirty();
            generaltoast.show = false;
            generaltoast.msg = "";
            redraw()
        ), timems
    )

proc showToast(msg : cstring, timems : cint) {.exportc.} =

    showToast($msg, timems.int)

proc showOverlay*(child : VNode) = 

    if generaloverlay.isNil():
        ## do noting if overlay var is nil
        
        return
    
    generaloverlay.markDirty()
    generaloverlay.show = true
    generaloverlay.child = child

proc hideOverlay() = 

    if generaloverlay.isNil():
        ## do noting if overlay var is nil
        
        return
    
    generaloverlay.markDirty()
    generaloverlay.show = false 
    generaloverlay.child = nil

proc parseUrlQueries*() =

    let query = parseUri($window.location.href).query
    for key, value in decodeQuery(query):

        url_query[key] = value

## VNode procs
proc navbar*() : VNode =

    result = buildHtml nav(id = "navbar"):

        h2(class = "coloured-text"):

            text "Tweet Vibe"

        span(id = "navwidgets"):

            p(class = "btn-text"):

                proc onclick() {.closure.} =

                    let about_node = buildHtml p(class = "overlay_child"):

                        p():
                            
                            text """Tweet vibe is a tool to analyse the vibe of a tweet's reply using sentiment analysis,
                                a report is then generated after the analysis and displayed in an orderly fashion."""

                        p():

                            text """This tool uses the twitter v2 api to get the requested tweet by tweet id and to get
                                the tweets replies by conversation_id. The replies are then feed to the google natural
                                language processing api for sentiment analysis before the whole result is displayed."""

                        p():

                            text """To avoid spamming the apis used by this tool, only a maximum of 15 tweet replies
                                are analysed these replies are then used to estimate the mean vibe of the tweet's replies."""

                        p():

                            text "The charts displayed by this tool are generated by charts.js, so props to the charts.js devs"

                    showOverlay(about_node)

                text "About"

            p(class = "btn-text"):

                proc onclick() {.closure.} =

                    let contact_node = buildHtml span(id = "vertical_center", class = "overlay_child"):

                        a(class = "social_media", href = "https://www.youtube.com/channel/UCDAN3oIUauqL5e7-6gf09MQ"):

                            tdiv(id = "youtube")
                            p():

                                text "Youtube"

                        a(class = "social_media", href = "https://twitter.com/CNERD7"):

                            tdiv(id = "twitter")
                            p():
                                
                                text "Twitter"

                        a(class = "social_media", href = "https://t.me/C_NERD"):

                            tdiv(id = "telegram")
                            p():
                                
                                text "Telegram"

                    showOverlay(contact_node)
                    
                text "Contacts"

proc footbar*() : VNode =

    result = buildHtml footer(id = "footbar"):

        text "© Tweet vibe by C-NERD all rights reserved"

proc loadingScreen*() : VNode =

    let loadscreen_style : Vstyle = block :

        var loadscreen_style : Vstyle
        if show_loading_screen:

            loadscreen_style = style(display, "flex")

        else:

            loadscreen_style = style(display, "none")

        loadscreen_style

    result = buildHtml span(id = "loadscreen", style = loadscreen_style):

        tdiv(id = "load-spiner"):

            tdiv()
            tdiv()

## Reactive procs
proc toast*(toast : var Toast = generaltoast) : Toast =

    proc render(toast : VComponent) : VNode =

        let self = Toast(toast)
        self.markDirty()

        let toast_style : Vstyle = block :

            var toast_style : Vstyle
            if self.show:

                toast_style = style(display, "flex")

            else:

                toast_style = style(display, "none")

            toast_style

        result = buildHtml span(id = "toastcontainer", style = toast_style):

            tdiv(id = "toast"):

                text self.msg

    if toast.isNil():

        toast = newComponent(Toast, render)

    return toast

proc overlay*(overlay : var Overlay = generaloverlay) : Overlay =

    proc render(overlay : VComponent) : VNode =

        let self = Overlay(overlay)
        self.markDirty()

        let overlay_style : Vstyle = block :

            var overlay_style : Vstyle
            if self.show:

                overlay_style = style(display, "flex")

            else:

                overlay_style = style(display, "none")

            overlay_style

        result = buildHtml span(id = "overlaycontainer", style = overlay_style):

            span(id = "overlay"):

                span(id = "cancelcontainer"):

                    tdiv(class = "cancelbox", onclick = hideOverlay):

                        tdiv(class = "cancelline1")
                        tdiv(class = "cancelline2")

                if not self.child.isNil():

                    self.child

    if overlay.isNil():

        overlay = newComponent(Overlay, render)

    return overlay
