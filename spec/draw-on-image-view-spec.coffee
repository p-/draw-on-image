{View, $} = require 'atom-space-pen-views'
fs = require 'fs-plus'
ImageEditorView = require '../lib/draw-on-image-view'
ImageEditor = require '../lib/draw-on-image'

describe "ImageEditorView", ->
  [editor, view, filePath, workspaceElement] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    filePath = atom.project.getDirectories()[0].resolve('binary-file.png')
    #TODO: delete created images in tear up or down
    editor = new ImageEditor(filePath)
    view = new ImageEditorView(editor)
    view.height(100)
    jasmine.attachToDOM(view.element)

    waitsFor -> view.loaded

  afterEach ->
    editor.destroy()
    view.remove()

  it "displays the image for a path", ->
    expect(view.image.attr('src')).toContain filePath

  describe "when the image is changed", ->
    it "reloads the image", ->
      spyOn(view, 'updateImageURI')
      editor.file.emitter.emit('did-change')
      expect(view.updateImageURI).toHaveBeenCalled()

  describe "when the image is moved", ->
    it "updates the title", ->
      titleHandler = jasmine.createSpy('titleHandler')
      editor.onDidChangeTitle(titleHandler)
      editor.file.emitter.emit('did-rename')

      expect(titleHandler).toHaveBeenCalled()

  describe "draw-on-image:reload", ->
    it "reloads the image", ->
      spyOn(view, 'updateImageURI')
      atom.commands.dispatch view.element, 'draw-on-image:reload'
      expect(view.updateImageURI).toHaveBeenCalled()

  describe "save", ->
    it "saves the image", ->
      filePathSaved = atom.project.getDirectories()[0].resolve('binary-file_saved.png')
      view.saveImage()
      expect(fs.existsSync(filePathSaved)).toBe(true);

  describe "save as", ->
    it "saves the image with a specific filename", ->
      fileName = 'binary-file_test' + Math.random() + '.png'
      filePathSaved = atom.project.getDirectories()[0].resolve(fileName)
      view.saveImageAs(filePathSaved)
      expect(fs.existsSync(filePathSaved)).toBe(true);

  describe "ImageEditorStatusView", ->
    [imageSizeStatus] = []

    beforeEach ->
      view.detach()
      jasmine.attachToDOM(workspaceElement)

      waitsForPromise ->
        atom.packages.activatePackage('draw-on-image')

      waitsForPromise ->
        atom.workspace.open(filePath)

      runs ->
        editor = atom.workspace.getActivePaneItem()
        view = $(atom.views.getView(atom.workspace.getActivePaneItem())).view()
        view.height(100)

      waitsFor -> view.loaded

      waitsForPromise ->
        atom.packages.activatePackage('status-bar')

      runs ->
        statusBar = workspaceElement.querySelector('status-bar')
        imageSizeStatus = $(statusBar.leftPanel.querySelector('.status-image')).view()
        expect(imageSizeStatus).toExist()

    it "displays the size of the image", ->
      expect(imageSizeStatus.text()).toBe '49x80'
