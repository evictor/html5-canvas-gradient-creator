###
  Horizontal slider.

  Usage:
    <div slider value="{expression}" min="{Number}" max="{Number}" round="{int}"></div>

    value - {expression} - Model to bind slider value to.
    min - {Number} - Slider value at leftmost position.
    max - {Number} - Slider value at rightmost position.
    precision - {int} - Number of places after decimal to keep in value, 0-20 per limits of Number.toFixed().
###
GradientCreatorApp.directive 'slider', ($timeout, $document) ->
  scope:
    value: '='
    handleLeft: '@'
  template: '<div class="inner"><a target="_self" class="handle" ng-style="{left: handleLeft}"></a></div>'
  replace: false
  link: (scope, elem, attrs) ->
    min = max = precision = handleLeft = rawValue = null
    $handle = elem.find '.handle'

    # Keep min/max/round up to date
    scope.$watch attrs.min, (watched) -> min = parseFloat watched; if scope.value < min then scope.value = min
    scope.$watch attrs.max, (watched) -> max = parseFloat watched; if scope.value > max then scope.value = max
    scope.$watch attrs.precision, (watched) ->
      precision = watched
      if rawValue?
        scope.value = parseFloat(rawValue).toFixed precision

    ###
      Update slider value directly.
    ###
    updateSliderValue = (newValue) ->
      # Fix precision and bounds
      newValue = parseFloat newValue
      scope.value = switch
                      when newValue < min then min
                      when newValue > max then max
                      else newValue
      scope.value = parseFloat scope.value.toFixed precision

    # Keep slider up to date with value
    minLeft = 0
    maxLeft = 100
    init = true
    scope.$watch 'value', (rawValue, oldValue) ->
      if rawValue? and (rawValue != oldValue or init)
        updateSliderValue rawValue
        scope.handleLeft = minLeft + (maxLeft - minLeft) * (rawValue - min) / (max - min) + '%'
        init = false

    # Init value if needed
    if !scope.value?
      $timeout -> scope.value = min

    ###
      Updates handle left pos to correspond with mouse pageX.
    ###
    updateHandleLeftFromMouse = (mousePageX) ->
      scope.handleLeft = minLeft + (maxLeft - minLeft) * (mousePageX - elem.position().left) / elem.width()
      if scope.handleLeft < minLeft then scope.handleLeft = minLeft
      else if scope.handleLeft > maxLeft then scope.handleLeft = maxLeft
      scope.handleLeft += '%'

    ###
      Update slider value to correspond with mouse pageX.
    ###
    updateValueFromMouse = (mousePageX) ->
      scope.value = min + (max - min) * (mousePageX - elem.position().left) / elem.width()
      if scope.value < min then scope.value = min
      else if scope.value > max then scope.value = max
      scope.value = parseFloat scope.value.toFixed precision

    # Handle draggability
    mousemoveListener = null
    $handle.mousedown (e) ->
      $timeout -> $handle.focus()
      $document.mousemove mousemoveListener = (event) ->
        scope.$apply ->
          updateHandleLeftFromMouse event.pageX
          updateValueFromMouse event.pageX
      if e.immediateUpdate then mousemoveListener(e)
      false
    $document.mouseup ->
      if mousemoveListener != null
        $document.unbind 'mousemove', mousemoveListener
        mousemoveListener = null

    # Slider bar mousedown
    elem.mousedown (e) ->
      # Simulate handle mousedown for dragging + immediate update
      $handle.trigger jQuery.Event 'mousedown',
        pageX: e.pageX
        immediateUpdate: true

    ###
      Update value by a percent-of-range delta.
      @param {Number} percentDelta Floating point percent from 0-1.
    ###
    updateValueByPercentDelta = (percentDelta) ->
      updateSliderValue parseFloat(scope.value) + percentDelta * (max - min)

    # Handle keypress
    $handle.keydown (e) ->
      switch e.which
        # UP or RIGHT
        when 38, 39 then scope.$apply -> updateValueByPercentDelta 0.01
        # DOWN or LEFT
        when 40, 37 then scope.$apply -> updateValueByPercentDelta -0.01
        # HOME
        when 36 then scope.$apply -> updateSliderValue min
        # END
        when 35 then scope.$apply -> updateSliderValue max
        # PAGE UP
        when 33 then scope.$apply -> updateValueByPercentDelta -0.1
        # PAGE DOWN
        when 34 then scope.$apply -> updateValueByPercentDelta 0.1
        else didntHandleKey = true

      e.preventDefault() unless didntHandleKey? and didntHandleKey