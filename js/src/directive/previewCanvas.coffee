###
  The canvas used to draw the gradient live.

  Usage:
    <canvas preview-canvas
            gradient-type="{expression}"
            color-handles="{expression}"
            width="{expression}"
            height="{expression}"
            rotate="{expression}"
            inner-circle-x="{expression}"
            inner-circle-y="{expression}"
            outer-circle-x="{expression}"
            outer-circle-y="{expression}"
            [html-code="{model}"]
            [js-code="{model}"]></canvas>

    gradientType - {expression} - "linear" or "radial".
    colorHandles - {expression} - Array of color handle objects used to draw gradient.
    width - {expression} - Width of canvas.
    height - {expression} - Height of canvas.
    rotate - {expression} - Linear gradient type only; the number of degrees to rotate gradient, range is [0, 360).
    innerCircleX - {expression} - Radial gradient type only; inner circle x coord in percentage from 0-100.
    innerCircleY - {expression} - Radial gradient type only; inner circle y coord in percentage from 0-100.
    outerCircleX - {expression} - Radial gradient type only; outer circle x coord in percentage from 0-100.
    outerCircleY - {expression} - Radial gradient type only; outer circle y coord in percentage from 0-100.
    htmlCode - {model} - Model name that will be stuffed with generated HTML code. This is *not* an expression.
    jsCode - {model} - Model name that will be stuffed with generated JS code. This is *not* an expression.
###
GradientCreatorApp.directive 'previewCanvas', ->
  require: '?resizableCanvas'
  link: (scope, elem, attrs, resizableCanvasCtrl) ->
    canvasDom = elem[0]
    ctx = canvasDom.getContext '2d'
    jsCodePrecision = 3

    ###
      @return {Object} Data on which the canvas rendering depends.
    ###
    getDependentData = ->
      ColorHandles: scope.$eval attrs.colorHandles
      gradientType: scope.$eval attrs.gradientType
      width: elem.prop 'width'
      height: elem.prop 'height'
      rotateDegrees: scope.$eval attrs.rotate
      innerCircleX: scope.$eval attrs.innerCircleX
      innerCircleY: scope.$eval attrs.innerCircleY
      outerCircleX: scope.$eval attrs.outerCircleX
      outerCircleY: scope.$eval attrs.outerCircleY

    ###
      @param {Object} dependentData Result of {@link getDependentData()}.
    ###
    dependentDataChange = (dependentData) ->
      ColorHandles = dependentData.ColorHandles
      gradientType = dependentData.gradientType
      width = dependentData.width
      height = dependentData.height
      rotateDegrees = dependentData.rotateDegrees ? 0
      innerCircleX = dependentData.innerCircleX ? 50
      innerCircleY = dependentData.innerCircleY ? 50
      outerCircleX = dependentData.outerCircleX ? 50
      outerCircleY = dependentData.outerCircleY ? 50

      # HTML code
      if attrs.htmlCode
        scope[attrs.htmlCode] = """
                                <canvas id="myPrettyCanvas" width="#{width}" height="#{height}"></canvas>
                                """

      # Init JS code
      if attrs.jsCode
        scope[attrs.jsCode] = """
                              var canvasId = 'myPrettyCanvas',
                                  canvas = document.getElementById(canvasId),
                                  ctx = canvas.getContext('2d'),
                                  grd;


                              """

      # Create gradient
      scaleX = 1
      scaleY = 1
      switch gradientType
        when 'linear'
          if 0 <= rotateDegrees < 45
            x1 = 0
            y1 = height / 2 * (45 - rotateDegrees) / 45
            x2 = width
            y2 = height - y1
          else if 45 <= rotateDegrees < 135
            x1 = width * (rotateDegrees - 45) / (135 - 45)
            y1 = 0
            x2 = width - x1
            y2 = height
          else if 135 <= rotateDegrees < 225
            x1 = width
            y1 = height * (rotateDegrees - 135) / (225 - 135)
            x2 = 0
            y2 = height - y1
          else if 225 <= rotateDegrees < 315
            x1 = width * (1 - (rotateDegrees - 225) / (315 - 225))
            y1 = height
            x2 = width - x1
            y2 = 0
          else if 315 <= rotateDegrees
            x1 = 0
            y1 = height - height / 2 * (rotateDegrees - 315) / (360 - 315)
            x2 = width
            y2 = height - y1
          grd = ctx.createLinearGradient x1, y1, x2, y2
          if attrs.jsCode
            x1Fixed = x1.toFixed jsCodePrecision
            y1Fixed = y1.toFixed jsCodePrecision
            x2Fixed = x2.toFixed jsCodePrecision
            y2Fixed = y2.toFixed jsCodePrecision
            scope[attrs.jsCode] += """
                                   // Create gradient
                                   grd = ctx.createLinearGradient(#{x1Fixed}, #{y1Fixed}, #{x2Fixed}, #{y2Fixed});


                                   """
        when 'radial'
          if width > height then scaleY = height / width
          if height > width then scaleX = width / height
          ctx.setTransform scaleX, 0, 0, scaleY, 0, 0
          grd = ctx.createRadialGradient(
            x1 = (width * innerCircleX / 100) / scaleX,
            y1 = (height * innerCircleY / 100) / scaleY,
            r1 = 0,
            x2 = (width * outerCircleX / 100) / scaleX,
            y2 = (height * outerCircleY / 100) / scaleY,
            r2 = (width / 2) / scaleX
          )
          if attrs.jsCode
            if scaleX != 1 or scaleY != 1
              scope[attrs.jsCode] += """
                                     // Transform to facilitate ellipse
                                     ctx.setTransform(#{scaleX}, 0, 0, #{scaleY}, 0, 0);


                                     """
            x1Fixed = x1.toFixed jsCodePrecision
            y1Fixed = y1.toFixed jsCodePrecision
            r1Fixed = r1.toFixed jsCodePrecision
            x2Fixed = x2.toFixed jsCodePrecision
            y2Fixed = y2.toFixed jsCodePrecision
            r2Fixed = r2.toFixed jsCodePrecision
            scope[attrs.jsCode] += """
                                   // Create gradient
                                   grd = ctx.createRadialGradient(#{x1Fixed}, #{y1Fixed}, #{r1Fixed}, #{x2Fixed}, #{y2Fixed}, #{r2Fixed});


                                   """
        else
          throw 'Unknown gradient type.'

      # Add colors
      if attrs.jsCode then scope[attrs.jsCode] += '// Add colors\n'
      for ColorHandle in ColorHandles when ColorHandle.color
        grd.addColorStop ColorHandle.stop, ColorHandle.color
        if attrs.jsCode
          regEx = /([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)/
          matches = regEx.exec ColorHandle.color
          r = matches[1]
          g = matches[2]
          b = matches[3]
          a = parseFloat(matches[4]).toFixed jsCodePrecision
          scope[attrs.jsCode] += """
                                 grd.addColorStop(#{ColorHandle.stop.toFixed jsCodePrecision}, 'rgba(#{r}, #{g}, #{b}, #{a})');

                                 """
      if attrs.jsCode then scope[attrs.jsCode] += '\n'

      # Fill
      ctx.clearRect 0, 0, width / scaleX, height / scaleY
      ctx.fillStyle = grd
      ctx.fillRect 0, 0, width / scaleX, height / scaleY
      if attrs.jsCode
        scope[attrs.jsCode] += """
                               // Fill with gradient
                               ctx.fillStyle = grd;
                               ctx.fillRect(0, 0, #{(width / scaleX).toFixed jsCodePrecision}, #{(height / scaleY).toFixed jsCodePrecision});
                               """

      if resizableCanvasCtrl? then resizableCanvasCtrl.drawResizeIcon()

    # Update canvas on dependent data change
    scope.$watch getDependentData, dependentDataChange, true