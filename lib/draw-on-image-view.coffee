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

        # Tools
        @a outlet: 'pen', class: 'tool-sel image-controls-tool-sel-pen', value: 'pen', =>
          @text 'pen'
        @a outlet: 'rect', class: 'tool-sel image-controls-tool-sel-rect', value: 'rect', =>
          @text 'rect'

        # lineWidth
        @a outlet: 'thinLine', class: 'line-sel image-controls-line-sel-thin', value: 1, =>
          @text 'thin line'
        @a outlet: 'mediumLine', class: 'line-sel image-controls-line-sel-medium', value: 4, =>
          @text 'medium line'

        # Colors
        @input outlet: 'colorSelectionButton', type: 'color', class: 'image-controls-color-selection'
        @a outlet: 'whiteColorButton', class: 'color-sel image-controls-color-white', value: '#ffffff', =>
          @text 'white'
        @a outlet: 'blackColorButton', class: 'color-sel image-controls-color-black', value: '#000000', =>
          @text 'black'
        @a outlet: 'blueColorButton', class: 'color-sel image-controls-color-blue', value: '#1428fa', =>
          @text 'blue'
        @a outlet: 'yellowColorButton', class: 'color-sel image-controls-color-yellow', value: '#fafa28', =>
          @text 'yellow'
        @a outlet: 'greenColorButton', class: 'color-sel image-controls-color-green', value: '#64e614', =>
          @text 'green'
        @a outlet: 'redColorButton', class: 'color-sel image-controls-color-red', value: '#e62828', =>
          @text 'red'

      @div class: 'image-container', =>
        @div class: 'image-container-cell', =>
          @canvas outlet: 'canvas', id: 'doi-canvas', class: 'canvas'
          @canvas outlet: 'tmp_canvas', id: 'tmp-canvas', class: 'tmp-canvas'
          @img outlet: 'image', id: 'doi-image'

  initialize: (@editor) ->
    super
    @prevX = 0
    @currX = 0
    @prevY = 0
    @currY = 0
    @x0 = 0
    @y0 = 0
    @isDrawing = false
    @isDot = false

    @tool = 'pen'
    @lineWidth = 4
    @strokeColor = '#64e614'

    @emitter = new Emitter

  attached: ->
    @disposables = new CompositeDisposable

    @loaded = false
    @image.hide()
    @updateImageURI()

    @disposables.add @editor.onDidChange => @updateImageURI()
    @disposables.add atom.commands.add @element,
      'draw-on-image:reload': => @updateImageURI()

    @image.load =>
      @originalHeight = @image.height()
      @originalWidth = @image.width()

      @doicanvas = @canvas.get(0)
      @doicanvas.width = @originalWidth
      @doicanvas.height = @originalHeight
      @doicontext = @doicanvas.getContext "2d"
      @doicontext.drawImage @image.get(0), 0, 0

      @tmpcanvas = @tmp_canvas.get(0)
      @tmpcanvas.width = @originalWidth
      @tmpcanvas.height = @originalHeight
      @tmpcontext = @tmpcanvas.getContext "2d"

      @tmpcanvas.addEventListener "mousemove", (e) => @drawDispatcher('move', e)
      @tmpcanvas.addEventListener "mousedown", (e) => @drawDispatcher('down', e)
      @tmpcanvas.addEventListener "mouseup", (e) => @drawDispatcher('up', e)
      @tmpcanvas.addEventListener "mouseout", (e) => @drawDispatcher('out', e)

      @loaded = true
      @emitter.emit 'did-load'

    if @getPane()
      @disposables.add atom.tooltips.add @pen[0], title: "Draw with pen"
      @disposables.add atom.tooltips.add @rect[0], title: "Draw rectangle"

      @disposables.add atom.tooltips.add @thinLine[0], title: "Thin"
      @disposables.add atom.tooltips.add @mediumLine[0], title: "Medium"
      @disposables.add atom.tooltips.add @colorSelectionButton[0], title: "Select custom color"

      @setDrawColor(@strokeColor)
      @initToolSelections()

      @imageControls.find('.tool-sel').on 'click', (e) =>
        $(".tool-sel").each (index, element) =>
          $(element).removeClass('selected')
        $(e.target).addClass('selected')
        @setTool $(e.target).attr 'value'

      @imageControls.find('.line-sel').on 'click', (e) =>
        $(".line-sel").each (index, element) =>
          $(element).removeClass('selected')
        $(e.target).addClass('selected')
        @setLineWidth $(e.target).attr 'value'

      @imageControls.find('.color-sel').on 'click', (e) =>
        $(".color-sel").each (index, element) =>
          $(element).removeClass('selected')
        $(e.target).addClass('selected')
        @setDrawColor $(e.target).attr 'value'
      @colorSelectionButton.change =>
        @setDrawColor @colorSelectionButton[0].value

  onDidLoad: (callback) ->
    @emitter.on 'did-load', callback

  detached: ->
    @disposables.dispose()

  updateImageURI: ->
    @image.attr('src', "#{@editor.getURI()}?time=#{Date.now()}")

  getPane: ->
    @parents('.pane')[0]

  initToolSelections: ->
    # TODO: make generic and/or restore from settings
    $(".image-controls-tool-sel-pen").addClass('selected')
    $(".image-controls-line-sel-medium").addClass('selected')
    $(".image-controls-color-green").addClass('selected')


  setTool: (tool) ->
    return unless @isVisible() and tool
    @tool = tool

  setLineWidth: (lineWidth) ->
    return unless @isVisible() and lineWidth
    @lineWidth = lineWidth

  setDrawColor: (color) ->
    return unless @isVisible() and color

    @strokeColor = color
    @colorSelectionButton[0].value = color

  saveImage: ->
    savePath = @proposeSavePath();
    @saveImageAs(savePath)

  proposeSavePath: ->
    parsedPath = path.parse(@editor.getURI())
    return parsedPath.dir + path.sep + parsedPath.name + "_saved" + parsedPath.ext

  saveImageAs: (savePath) ->
    @commitChanges()
    mimetype = @getMimetype(savePath)
    dataUrl = @doicanvas.toDataURL(mimetype, 0.9)
    regex = /^data:.+\/(.+);base64,(.*)$/

    matches = dataUrl.match(regex)
    data = matches[2]
    buffer = new Buffer(data, 'base64')
    fs.writeFileSync(savePath, buffer)

  getMimetype: (savePath) ->
    # Save to the same format as source image
    fileext = path.extname(savePath)
    mimetype = 'image/jpeg'
    if (fileext.toLowerCase() == '.png')
      mimetype = 'image/png'
    return mimetype

  commitChanges: ->
    @doicontext.drawImage(@tmpcanvas, 0, 0)
    @undoLastChange()

  undoLastChange: ->
    @tmpcontext.clearRect(0, 0, @tmpcanvas.width, @tmpcanvas.height)

  drawDispatcher: (action, e) ->
    if e.which == 3 # filter out right-clicks
      return
    switch @tool
      when 'pen' then @drawPen(action, e)
      when 'rect' then @drawRect(action, e)

  drawPen: (action, e) ->
    if (action == 'down')
        @commitChanges()
        @prevX = @currX
        @prevY = @currY
        @currX = @calcX(e.clientX)
        @currY = @calcY(e.clientY)

        @isDrawing = true
        @isDot = true
        if (@isDot)
            @tmpcontext.beginPath()
            @tmpcontext.fillStyle = @strokeColor
            @tmpcontext.fillRect(@currX, @currY, @lineWidth, @lineWidth)
            @tmpcontext.closePath()
            @isDot = false

    if (action == 'up' || action == "out")
        if !@isDrawing
          return
        @isDrawing = false

    if (action == 'move')
        if (@isDrawing)
            @prevX = @currX
            @prevY = @currY
            @currX = @calcX(e.clientX)
            @currY = @calcY(e.clientY)
            @draw()

  calcX: (x) ->
    return x - @tmpcanvas.offsetLeft - $(@tmpcanvas).offset().left

  calcY: (y) ->
    return y - @tmpcanvas.offsetTop - $(@tmpcanvas).offset().top

  draw: ->
    @tmpcontext.beginPath()
    @updateCanvasSettings()
    @tmpcontext.moveTo(@prevX, @prevY)
    @tmpcontext.lineTo(@currX, @currY)
    @tmpcontext.stroke()
    @tmpcontext.closePath()

  updateCanvasSettings: ->
    @tmpcontext.strokeStyle = @strokeColor
    @tmpcontext.lineWidth = @lineWidth

  drawRect: (action, e) ->
    if (action == 'down')
        @commitChanges()
        @updateCanvasSettings()
        @currX = @calcX(e.clientX)
        @currY = @calcY(e.clientY)
        @x0 = @currX
        @y0 = @currY

        @isDrawing = true

    if (action == 'up' || action == "out")
        if !@isDrawing
          return
        @isDrawing = false

    if (action == 'move')
        if !@isDrawing
          return

        @currX = @calcX(e.clientX)
        @currY = @calcY(e.clientY)

        x = Math.min(@currX, @x0)
        y = Math.min(@currY, @y0)
        w = Math.abs(@currX - @x0)
        h = Math.abs(@currY - @y0)
        @tmpcontext.clearRect(0, 0, @doicanvas.width, @doicanvas.height)
        if (!w || !h)
          return
        @tmpcontext.strokeRect(x, y, w, h)
