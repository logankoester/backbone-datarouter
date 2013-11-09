define [
  'underscore',
  'backbone',
  'moment',
  'backbone-datarouter/dom_storage_adapter'
], (_, Backbone, moment, DOMStorageAdapter) ->
  class Cache

    @defaults:
      logger: Cache.logger
      namespace: null

    # @property logger [Object] Optional logger dependency (such as npm's loglevel).
    @logger: console

    constructor: (app, @options) ->
      @options ||= {}
      @options = _.extend @options, Cache.defaults

      Cache.logger = @options.logger if @options.logger

      unless @options.storage
        @storage = new DOMStorageAdapter @options.namespace, 'local'

      @expired = false
      @app = app
      _.extend @, Backbone.Events

    tryCache: ->
      Cache.logger.info 'Trying cache...'
      timestamp = moment.unix @storage.getItem('expireAt')
      if moment().diff(timestamp) > 0
        console.info 'Cache expired!'
        @expire()

    expire: ->
      @expired = true
      @

    clear: ->
      @storage.clear()
      @

    # Serialize a model or collection into storage
    set: (key, resource) ->
      @storage.setItem key, JSON.stringify( resource.toJSON() )

    expiresIn: ->
      moment.unix( @storage.getItem('expireAt') ).fromNow()

    incrementExpiration: ->
      @storage.setItem 'expireAt', moment().add(@app.Settings.cache.lifespan...).unix()

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
              @set key, resource
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
          instance.set JSON.parse( @storage.getItem(key) )
          @trigger "hit:#{key}:online", instance
          callback(instance) if callback
      else
        Cache.logger.info 'Fetch called while offline, falling back to cache'
        instance.set JSON.parse( @storage.getItem(key) )
        @trigger "hit:#{key}:offline", instance
        callback(instance) if callback
