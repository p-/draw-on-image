# Code hacked together for POC

path = require 'path'
fs = require 'fs-plus'
{File} = require 'pathwatcher'
{CompositeDisposable} = require 'atom'

# Editor model for an image file
module.exports =
class ImageEditor
  atom.deserializers.add(this)

  @deserialize: ({filePath}) ->
    if fs.isFileSync(filePath)
      new ImageEditor(filePath)
    else
      console.warn "Could not deserialize image editor for path '#{filePath}' because that file no longer exists"

  constructor: (filePath) ->
    @file = new File(filePath)
    @subscriptions = new CompositeDisposable()

  serialize: ->
    {filePath: @getPath(), deserializer: @constructor.name}

  getViewClass: ->
    require './draw-on-image-view'

  onDidChange: (callback) ->
    changeSubscription = @file.onDidChange(callback)
    @subscriptions.add(changeSubscription)
    changeSubscription

  onDidChangeTitle: (callback) ->
    renameSubscription = @file.onDidRename(callback)
    @subscriptions.add(renameSubscription)
    renameSubscription

  destroy: ->
    @subscriptions.dispose()

  getTitle: ->
    if filePath = @getPath()
      path.basename(filePath)
    else
      'untitled'

  getURI: -> @getPath()

  getPath: -> @file.getPath()

  isEqual: (other) ->
    other instanceof ImageEditor and @getURI() is other.getURI()
