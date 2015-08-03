# Code hacked together for POC

{$} = require 'atom-space-pen-views'
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

    @subscriptions.add atom.commands.add 'atom-workspace', 'core:undo', (e) =>
      editorView = @handleCoreEvent(e)
      editorView.undoLastChange() if editorView

    @subscriptions.add atom.commands.add 'atom-workspace', 'core:save', (e) =>
      editorView = @handleCoreEvent(e)
      editorView.saveImage() if editorView

    @subscriptions.add atom.commands.add 'atom-workspace', 'core:save-as', (e) =>
      editorView = @handleCoreEvent(e)
      @saveContentAs(editorView) if editorView

  handleCoreEvent: (event) ->
    editor = atom.workspace.getActivePaneItem()
    if @isEqual(editor)
      event.preventDefault()
      event.stopPropagation()
      editorView = $(atom.views.getView(editor)).view()
      return editorView if editorView.loaded

  saveContentAs: (editorView) ->
    saveOptions = {}
    saveOptions.defaultPath ?= editorView.proposeSavePath()
    newItemPath = atom.showSaveDialogSync(saveOptions)
    if newItemPath
      try
        editorView.saveImageAs(newItemPath)
      catch error
        @addWarningWithPath(newItemPath)

  addWarningWithPath: (filePath) ->
    atom.notifications.addWarning('Unable to save image to : "' + filePath + '"')

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
