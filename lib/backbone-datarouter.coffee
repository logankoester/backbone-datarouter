define [
  'require',
  'underscore',
  'backbone',
  'cache',
  'kinvey',
  'backbone-datarouter/authorize_kinvey'
], (require, _, Backbone, Cache, Kinvey, Authorize) ->

  # Use the Route class to construct handlers for your router and
  # register them to an application (or whatever object you want
  # to attach a routes table to).
  #
  # @example Map the #home URL hash to the view class "Home"
  #   new Route pattern: "#home", view: HomeView, app: MyApp
  #
  #
  # @example You can also use a simplified routing syntax if you load this module with _.extend
  #   _.extend myApp, require('router/route')
  #   myApp.route '#home': 'HomeView'
  #   myApp.route '#birds': 'BirdsView', collection: 'Birds'
  #
  class Route

    @defaults:
      cache: true
      spinner:
        show: -> $.mobile.loading 'show'
        hide: -> $.mobile.loading 'hide'
      authorize: (route) -> $.Deferred().resolve().promise()
      logger: Route.logger
      online: -> navigator.onLine

    # @property logger [Object] Optional logger dependency (such as npm's loglevel).
    @logger: console

    # Construct, validate, and then register a new route to an object.
    #
    # @extend Backbone.Events
    #
    # @note If possible, the route will be registered even in the presence of invalid options, which will simply be logged instead of throwing an error.
    #
    # @param options [Object] Routing options (some required).
    #
    # @option options collection [Object<Backbone.Collection>] An optional collection to fetch and pass into the view.
    # @option options cache [Boolean] If disabled, model & collection will ignore the local cache and attempt to fetch from the network instead.
    # @option options spinner [Object] Overload functions 'call' and 'hide' to use a custom loading animation.
    # @option options events [Object] Events hash for routing lifecycle.
    # @option options authorize [Function] Optional function returning a promise. Routing will continue when fulfilled, or abort when rejected. This route instance will be passed as a parameter.
    # @option options logger [Object] Optional logger dependency (such as npm's loglevel). Updates Route.logger if set (affects all routes).
    # @option options online [Function] Function to use when checking if the app is in its online state. Return true for online, false for offline
    # @option options region [Function] A function that returns an object implementing show(view), given @options.app as a parameter.
    #
    # @note The model will be inferred the pattern matches an 'id' param, and a single model will be fetched for the view instead.
    # @note If @options.region is omitted, the route will simply call render() on a new instance of the view.
    #
    constructor: (@options) ->
      _.extend @, Backbone.Events

      @options ||= {}
      @options = _.extend _.clone(Route.defaults), @options
      Route.logger = @options.logger if @options.logger

      @on 'all', (event) -> Route.logger.debug "Route event #{event}"

      if errors = !@validate(@options)
        Route.logger.error "Route has invalid options", errors, @
      @register @options['app'], @options['pattern']

    # A list of errors the user may need to deal with after routing is finished.
    # This does not include validation errors, which are just logged immediately then discarded.
    # @return [Array] A list of error objects collected by this route
    #
    getErrors: -> @errors ||= []

    # Add an error object to the list for users to deal with after routing is finished.
    # @private
    #
    pushError: (error) -> @getErrors().push error

    # Check if a route options hash is valid.
    #
    # @param options [Object] An options hash
    # @return [Boolean] false when all options are valid
    # @return [Array] One or more error strings
    #
    validate: (options) ->
      errors = []

      if !options['pattern'] then errors.push 'Missing option "pattern"'
      if !options['view'] then errors.push 'Missing option "view"'
      if !options['app'] then errors.push 'Missing option "app"'
      if options['spinner']
        if !_.isFunction( options['spinner']['show'] )
          errors.push "spinner.show is not a function"
        if !_.isFunction( options['spinner']['hide'] )
          errors.push "spinner.hide is not a function"
      if options['model'] && options['collection']
        errors.push 'Route does not support fetching both a model and collection'

      _.isEmpty(errors) ? false : errors

    # Sets the current instance's @_handler method to a named property
    # of app.routes. The routes object will be created if it does not
    # exist.
    #
    # @param app [Object] Some object to contain your routing table.
    # @param pattern [String] The url pattern to match.
    # @param events [String] Named event(s) to trigger this route (defaults to 'bC').
    # @param argsre [Boolean] If true (?:[?](.*))?$ will be appended (default)
    #
    register: (app, pattern, events = 'bC', argsre = true) ->
      app.routes ||= {}
      app.routes[pattern] =
        handler: @_handler
        route: @
        events: 'bC'
        argsre: true

    # Handles the routing behavior when actually triggered.
    # Called by jquerymobile-router on the registered events.
    #
    _handler: (type, match, ui, page, e) =>
      e.preventDefault()
      @_eventWrapper ui
      @trigger 'before'

      # @todo Decouple router adapter from app object
      params = @options.app.router.getParams(match['input'])

      @options.authorize(@)
        .done =>
          if @options.collection
            if id = params['id']
              model = @_newCollectionModel @options.collection, id

              @once 'model:ready', (model, response, options) =>
                @_showView model: model, params: params
                @trigger 'after'

              @once 'model:error', (model, xhr, options) =>
                # @todo Properly handle this kind of error
                Route.logger.error 'model:error', model, xhr, options
                @trigger 'after'

              @_fetchModel model, @options.cache
            else
              Route.logger.info 'Fetching collection', @options.collection
              collection = new @options.app.Data.Collections[@options.collection]

              @once 'collection:ready', (collection, response, options) =>
                @_showView collection: collection, params: params
                @trigger 'after'

              @once 'collection:error', (collection, xhr, options) =>
                # @todo Properly handle this kind of error
                Route.logger.error 'collection:error', collection, xhr, options
                @trigger 'after'

              @_fetchCollection collection, @options.collection, @options.cache
          else
            @trigger 'after'
            @_showView params: params
        .fail =>
          Route.logger.error 'Router failed authorization'
          @trigger 'after'
          @_showView params: params

    # Instantiate a new model if an associated collection is known
    #
    # @param collection [Object<Backbone.Collection>] A collection associated with a model.
    # @param id [String] The _id attribute to set on the model, if any
    #
    #
    _newCollectionModel: (collection, id = null) ->
      model = new @options.app.Data.Collections[collection].prototype.model
        _id: id

    # Fetches a model through the localStorage cache, or directly from
    # the network, then triggers a local event when finished.
    #
    # This event might be any of:
    #
    #   * model:ready, model [, response, options]
    #   * model:error, model, xhr, options
    #
    # @param model [Object<Backbone.Model>] A model instance with an idAttribute set.
    # @param useCache [Boolean] If false, skip the local cache and rely on the network.
    #
    #
    _fetchModel: (model, useCache) ->
      if useCache
        id = model.get model.idAttribute
        @options.app.Data.cache.getModel @options.collection, id, (model) =>
          Route.logger.debug 'Model ready', model
          @trigger 'model:ready', model
      else
        model.fetch
          success: (model, response, options) =>
            @trigger 'model:ready', model, response, options
          error: (model, xhr, options) =>
            @trigger 'model:error', model, xhr, options

    # Fetches a collection through the localStorage cache, or directly from
    # the network, then triggers a local event when finished.
    #
    # This event might be any of:
    #
    #   * collection:ready, collection [, response, options]
    #   * collection:error, collection, xhr, options
    #
    # @param collection [Object<Backbone.Collection>] A Backbone collection.
    # @param collectionName [String] The key to lookup this collection in the cache.
    # @param useCache [Boolean] If false, skip the local cache and rely on the network.
    #
    # @note collectionName is allowed to be null if useCache is false.
    #
    #
    _fetchCollection: (collection, collectionName, useCache) ->
      if useCache
        @options.app.Data.cache.fetchCollection collection, collectionName, (collection) =>
          @trigger 'collection:ready', collection
      else
        collection.fetch
        success: (collection, response, options) =>
          @trigger 'collection:ready', collection, response, options
        error: (collection, xhr, options) =>
          @trigger 'collection:error', model, xhr, options

    # Instructs the region manager to show a new instance of the view,
    # or calls its view.render() method if a region is not set.
    #
    # @param opts [Object] Options hash to pass into the view (if any)
    #
    _showView: (opts = null) ->
      try
        view = new @options.view(opts)
        if region = @_getRegion()
          region.show(view)
        else
          view.render()
      catch error
        if error.name == 'TemplateNotFoundError'
          Route.logger.debug "View (instance of '#{view.constructor.name}') attempted to render without a template."
        Route.logger.error error.name, error.message

    # Get the region responsible for showing the view associated with this route, if any.
    #
    # @return region Object An object implementing a show() method which expects a view.
    #
    _getRegion: ->
      if @options.region
        @options.region( @options.app )
      else
        undefined

    # Wrap built-in hooks around routing lifecycle events
    #
    # @param ui [Object] The adapter's ui object (to resolve when finished)
    #
    _eventWrapper: (ui) ->

      @once 'before', =>
        if @options.spinner then @options.spinner.show()
        @_registerEvents()
        @trigger 'begin'

      @once 'after', =>
        @trigger 'finish'
        @_unregisterEvents()
        ui.bCDeferred.resolve()
        if @options.spinner then @options.spinner.hide()

    # Start listening to events passed in via the route's options hash.
    #
    _registerEvents: ->
      unless _.isEmpty(@options.events)
        _.each @options.events, (value, key, list) =>
          @listenTo @, key, value

    # Stop listening to events passed in via the route's options hash.
    #
    _unregisterEvents: ->
      unless _.isEmpty(@options.events)
        _.each @options.events, (value, key, list) =>
          @stopListening @, key, value

  {
    Route: Route
    Cache: Cache
    Authorize: Authorize
    route: (glue, options={}) ->
      glue = _.pairs(glue)[0]
      new Route _.extend options,
        app: @
        pattern: glue[0]
        view: glue[1]
  }
