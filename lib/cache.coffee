define [
  'underscore',
  'backbone',
  'moment',
  'backbone-datarouter/dom_storage_adapter'
], (_, Backbone, moment, DOMStorageAdapter) ->
  class Cache

    @defaults:
      logger: Cache.logger
      namespace: 'cache'
      online: -> navigator.onLine

    # @property logger [Object] Optional logger dependency (such as npm's loglevel).
    @logger: console

    constructor: (app, @options) ->
      @options ||= {}
      @options = _.extend _.clone(Cache.defaults), @options

      Cache.logger = @options.logger if @options.logger

      unless @options.storage
        @storage = new DOMStorageAdapter @options.namespace, 'local'

      @online = @options.online

      @expired = false
      @app = app
      _.extend @, Backbone.Events

    tryCache: ->
      Cache.logger.info 'Trying cache...'
      if @options.online()
        timestamp = moment.unix @storage.getItem('expireAt', false)
        if !timestamp || moment().diff(timestamp) > 0
          Cache.logger.info 'Cache expired!'
          @expire()
      else
        Cache.logger.info 'Offline mode, preserving cache'
        @incrementExpiration()
      @

    expire: ->
      @expired = true
      @

    clear: ->
      @storage.clear()
      @

    expiresIn: ->
      moment.unix( @storage.getItem('expireAt', false) ).fromNow()

    incrementExpiration: ->
      expireAt = moment().add(@app.Settings.cache.lifespan...).unix()
      @storage.setItem 'expireAt', expireAt, false

    preloadFinished: ->
      _.every @app.Settings.cache.preloads, (resource) =>
        _.contains @preloaded, resource

    preload: (callback) ->
      @preloaded = []

      _.each @app.Settings.cache.preloads, (resource) =>
        @once "miss:#{resource}:success", ->
          @preloaded.push resource
          if @preloadFinished() and callback then callback.call()
        @fetchCollection new @app.Data.Collections[resource], resource
      @

    humanStatus: ->
      # Returns a sentence about the state of the cached data
      if @expired
        'Data may be out of data.'
      else
        "Checking for updated data in #{@expiresIn()}."

    getModel: (collectionName, id, callback) ->
      collection = new @app.Data.Collections[collectionName]
      @fetchCollection collection, collectionName, (c) ->
        callback( c.get(id) ) if callback

    fetchCollection: (instance, key, callback) ->
      @tryCache()
      Cache.logger.info 'Fetching resource'

      if @expired
        instance.fetch
          offline: false
          refresh: false
          success: (resource, response, options) =>
            @storage.setItem key, resource
            Cache.logger.info 'Fetched resource from network', resource
            @expired = false

            @incrementExpiration()
            @trigger "miss:#{key}:success", instance
            callback(resource) if callback

          error: (resource, response, options) =>
            Cache.logger.info 'Could not fetch resource.'
            @trigger "miss:#{key}:error", instance
            callback(resource) if callback
      else
        Cache.logger.info 'Fetched resource from cache'
        instance.set @storage.getItem(key)
        @trigger "hit:#{key}:online", instance
        callback(instance) if callback
