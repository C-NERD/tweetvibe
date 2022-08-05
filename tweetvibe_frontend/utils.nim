{.experimental : "codeReordering".}

import karax / [karaxdsl, vdom, vstyles], dom, asyncjs
#from json import parseJson, to, JsonNode
from sugar import `=>`
#from std / jsonutils import toJson

type

    Toast = ref object of VComponent

        msg : string
        show : bool
        timer : TimeOut

    ReqMethod {.pure.} = enum

        Get, Post, Put, Delete, Head, Patch

    Response = object

        ok : bool
        status : cint
        text : cstring

## Reactive variables
var
    generaltoast : Toast

## Vanila js procs
proc fetchWithTimeOut(url, body, content_type : cstring, meth : ReqMethod, timeout : cint) : Response {.importc, async.}

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

    discard action()

template fetchJsonImpl*[T](url, body : cstring, meth : ReqMethod, timeout : cint = 10000, code : untyped) {.dirty.} =

    fetchImpl(url, body, "application/json" meth, timeout):

        let 
            json_resp : JsonNode = parseJson($response.text)
            resp_obj : T = json_resp.to(T)

        code

proc showToast*(msg : string, timems : int = 2000) =
    ## displays toast

    if not generaltoast.timer.isNil():
        ## destroys previous toast
        
        generaltoast.timer.clearTimeout()
        generaltoast.timer = nil

    generaltoast.show = true
    generaltoast.msg = msg
    generaltoast.markDirty()

    generaltoast.timer = setTimeout(
        () => (
            generaltoast.show = false;
            generaltoast.msg = "";
            generaltoast.markDirty();
        ), timems
    )

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
