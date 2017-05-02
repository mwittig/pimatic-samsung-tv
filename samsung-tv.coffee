# The amazing dash-button plugin
module.exports = (env) ->

  Promise = env.require 'bluebird'
  SamsungRemote = require 'samsung-remote'
  commons = require('pimatic-plugin-commons')(env)


  # ###SamsungTvPlugin class
  class SamsungTvPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      @debug = @config.debug || false
      @remote = new SamsungRemote({
        ip: @config.host
      });
      @base = commons.base @, 'Plugin'

      # register devices
      deviceConfigDef = require("./device-config-schema")
      @framework.deviceManager.registerDeviceClass("SamsungTvPresence",
        configDef: deviceConfigDef.SamsungTvPresence,
        createCallback: (@config, lastState) =>
          new SamsungTvPresenceSensor(@config, @, lastState)
      )


  class SamsungTvPresenceSensor extends env.devices.PresenceSensor

    constructor: (@config, @plugin, lastState) ->
      @id = @config.id
      @name = @config.name
      @_contact = false
      @remote = @plugin.remote
      @debug = @plugin.debug || false
      @base = commons.base @, @config.class
      super()
      process.nextTick () =>
        @_requestUpdate()

    destroy: () ->
      @base.cancelUpdate()
      super()

    _requestUpdate: () =>
      @base.cancelUpdate()
      @base.debug "Requesting update"

      present = false
      @remote.isAlive (err) =>
        present = true if err?
        @base.debug "Presense state is #{present}"
        @_setPresence present
        @base.scheduleUpdate @_requestUpdate, @config.interval * 1000

    getPresence: () ->
      return new Promise.resolve @_presence

  # ###Finally
  # Create a instance of my plugin
  # and return it to the framework.
  return new SamsungTvPlugin