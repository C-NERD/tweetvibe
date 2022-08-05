import utils, karax / [karax, karaxdsl, vdom]

proc homepage() : VNode =

    result = buildHtml main():

        navbar()

        main(id = "mainbody"):

            tdiv(id = "logo-wallpaper")
            span(id = "contentbody")

        footbar()
        toast()

setRenderer homepage