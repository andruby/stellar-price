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
import VueCookie from "vue-cookie"

// Tell Vue to use the plugin
Vue.use(VueCookie);

import {Socket} from "phoenix"

// Add smooth scrolling for anchor links
import SmoothScroll from "smooth-scroll"
var scroll = new SmoothScroll('[data-smoothscroll]');

let socket = new Socket("/socket")
socket.connect()

Vue.component('route-line', {
  template: '#route-line'
})

let round = function(amount, currency) {
  if (currency == "eur" || currency == "usd") {
    return Math.round(amount*100)/100
  } else {
    return Math.round(amount*100000000)/100000000
  }
}

let app = new Vue({
  el: "#app",
  data: {
    trade_direction: "buy",
    base_amount: "1000",
    base_currency: "xlm",
    quote_currency: "usd",
    channel: null,
    route: [],
    allTicks: [],
  },

  mounted() {
    this.loadState()
    this.$el.querySelector('[contenteditable]').innerText = this.base_amount
    this.subscribeSpecificRoute()
    this.subscribeAll()
  },

  watch: {
    trade_direction: function(newValue) { this.subscribeSpecificRoute(); this.stateChanged() },
    quote_currency: function(newValue) { this.subscribeSpecificRoute(); this.stateChanged() },
    base_amount: function(newValue) { this.stateChanged() }
  },

  computed: {
    trades: function() {
      let route = this.route.slice()
      if (route.length == 0) {
        return []
      }
      if (this.trade_direction == "buy") {
        let base_amount = this.base_amount
        return route.reverse().map(function(best_price) {
          best_price.base_amount = round(base_amount, best_price.base_currency)
          let quote_amount = base_amount * best_price.ask
          best_price.quote_amount = round(quote_amount, best_price.quote_currency)
          base_amount = quote_amount
          return best_price
        }).reverse()
      } else {
        // selling
        let base_amount = this.base_amount
        return route.map(function(best_price) {
          best_price.base_amount = round(base_amount, best_price.base_currency)
          let quote_amount = base_amount * best_price.bid
          best_price.quote_amount = round(quote_amount, best_price.quote_currency)
          base_amount = quote_amount
          return best_price
        })
      }
    },
  },

  methods: {
    update(event) {
      this.base_amount = event.target.innerText
    },

    subscribeSpecificRoute() {
      this.route = []
      if (this.channel) {
        this.channel.leave()
      }
      let topic = `info:${this.trade_direction}:${this.base_currency}:${this.quote_currency}`
      this.channel = socket.channel(topic, {})
      this.channel.on("tick", (payload) => { this.route = payload.route })
      this.channel.join()
        .receive("ok", resp => { console.log("Successfully joined " + topic, resp) })
        .receive("error", resp => { console.log("Unable to join " + topic, resp) })
    },

    subscribeAll() {
      let all_channel = socket.channel("info:all", {})
      all_channel.on("tick", (payload) => {
        let tick_index = this.allTicks.findIndex((tick) => {
          return tick.exchange_name == payload.exchange_name && tick.base_currency == payload.base_currency && tick.quote_currency == payload.quote_currency
        })
        if (tick_index > -1) {
          this.allTicks[tick_index] = payload
        } else {
          this.allTicks.push(payload)
        }
        this.allTicks.sort((a, b) => {
          return a.base_currency.localeCompare(b.base_currency) * (-1) ||
                 a.quote_currency.localeCompare(b.quote_currency) * (-1) ||
                 b.bid.toString().localeCompare(a.bid.toString()) ||
                 b.ask.toString().localeCompare(a.ask.toString()) ||
                 a.exchange_name.localeCompare(b.exchange_name)
        })
      })
      all_channel.join()
        .receive("ok", resp => { console.log("Successfully joined info:all", resp) })
        .receive("error", resp => { console.log("Unable to join info:all", resp) })

    },

    stateChanged() {
      Vue.cookie.set('base_amount', this.base_amount, { expires: '1Y' })
      Vue.cookie.set('trade_direction', this.trade_direction, { expires: '1Y' })
      Vue.cookie.set('base_currency', this.base_currency, { expires: '1Y' })
      Vue.cookie.set('quote_currency', this.quote_currency, { expires: '1Y' })
    },

    loadState() {
      if (Vue.cookie.get('base_amount')) { this.base_amount = Vue.cookie.get('base_amount') }
      if (Vue.cookie.get('trade_direction')) { this.trade_direction = Vue.cookie.get('trade_direction') }
      if (Vue.cookie.get('base_currency')) { this.base_currency = Vue.cookie.get('base_currency') }
      if (Vue.cookie.get('quote_currency')) { this.quote_currency = Vue.cookie.get('quote_currency') }
    },
  },
});
