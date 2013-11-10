define [
  'underscore'
], (_) ->

  # DOMStorageAdapter wraps the DOM Storage interface with namespaced
  # keys to avoid clobbering unrelated data.
  #
  # @see https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Storage
  #
  class DOMStorageAdapter

    # Initialize a DOMStorageAdapter object with a given namespace and scope.
    #
    # @param namespace [String] A key prefix used internally to identify keys managed by this DOMStorageAdapter instance.
    # @param scope [String] One of 'local', 'session', or 'global'.
    #
    constructor: (@namespace, @scope) ->
      @storage = @_storage @scope

    # Stringify a JSON object and store it under a key.
    #
    # @param key [String] The key (without namespace) to identify this object.
    # @param value [Object] The object to be stringified and stored.
    # @param serialize [Boolean] If explicitely changed to false, the value will be stored raw rather than stringified as JSON.
    # @return this
    #
    setItem: (key, value, serialize = true) ->
      @_registerKey key
      if serialize
        value = JSON.stringify( value.toJSON() )
      @storage.setItem @_namespacedKey(key), value
      return @

    # Retrieve a stored object identified by a key.
    #
    # @param key [String] The key (without namespace) to identify this object.
    # @return [Object] The object (deserialized by JSON.parse), or null if nothing was found.
    # @param deserialize [Boolean] If explicitely changed to false, the value will be returned as-is rather than parsed as JSON.
    #
    getItem: (key, deserialize = true) ->
      str = @storage.getItem( @_namespacedKey(key) )
      if str
        if deserialize then return JSON.parse(str) else return str
      else
        return null

    # Remove a stored object identified by a key.
    #
    # @param key [String] The key (without namespace) to identify this object.
    # @return this
    #
    removeItem: (key) ->
      @storage.removeItem @_namespacedKey(key)
      @_unregisterKey key
      @

    # Remove all items registered to this namespace
    # @return this
    #
    clear: ->
      _.each @_getKeys(), (key) =>
        @storage.removeItem @_namespacedKey(key)
      @_setKeys []
      @

    # Add an item to the stored list of keys managed by this namespace.
    #
    # @private
    # @param key [String] The key (without namespace) to identify this object.
    # @return this
    #
    _registerKey: (key) ->
      keys = @_getKeys()
      keys.push key
      @_setKeys _.uniq(keys)
      @

    # Remove an item from the stored list of keys managed by this namespace.
    #
    # @private
    # @param key [String] The key (without namespace) to identify this object.
    # @return this
    #
    _unregisterKey: (key) ->
      keys = _.reject @_getKeys(), (i) -> i == key
      @_setKeys keys
      @

    # Retrieve the stored list of keys managed by this namespace.
    #
    # @private
    # @return Array List of keys managed by this namespace.
    #
    _getKeys: ->
      str = @storage.getItem @_keysItem()
      if str
        return JSON.parse str
      else
        return []

    # Replace the stored list of keys managed by this namespace.
    #
    # @private
    # @param keys [Array] The full list of keys to be managed by this namespace, (not including the namespace prefix in each key).
    # @return this
    #
    _setKeys: (keys) ->
      @storage.setItem @_keysItem(), JSON.stringify(keys)
      @

    # Obtain a reference to the browser storage object for the specified scope.
    #
    # @private
    # @param scope [String] One of 'local', 'session', or 'global'.
    # @return A browser storage object
    # @throw Unknown scope for DOM Storage adapter
    #
    _storage: (scope) ->
      root = window ? global
      switch scope
        when 'local'
          return root.localStorage
        when 'global'
          return root.globalStorage
        when 'session'
          return root.sessionStorage
        else
          throw new Error 'Unknown scope for DOM Storage adapter'


    # @private
    # @return [String] The namespaced key to store the list of keys registered to this namespace.
    #
    _keysItem: -> @_namespacedKey 'keys'

    # @private
    # @param key [String] A key with no namespace
    # @return [String] The key, prefixed with the namespace associated with this DOMStorageAdapter instance
    #
    _namespacedKey: (key) -> "#{@namespace}_#{key}"
