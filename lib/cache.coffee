define [
  'backbone',
  'moment'
], (Backbone) ->
  class Cache
    constructor: (app) ->
      @storage = window.localStorage
      @monitorConnection()
      @expired = false
      @app = app
      _.extend @, Backbone.Events

    monitorConnection: ->
      $(window).on
        offline: =>
          console.log 'Application is now offline'
        online: =>
          console.log 'Application is now online'
          @tryCache()

    tryCache: ->
      console.log 'Trying cache...'
      timestamp = moment.unix @storage.getItem('expireAt')
      if moment().diff(timestamp) > 0
        console.log 'Cache expired!'
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
              console.log 'Fetched resource from network', resource
              @expired = false

              @incrementExpiration()
              @trigger "miss:#{key}:success", instance
              callback(resource) if callback

            error: (resource, response, options) =>
              console.log 'Could not fetch resource.'
              @trigger "miss:#{key}:error", instance
              callback(resource) if callback
        else
          console.log 'Fetched resource from cache'
          instance.set JSON.parse( @storage.getItem(key) )
          @trigger "hit:#{key}:online", instance
          callback(instance) if callback
      else
        console.log 'Fetch called while offline, falling back to cache'
        instance.set JSON.parse( @storage.getItem(key) )
        @trigger "hit:#{key}:offline", instance
        callback(instance) if callback
