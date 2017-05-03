# The amazing dash-button plugin
module.exports = (env) ->

  Promise = env.require 'bluebird'
  SamsungRemote = require 'samsung-remote'
  commons = require('pimatic-plugin-commons')(env)
  M = env.matcher


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
      
      @framework.ruleManager.addActionProvider(new SamsungTvActionProvider(@framework, @config))

  class SamsungTvActionProvider extends env.actions.ActionProvider
    
    constructor: (@framework, @config) ->
      
    parseAction: (input, context) =>
      retVal = null
      commandTokens = null
      fullMatch = no

      setCommand = (m, tokens) => commandTokens = tokens
      onEnd = => fullMatch = yes
      
      # Action predicate format: 'send samsungTV "[IP] <command>"'
      m = M(input, context)
        .match("send samsungTV ")
        .matchStringWithVars(setCommand)
      
      if m.hadMatch()
        match = m.getFullMatch()
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new SamsungTvActionHandler(@framework, @config, commandTokens)
        }
      else
        return null
        
  class SamsungTvActionHandler extends env.actions.ActionHandler
  
    constructor: (@framework, @config, @commandTokens) ->
      
    executeAction: (simulate) =>
      @framework.variableManager.evaluateStringExpression(@commandTokens).then( (command) =>
        if simulate
          # just return a promise fulfilled with a description about what we would do.
          return __("would send Samsung remote command: \"%s\"", command)
        else
          # string can be of format "[IP] <command>", if IP is omitted the config.host value will be used. Overriding allows for operating multiple Samsung devices in the home
          args = command.split " ", 2
          command = args.pop()
          remoteConfig = {
            ip: args[0] ? @config.host
          }
          
          remote = new SamsungRemote(remoteConfig)
          # #############################################################
          # ### Promisification and handling of err callback function needs review ###
          # #############################################################
          return new Promise( (resolve, reject) =>
            return remote.send(command, (err) => # <- 
              if err
                return reject __("Command: \"%s\", returned an error: \"%s\"", command, err)
              else
                return resolve __("Succesfully sent command: \"%s\"", command)
            )
          )
          # #############################################################
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