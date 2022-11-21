{.experimental : "codeReordering".}

import karax / [karax, karaxdsl, vdom, vstyles], dom, asyncjs
from std / json import `$`, parseJson, JsonNode
from std / jsonutils import fromJson, toJson, Joptions
from std / tables import Table, `[]=`
from std / sugar import `=>`

export parseJson, fromJson, toJson, JsonNode, `$` ## export json for fetch templates

type

    Display* {.pure.} = enum

        None = "none"
        Flex = "flex"

    Toast = ref object of VComponent

        display : Display
        msg : string
        timems : int
        timer : TimeOut

    ReqMethod* {.pure.} = enum

        Get, Post, Put, Delete, Head, Patch

    Response* = object

        ok* : bool
        status* : cint
        text* : cstring

    Tweet* = object

        id*, author_id*, conversation_id*, created_at*, tweet_id*, in_reply_to_user_id*, text* : string

    Vibe* {.pure.} = enum

        Negative = 1
        Neutral = 2
        Positive = 3

    Analysis* = object

        score* : int
        vibe* : Vibe

    TweetVibe* = object

        analysis* : Analysis
        tweet* : Tweet

    VibeAnalysis* = object

        parent_tweet* : TweetVibe
        replies* : seq[TweetVibe]

    ErrorData*[T] = object

        status* : bool
        msg* : string
        data* : T

## Reactive variables
var
    onfetch_failed* : proc() {.closure.} = nil
    show_loading_screen* : bool = false
    toast : Toast

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

            if not onfetch_failed.isNil():

                onfetch_failed()

            setToast("Request failed")
        
        else:

            code
            redraw()

    discard action()

template fetchJsonImpl*[T](url, body : cstring, meth : ReqMethod, timeout : cint = 10000, code : untyped) =

    fetchImpl(url, body, "application/json", meth, timeout):

        var resp_obj {.inject.} : T
        resp_obj.fromJson(parseJson($response.text), Joptions(allowExtraKeys : true, allowMissingKeys: true))
        
        code

proc setToast*(msg : string, timems : int = 2000) =

    toast.markDirty()
    if not toast.timer.isNil():

        toast.timer.clearTimeout()
        toast.timer = nil

    toast.display = Display.Flex
    toast.msg = msg
    toast.timems = timems
    
    toast.timer = runLater(
        
        () => (toast.markDirty(); toast.display = Display.None; toast.msg = ""; toast.timer = nil),
        toast.timems
    )

proc setToast(msg : cstring, timems : cint) {.exportc.} = 

    setToast($msg, timems.int)

## VNode procs
proc navbar*() : VNode =

    result = buildHtml nav(id = "navbar"):

        h2(class = "coloured-text"):

            text "Tweet Vibe"

proc footbar*() : VNode =

    result = buildHtml footer(id = "footbar1"):

        span(id = "footwidgets"):

            a(class = "social_media", href = "https://www.youtube.com/channel/UCDAN3oIUauqL5e7-6gf09MQ"):

                tdiv(class = "icon fa-brands fa-youtube")
                p():

                    text "Youtube"

            a(class = "social_media", href = "https://twitter.com/CNERD7"):

                tdiv(class = "icon fa-brands fa-twitter")
                p():

                    text "Twitter"

            a(class = "social_media", href = "https://t.me/C_NERD"):

                tdiv(class = "icon fa-brands fa-telegram")
                p():

                    text "Telegram"

proc footbar2*() : VNode =

    result = buildHtml footer(id = "footbar2"):

        text "© Tweet vibe by C-NERD all rights reserved"

## Reactive procs
proc toastVnode*(toast : var Toast = toast) : Toast =

    proc render(toast : VComponent) : VNode {.closure.} =

        let self = Toast(toast)
        self.markDirty()

        result = buildHtml(tdiv(id = "toastcontainer", style = style(display, ($self.display).cstring))):

            tdiv(id = "toast"):

                text self.msg

    if toast.isNil():

        toast = newComponent(Toast, render)
    
    return toast
