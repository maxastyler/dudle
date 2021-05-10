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
import topbar from "topbar"
import {LiveSocket} from "phoenix_live_view"
import * as rs from "responsive-sketchpad"

const pen_sizes = [2, 10, 20];
const pen_colours = ["#000000", "#FFFFFF", "#FF0000", "#00FF00", "#0000FF", "#FFC0CB", "#964B00", "#FFFF00"];

let Hooks = {}
Hooks.SketchPad = {
    mounted() {
        let sketch_el = document.createElement("div");
        let size_div = document.createElement("div");
        let colour_div = document.createElement("div");
        colour_div.className = "colour_container";
        let control_div = document.createElement("div");

        this.pad = new rs(sketch_el, {
            line: {
                color: pen_colours[0],
                size: pen_sizes[0]
            },
            width: 500,
        });

        this.send_function = () => {this.pushEvent("handle_sketch_data",
                                                   {sketch_data: this.pad.toJSON()})};
        this.send_image_function = () => {this.pushEvent("handle_image_data",
                                                         {image_data: this.pad.canvas.toDataURL("image/png")})}

        let undo = document.createElement("button");
        undo.appendChild(document.createTextNode("undo"));
        undo.addEventListener("click", () => {this.pad.undo()});
        control_div.appendChild(undo);

        let redo = document.createElement("button");
        redo.appendChild(document.createTextNode("redo"));
        redo.addEventListener("click", () => {this.pad.redo()});
        control_div.appendChild(redo);

        let send = document.createElement("button");
        send.appendChild(document.createTextNode("send"));
        send.addEventListener("click", () => {this.send_image_function()});
        control_div.appendChild(send);

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

        this.handleEvent("send_data", (_) => {this.send_function()});
        this.handleEvent("update_data",
                         ({data}) => {
                             console.log(data);
                             this.pad.loadJSON(data)})
        this.handleEvent("send_image", (_) => {this.send_image_function()});
    }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

