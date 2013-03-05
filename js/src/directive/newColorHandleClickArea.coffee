###
  Area beneath the working canvas where you can click to add additional color handles.

  Usage:
    <ANY new-color-handle-click-area></ANY>
###
GradientCreatorApp.directive 'newColorHandleClickArea', ($document) ->
  template: '<span class="addHandleIcon iconic brush"></span>'
  link: (scope, elem) ->
    # Get and hide icon
    addHandleIcon = elem.find('.addHandleIcon').hide()

    # Track global mousedown/up status
    mouseIsDown = false
    $document.mousedown -> mouseIsDown = true
    $document.mouseup -> mouseIsDown = false

    # Show icon if hovering over click area while mouse is up
    elem.mouseover -> addHandleIcon.show() unless mouseIsDown
    elem.mouseout -> addHandleIcon.hide()
    elem.mousemove (event) -> addHandleIcon.css left: event.offsetX, top: event.offsetY - 5

    # Add color handle on left-mousedown
    elem.mousedown (event) ->
      leftClicked = event.which == 1
      if leftClicked
        scope.$apply -> scope.addColorHandle (event.pageX - elem.offset().left) / elem.width()
        addHandleIcon.hide()