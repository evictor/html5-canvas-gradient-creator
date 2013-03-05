GradientCreatorApp.factory 'ColorHandle', ->
  class ColorHandle
    ###
      @param {String} color Color string in CSS rgba(0-255, 0-255, 0-255, 0-1) format.
      @param {Number} stop  Value 0-1, the gradient color stop. 0 means the color appears at 0%, 0.5 means 50%, etc.
    ###
    constructor: (@color, @stop) ->