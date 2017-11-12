// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import Vue from "vue/dist/vue.common.js"

import {Socket} from "phoenix"

let socket = new Socket("/socket")
socket.connect()

let app = new Vue({
  el: "#app",
  data: {
    trade_direction: "buy",
    base_amount: "1000",
    quote_currency: "eur",
    channel: null,
  },

  mounted() {
    this.$el.querySelector('[contenteditable]').innerText = this.base_amount;
    this.subscribe()
  },

  watch: {
    trade_direction: function(newValue) { this.subscribe() },
    quote_currency: function(newValue) { this.subscribe() },
  },

  methods: {
    update(event) {
      this.base_amount = event.target.innerText
    },

    tick(payload) {
      console.log(payload)
    },

    subscribe() {
      if (this.channel) {
        this.channel.leave()
      }
      let topic = `info:${this.trade_direction}:${this.quote_currency}`
      this.channel = socket.channel(topic, {})
      this.channel.on("tick", this.tick)
      this.channel.join()
        .receive("ok", resp => { console.log("Successfully joined " + topic, resp) })
        .receive("error", resp => { console.log("Unable to join " + topic, resp) })
    },
  },
});
