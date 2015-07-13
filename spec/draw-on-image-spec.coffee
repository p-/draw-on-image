path = require 'path'
ImageEditor = require '../lib/draw-on-image'
ImageEditorView = require '../lib/draw-on-image-view'

describe "ImageEditor", ->
  describe ".deserialize(state)", ->
    it "returns undefined if no file exists at the given path", ->
      spyOn(console, 'warn') # suppress logging in spec
      editor = new ImageEditor(path.join(__dirname, 'fixtures', 'binary-file.png'))
      state = editor.serialize()
      expect(ImageEditor.deserialize(state)).toBeDefined()
      state.filePath = 'bogus'
      expect(ImageEditor.deserialize(state)).toBeUndefined()

  describe ".activate()", ->
    it "registers a project opener that handles image file extension", ->
      waitsForPromise ->
        atom.packages.activatePackage('draw-on-image')

      runs ->
        atom.workspace.open(path.join(__dirname, 'fixtures', 'binary-file.png'))

      waitsFor ->
        atom.workspace.getActivePaneItem() instanceof ImageEditor

      runs ->
        expect(atom.workspace.getActivePaneItem().getTitle()).toBe 'binary-file.png'
        atom.workspace.destroyActivePaneItem()
        atom.packages.deactivatePackage('draw-on-image')

        atom.workspace.open(path.join(__dirname, 'fixtures', 'binary-file.png'))

      waitsFor ->
        atom.workspace.getActivePaneItem()?

      runs ->
        expect(atom.workspace.getActivePaneItem() instanceof ImageEditor).toBe false
