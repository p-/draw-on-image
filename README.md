# draw-on-image package for Atom

Draw on your images and screenshots! (Experimental)

Experimental Hack (my first CoffeeScript project) originally based on [image-view](https://atom.io/packages/image-view) using only Html5 elements like the canvas and the input color element.

![draw-on-image](https://raw.githubusercontent.com/p-/draw-on-image/master/doc/draw-on-image.gif)

## Installing

Use the Atom package manager, which can be found in the Settings view or
run `apm install draw-on-image` from the command line.

## Usage
 * Open any .png or .jpg
 * Draw on the image as you're used to from similar paint applications
 * Undo your last drawing action with the default 'undo' keybindings (usually `Ctrl-Z`/`⌘-Z`) or the Atom 'Edit' menu
 * Save your artwork with the default 'save', 'save-as' keybindings or the Atom 'File' menu

## Known issues
 * The 'save' commands saves the file with the appendix '_saved' to prevent accidentally messing with files
 * Current the only supported file formats are .png and .jpg
