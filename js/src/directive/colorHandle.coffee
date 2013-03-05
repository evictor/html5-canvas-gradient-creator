###
  The little arrow color handles that you drag around to adjust the gradient.

  Usage:
    <ANY color-handle="{color handle model}"></ANY>
###
GradientCreatorApp.directive 'colorHandle', ($document, $timeout) ->
  return (scope, elem, attrs) ->
    container = elem.parent()
    elem.addClass 'iconic'

    # Gets this color handle's color handle model
    getColorHandle = -> scope.$eval attrs.colorHandle

    # Color handle model change
    scope.$watch attrs.colorHandle, (ColorHandle, OldColorHandle) ->
      # Update position from stop
      leftExtremePercent = -3.4
      rightExtremePercent = 96.7
      elem.css 'left', leftExtremePercent + (ColorHandle.stop * (rightExtremePercent + Math.abs(leftExtremePercent))) + '%'

      # Valid color
      if ColorHandle.color != null
        elem.css 'color', ColorHandle.color
      # Null color
      else
        # Try to delete this handle
        deleted = scope.deleteColorHandle ColorHandle

        # Couldn't delete (last handle)
        if !deleted
          # Revert color
          ColorHandle.color = OldColorHandle.color
    , true

    scope.$watch 'ActiveColorHandle', (ActiveColorHandle) ->
      ThisColorHandle = getColorHandle()

      # Active color handle is this one
      elem.toggleClass 'arrow_up_alt1', ActiveColorHandle == ThisColorHandle

      # Active color handle is not this one
      elem.toggleClass 'arrow_up', ActiveColorHandle != ThisColorHandle

    # Element draggability
    mousemoveListener = null
    elem.mousedown (event) ->
      leftClicked = event.which == 1
      if leftClicked then beginDragging()

    # Triggers dragging... should only be triggered if mouse is actually down
    beginDragging = ->
      ThisColorHandle = getColorHandle()
      scope.$apply -> scope.setActiveColorHandle ThisColorHandle
      elem.addClass 'dragging'
      if not mousemoveListener then $document.mousemove mousemoveListener = (event) ->
        scope.$apply ->
          ThisColorHandle.stop = (event.pageX - container.position().left) / container.width()
          if ThisColorHandle.stop < 0 then ThisColorHandle.stop = 0
          else if ThisColorHandle.stop > 1 then ThisColorHandle.stop = 1

    # Stop dragging as appropriate
    $document.mouseup ->
      if elem.hasClass 'dragging'
        elem.removeClass 'dragging'
      if mousemoveListener != null
        $document.unbind 'mousemove', mousemoveListener
        mousemoveListener = null

    # Right-click to delete
    elem.mouseup ->
      rightClicked = event.which == 3
      if rightClicked then scope.$apply -> scope.deleteColorHandle getColorHandle()

    # Instructed to force a drag immediately (such as when adding a color handle) and mouse is down.
    # Timed out to ensure mouseIsDown status is up to date.
    $timeout ->
      ThisColorHandle = getColorHandle()
      if ThisColorHandle.forceDrag and scope.getMouseIsDown()
        ThisColorHandle.forceDrag = false
        scope.setActiveColorHandle ThisColorHandle
        beginDragging()