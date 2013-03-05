###
  Makes a <canvas /> resizable by dragging in lower-right corner. It's necessary to target <canvas /> specifically
  because browsers depend on width/height DOM attributes for that node type rather than CSS.

  Usage:
    <canvas resizable-canvas
            width="{model name}"
            height="{model name}"></canvas>

    width - {model name} - Model name that will have width read from and written to.
    height - {model name} - Model name that will have height read from and written to.

  A controller is provided with method drawResizeIcon() that can be called to draw a resize icon in the lower-right
  corner of the canvas.
###
GradientCreatorApp.directive 'resizableCanvas', ($document) ->
  controller: ($element) ->
    ctx = $element[0].getContext('2d')

    ###
      Call this after canvas is finished rendering; a resize icon in the lower icon will be overlayed on top.
    ###
    @drawResizeIcon = ->
      iconImage = new Image()
      iconImage.src = 'img/resizable.png'
      iconImage.onload = ->
        ctx.setTransform 1, 0, 0, 1, 0, 0
        ctx.drawImage(iconImage, $element.width() - 11, $element.height() - 11)

  link: (scope, elem, attrs) ->
    # Pixel square hit area to click and drag resize in bottom-right
    cornerHitAreaDim = 15

    # Min width or height of the canvas
    minDim = 15

    # Keep DOM width/height up to date with model
    scope.$watch attrs.width, (newWidth) -> elem.prop 'width', newWidth
    scope.$watch attrs.height, (newHeight) -> elem.prop 'height', newHeight

    ###
      @param {Number} offsetX Mouse offset X.
      @param {Number} offsetY Mouse offset Y.

      @return {Boolean} TRUE if mouse is within resize hit area.
    ###
    mouseInHitArea = (offsetX, offsetY) ->
      offsetX >= elem.prop('width') - cornerHitAreaDim and offsetY >= elem.prop('height') - cornerHitAreaDim

    # Track mouse down status
    dragging = false
    mouseDownPos = null
    elem.mousedown (event) ->
      if mouseInHitArea event.offsetX, event.offsetY
        dragging = true
        mouseDownPos = right: elem.prop('width') - event.offsetX, bottom: elem.prop('height') - event.offsetY
    elem.mouseup -> dragging = false

    $document.mousemove (event) ->
      if dragging or mouseInHitArea event.offsetX, event.offsetY
        elem.css 'cursor', 'nw-resize'
        if dragging
          newWidth = (event.pageX - elem.position().left) + mouseDownPos.right
          newHeight = (event.pageY - elem.position().top) + mouseDownPos.bottom
          if newWidth < minDim then newWidth = minDim
          if newHeight < minDim then newHeight = minDim

          # Dims actually changed
          if newWidth != elem.prop('width') or newHeight != elem.prop('height')
            scope.$apply ->
              scope[attrs.width] = newWidth
              scope[attrs.height] = newHeight
      # Not dragging or mouse not in hit area
      else
        elem.css 'cursor', 'auto'