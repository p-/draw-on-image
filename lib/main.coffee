# Code hacked together for POC

path = require 'path'
_ = require 'underscore-plus'
ImageEditor = require './draw-on-image'

module.exports =
  activate: ->
    @openerDisposable = atom.workspace.addOpener(openURI)

    atom.workspace.add

  deactivate: ->
    @openerDisposable.dispose()

  consumeStatusBar: (statusBar) ->
    ImageEditorStatusView = require './draw-on-image-status-view'
    view = new ImageEditorStatusView(statusBar)
    view.attach()

# Those file types are currently supported
imageExtensions = ['.jpeg', '.jpg', '.png']
openURI = (uriToOpen) ->
  uriExtension = path.extname(uriToOpen).toLowerCase()
  if _.include(imageExtensions, uriExtension)
    new ImageEditor(uriToOpen)
