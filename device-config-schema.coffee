module.exports = {
  title: "pimatic-samsung-tv device config schemas"
  SamsungTvPresence:
    title: "Samsung TV Presence Sensor"
    type: "object"
    extensions: ["xLink"]
    properties: {
      interval:
        description: "The time interval in seconds (minimum 10) at which lock state shall be read"
        type: "number"
        default: 30
        minimum: 10
    }
}