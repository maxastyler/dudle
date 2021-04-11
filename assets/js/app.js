// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import * as rs from "responsive-sketchpad"
import {LiveSocket} from "phoenix_live_view"

const pen_sizes = [2, 10, 20];
const pen_colours = ["#000000", "#FFFFFF", "#FF0000", "#00FF00", "#0000FF"];

let Hooks = {}
Hooks.SketchPad = {
    mounted() {
        let sketch_el = document.createElement("div");
        let size_div = document.createElement("div");
        let colour_div = document.createElement("div");
        let control_div = document.createElement("div");

        this.pad = new rs(sketch_el, {
            line: {
                color: '#f44335',
                size: 5
            },
            width: 500,
        });

        let undo = document.createElement("button");
        undo.appendChild(document.createTextNode("undo"));
        undo.addEventListener("click", () => {this.pad.undo()});
        control_div.appendChild(undo);

        let redo = document.createElement("button");
        redo.appendChild(document.createTextNode("redo"));
        redo.addEventListener("click", () => {this.pad.redo()});
        control_div.appendChild(redo);

        for (const i in pen_sizes) {
            let button = document.createElement("button");
            button.addEventListener("click", () => {this.pad.setLineSize(pen_sizes[i])});
            let t = document.createTextNode(pen_sizes[i]);
            button.appendChild(t);
            size_div.appendChild(button);
        }
        for (const i in pen_colours) {
            let button = document.createElement("button");
            button.style = `background-color:${pen_colours[i]}`;
            button.addEventListener("click", () => {this.pad.setLineColor(pen_colours[i])});
            colour_div.appendChild(button);
        }

        this.el.appendChild(size_div);
        this.el.appendChild(colour_div);
        this.el.appendChild(control_div);
        this.el.appendChild(sketch_el);

        // this.el.style = "background-color:black";

        this.handleEvent("send_data",
                         (_) => {this.pushEvent("handle_sketch_data",
                                                {sketch_data: this.pad.toJSON()})})
        this.handleEvent("update_data",
                         (data) => {this.pad.loadJSON(data)})
    }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

