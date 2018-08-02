# #pimatic-samsung-tv plugin config options
module.exports = {
  title: "pimatic-samsung-tv plugin config options"
  type: "object"
  properties:
    debug:
      description: "Debug mode. Writes debug messages to the pimatic log, if set to true."
      type: "boolean"
      default: false
    host:
      description: "IP address of the Samsung TV"
      type: "string"
    port:
      description: "The port to use"
      type: "number"
      default: 55000
}