# Code hacked together for POC

_ = require 'underscore-plus'
path = require 'path'
fs = require 'fs-plus'

{$, ScrollView} = require 'atom-space-pen-views'
{Emitter, CompositeDisposable} = require 'atom'

module.exports =
class ImageEditorView extends ScrollView
  @content: ->
    @div class: 'draw-on-image', tabindex: -1, =>
      @div class: 'image-controls', outlet: 'imageControls', =>
        @a outlet: 'whiteColorButton', class: 'image-controls-color-white', value: '#fff', =>
          @text 'white'
        @a outlet: 'blackColorButton', class: 'image-controls-color-black', value: '#000', =>
          @text 'black'
        @a outlet: 'blueColorButton', class: 'image-controls-color-blue', value: '#1428fa', =>
          @text 'blue'
        @a outlet: 'yellowColorButton', class: 'image-controls-color-yellow', value: '#fafa28', =>
          @text 'yellow'
        @a outlet: 'greenColorButton', class: 'image-controls-color-green', value: '#64e614', =>
          @text 'green'
        @a outlet: 'redColorButton', class: 'image-controls-color-red', value: '#e62828', =>
          @text 'red'
        # 6 Colors, 3 Stroke Types, 3 Shape Types (Rect, Line, Free)
      @div class: 'image-container', =>
        @div class: 'image-container-cell', =>
          @canvas outlet: 'canvas', id: 'doi-canvas'
          @img outlet: 'image', id: 'doi-image'

  initialize: (@editor) ->
    super
    @prevX = 0
    @currX = 0
    @prevY = 0
    @currY = 0
    @flag = false
    @dot_flag = false
    @strokeColor = "black"
    @lineWidth = 4

    @emitter = new Emitter

  attached: ->
    @disposables = new CompositeDisposable

    @loaded = false
    @image.hide()
    @updateImageURI()

    @disposables.add @editor.onDidChange => @updateImageURI()
    @disposables.add atom.commands.add @element,
      'draw-on-image:reload': => @updateImageURI()

    @disposables.add atom.commands.add @element,
      'draw-on-image:save': => @saveImage()

    #atom.commands.add 'atom-text-editor', 'core:save',, (e) ->
      #e.preventDefault()
      #e.stopPropagation()
      #saveImage()

    @image.load =>
      @originalHeight = @image.height()
      console.log @originalHeight
      @originalWidth = @image.width()
      console.log @originalWidth

      @doicanvas = @canvas.get(0)
      @doicanvas.width = @originalWidth
      @doicanvas.height = @originalHeight
      @doicontext = @doicanvas.getContext "2d"
      @doicontext.drawImage @image.get(0), 0, 0

      @doicanvas.addEventListener "mousemove", (e) => @doifind('move', e)
      @doicanvas.addEventListener "mousedown", (e) => @doifind('down', e)
      @doicanvas.addEventListener "mouseup", (e) => @doifind('up', e)
      @doicanvas.addEventListener "mouseout", (e) => @doifind('out', e)

      @loaded = true
      @emitter.emit 'did-load'

    if @getPane()
      @imageControls.find('a').on 'click', (e) =>
        @setDrawColor $(e.target).attr 'value'

  onDidLoad: (callback) ->
    @emitter.on 'did-load', callback

  detached: ->
    @disposables.dispose()

  updateImageURI: ->
    @image.attr('src', "#{@editor.getURI()}?time=#{Date.now()}")

  getPane: ->
    @parents('.pane')[0]

  setDrawColor: (color) ->
    return unless @loaded and @isVisible() and color
    @strokeColor = color

  saveImage: ->
    # Save to the same format as source image
    fileext = path.extname(@editor.getURI());

    mimetype = 'image/jpeg'
    if (fileext == '.png')
      mimetype = 'image/png'

    dataUrl = @doicanvas.toDataURL(mimetype, 0.9);
    regex = /^data:.+\/(.+);base64,(.*)$/;

    matches = dataUrl.match(regex);
    ext = matches[1];
    data = matches[2];
    buffer = new Buffer(data, 'base64');
    fs.writeFileSync(@editor.getURI() + "_saved" + fileext, buffer);

  doifind: (res, e) ->
    if (res == 'down')
        @prevX = @currX
        @prevY = @currY
        @currX = e.clientX - @doicanvas.offsetLeft - $(@doicanvas).offset().left + 5
        @currY = e.clientY - @doicanvas.offsetTop - $(@doicanvas).offset().top + 25 + 5 #from the container

        @flag = true
        @dot_flag = true
        if (@dot_flag)
            @doicontext.beginPath()
            @doicontext.fillStyle = @strokeColor
            @doicontext.fillRect(@currX, @currY, 2, 2)
            @doicontext.closePath()
            @dot_flag = false

    if (res == 'up' || res == "out")
        @flag = false

    if (res == 'move')
        if (@flag)
            @prevX = @currX
            @prevY = @currY
            @currX = e.clientX - @doicanvas.offsetLeft - $(@doicanvas).offset().left + 5
            @currY = e.clientY - @doicanvas.offsetTop - $(@doicanvas).offset().top + 25 + 5 #from the container
            @draw()


  draw: ->
    @doicontext.beginPath();
    @doicontext.moveTo(@prevX, @prevY);
    @doicontext.lineTo(@currX, @currY);
    @doicontext.strokeStyle = @strokeColor;
    @doicontext.lineWidth = @lineWidth;
    @doicontext.stroke();
    @doicontext.closePath();
