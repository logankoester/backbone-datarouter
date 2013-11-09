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

    # @property logger [Object] Optional logger dependency (such as npm's loglevel).
    @logger: console

    constructor: (app, @options) ->
      @options ||= {}
      @options = _.extend Cache.defaults, @options

      Cache.logger = @options.logger if @options.logger

      unless @options.storage
        @storage = new DOMStorageAdapter @options.namespace, 'local'

      @expired = false
      @app = app
      _.extend @, Backbone.Events

    tryCache: ->
      Cache.logger.info 'Trying cache...'
      timestamp = moment.unix @storage.getItem('expireAt', false)
      if moment().diff(timestamp) > 0
        Cache.logger 'Cache expired!'
        @expire()

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
      if navigator.onLine
        @tryCache()

        if @expired
          instance.fetch
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
      else
        Cache.logger.info 'Fetch called while offline, falling back to cache'
        instance.set @storage.getItem(key)
        @trigger "hit:#{key}:offline", instance
        callback(instance) if callback
