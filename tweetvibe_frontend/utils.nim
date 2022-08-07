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

        children : seq[VNode]
        show : bool

    ReqMethod* {.pure.} = enum

        Get, Post, Put, Delete, Head, Patch

    Response* = object

        ok* : bool
        status* : cint
        text* : cstring

    Tweet* = ref object of RootObj

        author_id*, conversation_id*, created_at*, id*, in_reply_to_user_id*, text* : string

    Vibe* {.pure.} = enum

        Negative, Neutral, Positive

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
    url_query* : Table[string, string]
    generaltoast : Toast
    generaloverlay : Overlay

## Vanila js procs
proc fetchWithTimeOut*(url, body, content_type, meth : cstring, timeout : cint) : Response {.importc, async.}

## Helper procs
template fetchImpl*(url, body, content_type : cstring = "text/html", meth : ReqMethod, timeout : cint = 10000, code : untyped) =

    proc action() {.async.} =

        let 
            resp = newPromise() do(resolve : proc(response : Response)):
                resolve(fetchWithTimeOut(url, body, content_type, ($meth).cstring, timeout))
            response {.inject.} = await resp

        if not response.ok:

            showToast("Request failed")
        
        else:

            code
            redraw()

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

proc showOverlay*(children : seq[VNode]) = 

    if generaloverlay.isNil():
        ## do noting if overlay var is nil
        
        return
    
    generaloverlay.markDirty()
    generaloverlay.show = true
    generaloverlay.children = children 

proc hideOverlay() = 

    if generaloverlay.isNil():
        ## do noting if overlay var is nil
        
        return
    
    generaloverlay.markDirty()
    generaloverlay.show = false 
    generaloverlay.children = @[]

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

                text "About"

            p(class = "btn-text"):

                text "Contacts"

proc footbar*() : VNode =

    result = buildHtml footer(id = "footbar"):

        text "© Tweet vibe by C-NERD all rights reserved"

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

                tdiv(class = "cancelbox", onclick = hideOverlay):

                    tdiv(class = "cancelline1")
                    tdiv(class = "cancelline2")

                for child in self.children:

                    child

    if overlay.isNil():

        overlay = newComponent(Overlay, render)

    return overlay
