class window.MainCtrl
  addHandleDefaultColor: 'rgba(0, 0, 0, 1)'

  presetDefaults:
    gradientType: 'linear'
    width: 300
    height: 300
    rotate: 0
    innerCircleX: 50
    innerCircleY: 50
    outerCircleX: 50
    outerCircleY: 50

  constructor: (@$scope, @$document, @ColorHandle, @$filter, @localStorageService, @GradientPreset) ->
    @$scope.localStorageSupported = @localStorageService.isSupported()
    @$scope.gradientType = @presetDefaults.gradientType
    @$scope.bigCanvasWidth = @presetDefaults.width
    @$scope.bigCanvasHeight = @presetDefaults.height
    @$scope.rotateDegrees = @presetDefaults.rotate
    @$scope.innerCircleX = @presetDefaults.innerCircleX
    @$scope.innerCircleY = @presetDefaults.innerCircleY
    @$scope.outerCircleX = @presetDefaults.outerCircleX
    @$scope.outerCircleY = @presetDefaults.outerCircleY
    @$scope.LoadedPreset = {}
    @$scope.loading = true
    $.fn.qtip.defaults.position.my = 'bottom left'
    $.fn.qtip.defaults.position.at = 'top center'
    $.fn.qtip.defaults.position.viewport = true
    $.fn.qtip.defaults.position.adjust.method = 'shift none'
    $.fn.qtip.defaults.position.adjust.y = -3
    $.fn.qtip.defaults.style.classes = 'qtip-jtools'
    @$scope.presetTooltipOpts =
      position:
        my: 'bottom center'

    # Get saved presets from local storage
    @$scope.SavedPresets = @GradientPreset.query()

    # Scope proxy methods
    @$scope.addColorHandle = => @addColorHandle.apply @, arguments
    @$scope.deleteColorHandle = => @deleteColorHandle.apply @, arguments
    @$scope.setActiveColorHandle = => @setActiveColorHandle.apply @, arguments
    @$scope.getMouseIsDown = => @getMouseIsDown.apply @, arguments
    @$scope.applyPreset = => @applyPreset.apply @, arguments
    @$scope.saveLoadedPreset = => @saveLoadedPreset.apply @, arguments
    @$scope.deleteLoadedPreset = => @deleteLoadedPreset.apply @, arguments

    @initColorHandles()
    @trackMouseIsDown()
    @setUpActiveColorHandleStopManualInput()
    @compileGradientHtmlPageCode()
    @initPresets()
    @manageLoadedPresetDirty()

    # Auto-show/hide instructions based on color active handle
    @$scope.$watch 'ActiveColorHandle', (ActiveColorHandle) => @$scope.showInstructions = !ActiveColorHandle?

  initColorHandles: ->
    @$scope.ColorHandles = [
      new @ColorHandle('rgba(0, 0, 0, 1)', 0)
      new @ColorHandle('rgba(255, 255, 255, 1)', 1)
    ]
    @setActiveColorHandle null

    # ColorHandles stop change
    @$scope.$watch (=> (CH.stop for CH in @$scope.ColorHandles)), =>
      # Resort by stop
      @sortColorHandlesByStop()
    , true

  ###
    Adds a new color handle.

    @param {Number} stop New color handle's desired stop.
  ###
  addColorHandle: (stop) ->
    NewHandle = new @ColorHandle @addHandleDefaultColor, stop
    NewHandle.forceDrag = true
    @$scope.ColorHandles.push NewHandle

    # Sort by stop
    @sortColorHandlesByStop()

  ###
    @param {Object} DeleteColorHandle Handle to delete.

    @return {Boolean} TRUE if the handle was deleted (last handle is never deleted; will return FALSE).
  ###
  deleteColorHandle: (DeleteColorHandle) ->
    # OK to delete (not last handle)
    deleted = @$scope.ColorHandles.length > 1
    if deleted
      # Sort handles by stop
      @sortColorHandlesByStop()

      # Handle to delete is active handle
      if DeleteColorHandle == @$scope.ActiveColorHandle
        # Set active handle to next handle, or previous handle if next handle was last handle
        for ColorHandle, i in @$scope.ColorHandles
          if ColorHandle == DeleteColorHandle
            @$scope.setActiveColorHandle @$scope.ColorHandles[i + 1] ? @$scope.ColorHandles[i - 1]
            break

      # Delete handle
      @$scope.ColorHandles = (ColorHandle for ColorHandle in @$scope.ColorHandles when ColorHandle isnt DeleteColorHandle)

    deleted

  ###
    The "active" color handle is the one whose color is loaded into the color picker.

    @param {Object} ColorHandle Handle to set as active.
  ###
  setActiveColorHandle: (ColorHandle) -> @$scope.ActiveColorHandle = ColorHandle

  ###
    Keeps @$scope.mouseIsDown up to date.

    @see getMouseIsDown()
  ###
  trackMouseIsDown: ->
    @$scope.mouseIsDown = false
    @$document.mousedown => @$scope.mouseIsDown = true
    @$document.mouseup => @$scope.mouseIsDown = false

  ###
    @return {Boolean} TRUE if mouse is currently down, FALSE if it is up.
  ###
  getMouseIsDown: -> @$scope.mouseIsDown

  ###
    Keeps active color handle stop and manual input in sync.
  ###
  setUpActiveColorHandleStopManualInput: ->
    numberFilter = @$filter 'number'

    # Keep input up to date with handle
    @$scope.$watch 'ActiveColorHandle.stop', (stop) =>
      if stop? then @$scope.activeColorHandleStopPercent = parseFloat(numberFilter(stop * 100, 1).replace(/,/g, ''))

        # Keep handle up to date with input
    @$scope.$watch 'activeColorHandleStopPercent', (percent) =>
      if percent? then @$scope.ActiveColorHandle.stop = percent / 100

  ###
    Watches HTML and JS code bits from previewCanvas directive and compiles final full page code.
  ###
  compileGradientHtmlPageCode: ->
    # Watch gradient code parts
    @$scope.$watch =>
      html: @$scope.gradientHtmlCode ? ''
      js: @$scope.gradientJsCode ? ''
      dirty: @$scope.LoadedPreset?.dirty
    , (codeParts) =>

      # Get HTML escaped gradient preset name (or default name)
      gradientNameHtml = if @$scope.LoadedPreset.name?
          jQuery('<p />').text(@$scope.LoadedPreset.name).html() +
            if @$scope.LoadedPreset.dirty then ' (modified)' else ''
        else
          'Ermahgerd, a gradient'

      @$scope.gradientHtmlPageCode = """
                                     <!doctype html>
                                     <html>
                                       <head>
                                         <meta charset="UTF-8">
                                         <title>#{gradientNameHtml}</title>
                                       </head>
                                       <body>
                                         #{codeParts.html}
                                         <script type="text/javascript">
                                           #{codeParts.js.replace /\n/g, '\n      '}
                                         </script>
                                       </body>
                                     </html>
                                     """
    , true

  ###
    Init gradient presets.
  ###
  initPresets: ->
    @$scope.Presets = [
      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Black → transparent'
        name: 'Black → transparent'
        ColorHandles: [
          new @ColorHandle 'rgba(0, 0, 0, 1.00)', 0.00
          new @ColorHandle 'rgba(0, 0, 0, 0.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'White → transparent'
        name: 'White → transparent'
        ColorHandles: [
          new @ColorHandle 'rgba(255, 255, 255, 1.00)', 0.00
          new @ColorHandle 'rgba(255, 255, 255, 0.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Red → green'
        name: 'Red → green'
        ColorHandles: [
          new @ColorHandle 'rgba(225, 0, 25, 1.00)', 0.00
          new @ColorHandle 'rgba(0, 96, 27, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Violet → orange'
        name: 'Violet → orange'
        ColorHandles: [
          new @ColorHandle 'rgba(41, 10, 89, 1.00)', 0.00
          new @ColorHandle 'rgba(255, 124, 0, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Blue → red → yellow'
        name: 'Blue → red → yellow'
        ColorHandles: [
          new @ColorHandle 'rgba(10, 0, 178, 1.00)', 0.00
          new @ColorHandle 'rgba(255, 0, 0, 1.00)', 0.50
          new @ColorHandle 'rgba(255, 252, 0, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Blue → yellow → blue'
        name: 'Blue → yellow → blue'
        ColorHandles: [
          new @ColorHandle 'rgba(11, 1, 184, 1.00)', 0.10
          new @ColorHandle 'rgba(253, 250, 3, 1.00)', 0.50
          new @ColorHandle 'rgba(11, 2, 170, 1.00)', 0.90
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Orange → yellow → orange'
        name: 'Orange → yellow → orange'
        ColorHandles: [
          new @ColorHandle 'rgba(255, 110, 2, 1.00)', 0.00
          new @ColorHandle 'rgba(255, 255, 0, 1.00)', 0.50
          new @ColorHandle 'rgba(255, 109, 0, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Violet → green → orange'
        name: 'Violet → green → orange'
        ColorHandles: [
          new @ColorHandle 'rgba(111, 21, 108, 1.00)', 0.00
          new @ColorHandle 'rgba(0, 96, 27, 1.00)', 0.50
          new @ColorHandle 'rgba(253, 124, 0, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Yellow → violet → orange → blue'
        name: 'Yellow → violet → orange → blue'
        ColorHandles: [
          new @ColorHandle 'rgba(249, 230, 0, 1.00)', 0.05
          new @ColorHandle 'rgba(111, 21, 108, 1.00)', 0.35
          new @ColorHandle 'rgba(253, 124, 0, 1.00)', 0.65
          new @ColorHandle 'rgba(0, 40, 116, 1.00)', 0.95
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Copper'
        name: 'Copper'
        ColorHandles: [
          new @ColorHandle 'rgba(151, 70, 26, 1.00)', 0.00
          new @ColorHandle 'rgba(251, 216, 197, 1.00)', 0.30
          new @ColorHandle 'rgba(108, 46, 22, 1.00)', 0.83
          new @ColorHandle 'rgba(239, 219, 205, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Chrome'
        name: 'Chrome'
        ColorHandles: [
          new @ColorHandle 'rgba(41, 137, 204, 1.00)', 0.00
          new @ColorHandle 'rgba(255, 255, 255, 1.00)', 0.50
          new @ColorHandle 'rgba(144, 106, 0, 1.00)', 0.52
          new @ColorHandle 'rgba(217, 159, 0, 1.00)', 0.64
          new @ColorHandle 'rgba(255, 255, 255, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Spectrum'
        name: 'Spectrum'
        ColorHandles: [
          new @ColorHandle 'rgba(255, 0, 0, 1.00)', 0.00
          new @ColorHandle 'rgba(255, 0, 255, 1.00)', 0.15
          new @ColorHandle 'rgba(0, 0, 255, 1.00)', 0.33
          new @ColorHandle 'rgba(0, 255, 255, 1.00)', 0.49
          new @ColorHandle 'rgba(0, 255, 0, 1.00)', 0.67
          new @ColorHandle 'rgba(255, 255, 0, 1.00)', 0.84
          new @ColorHandle 'rgba(255, 0, 0, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Rainbow'
        name: 'Rainbow'
        ColorHandles: [
          new @ColorHandle 'rgba(255, 0, 0, 0.00)', 0.15
          new @ColorHandle 'rgba(255, 0, 0, 1.00)', 0.20
          new @ColorHandle 'rgba(255, 252, 0, 1.00)', 0.32
          new @ColorHandle 'rgba(1, 180, 57, 1.00)', 0.44
          new @ColorHandle 'rgba(0, 234, 255, 1.00)', 0.56
          new @ColorHandle 'rgba(0, 3, 144, 1.00)', 0.68
          new @ColorHandle 'rgba(255, 0, 198, 1.00)', 0.80
          new @ColorHandle 'rgba(255, 0, 198, 0.00)', 0.85
        ]
    ]

    @$scope.FunPresets = [
      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Solar eclipse'
        name: 'Solar eclipse'
        gradientType: 'radial'
        innerCircleX: 45
        innerCircleY: 45
        outerCircleX: 45
        outerCircleY: 45
        ColorHandles: [
          new @ColorHandle 'rgba(34, 10, 10, 1.00)', 0.00
          new @ColorHandle 'rgba(34, 10, 10, 1.00)', 0.33
          new @ColorHandle 'rgba(255, 255, 255, 1.00)', 0.34
          new @ColorHandle 'rgba(234, 189, 12, 1.00)', 0.60
          new @ColorHandle 'rgba(35, 1, 4, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Eyeball'
        name: 'Eyeball'
        gradientType: 'radial'
        innerCircleX: 51
        innerCircleY: 63.3
        outerCircleY: 49
        ColorHandles: [
          new @ColorHandle 'rgba(14, 14, 16, 1.00)', 0.00
          new @ColorHandle 'rgba(14, 14, 16, 1.00)', 0.17
          new @ColorHandle 'rgba(75, 93, 103, 1.00)', 0.61
          new @ColorHandle 'rgba(96, 109, 91, 1.00)', 0.27
          new @ColorHandle 'rgba(75, 93, 103, 1.00)', 0.62
          new @ColorHandle 'rgba(255, 250, 250, 1.00)', 0.69
          new @ColorHandle 'rgba(255, 250, 250, 1.00)', 0.92
          new @ColorHandle 'rgba(0, 0, 0, 1.00)', 0.93
          new @ColorHandle 'rgba(255, 255, 255, 1.00)', 0.94
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Bullseye'
        name: 'Bullseye'
        gradientType: 'radial'
        ColorHandles: [
          new @ColorHandle 'rgba(255, 238, 40, 1.00)', 0.00
          new @ColorHandle 'rgba(255, 238, 40, 1.00)', 0.20
          new @ColorHandle 'rgba(194, 66, 57, 1.00)', 0.21
          new @ColorHandle 'rgba(194, 66, 57, 1.00)', 0.40
          new @ColorHandle 'rgba(130, 194, 238, 1.00)', 0.41
          new @ColorHandle 'rgba(130, 194, 238, 1.00)', 0.60
          new @ColorHandle 'rgba(254, 254, 254, 1.00)', 0.61
          new @ColorHandle 'rgba(254, 254, 254, 1.00)', 0.78
          new @ColorHandle 'rgba(52, 50, 51, 1.00)', 0.79
          new @ColorHandle 'rgba(52, 50, 51, 1.00)', 0.99
          new @ColorHandle 'rgba(255, 255, 255, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Breakfast'
        name: 'Breakfast'
        gradientType: 'radial'
        width: 320
        height: 404
        innerCircleY: 89.1
        outerCircleY: 47.5
        ColorHandles: [
          new @ColorHandle 'rgba(255, 153, 0, 1.00)', 0.00
          new @ColorHandle 'rgba(255, 191, 0, 1.00)', 0.46
          new @ColorHandle 'rgba(255, 255, 255, 1.00)', 0.49
          new @ColorHandle 'rgba(255, 255, 255, 1.00)', 0.86
          new @ColorHandle 'rgba(0, 0, 0, 1.00)', 0.85
          new @ColorHandle 'rgba(255, 255, 255, 1.00)', 0.84
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Sunset'
        name: 'Sunset'
        gradientType: 'radial'
        innerCircleX: 60
        innerCircleY: 100
        outerCircleX: 60
        outerCircleY: 100
        ColorHandles: [
          new @ColorHandle 'rgba(255, 242, 0, 1.00)', 0.00
          new @ColorHandle 'rgba(255, 157, 0, 1.00)', 0.37
          new @ColorHandle 'rgba(47, 32, 163, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Oui oui'
        name: 'Oui oui'
        gradientType: 'linear'
        width: 300
        height: 200
        ColorHandles: [
          new @ColorHandle 'rgba(0, 85, 164, 1.00)', 0.00
          new @ColorHandle 'rgba(0, 85, 164, 1.00)', 0.33
          new @ColorHandle 'rgba(255, 255, 255, 1.00)', 0.331
          new @ColorHandle 'rgba(255, 255, 255, 1.00)', 0.66
          new @ColorHandle 'rgba(250, 60, 50, 1.00)', 0.661
          new @ColorHandle 'rgba(250, 60, 50, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Mamma mia'
        name: 'Mamma mia'
        gradientType: 'linear'
        width: 300
        height: 200
        ColorHandles: [
          new @ColorHandle 'rgba(0, 146, 70, 1.00)', 0.00
          new @ColorHandle 'rgba(0, 146, 70, 1.00)', 0.33
          new @ColorHandle 'rgba(241, 242, 241, 1.00)', 0.331
          new @ColorHandle 'rgba(241, 242, 241, 1.00)', 0.66
          new @ColorHandle 'rgba(206, 43, 55, 1.00)', 0.661
          new @ColorHandle 'rgba(206, 43, 55, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Con gusto'
        name: 'Con gusto'
        gradientType: 'linear'
        rotate: 90
        width: 300
        height: 200
        ColorHandles: [
          new @ColorHandle 'rgba(252, 209, 22, 1.00)', 0.00
          new @ColorHandle 'rgba(252, 209, 22, 1.00)', 0.5
          new @ColorHandle 'rgba(0, 56, 147, 1.00)', 0.501
          new @ColorHandle 'rgba(0, 56, 147, 1.00)', 0.75
          new @ColorHandle 'rgba(206, 17, 38, 1.00)', 0.751
          new @ColorHandle 'rgba(206, 17, 38, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Genau'
        name: 'Genau'
        gradientType: 'linear'
        rotate: 90
        width: 300
        height: 180
        ColorHandles: [
          new @ColorHandle 'rgba(0, 0, 0, 1.00)', 0.00
          new @ColorHandle 'rgba(0, 0, 0, 1.00)', 0.33
          new @ColorHandle 'rgba(255, 0, 0, 1.00)', 0.331
          new @ColorHandle 'rgba(255, 0, 0, 1.00)', 0.69
          new @ColorHandle 'rgba(255, 204, 0, 1.00)', 0.691
          new @ColorHandle 'rgba(255, 204, 0, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Привет'
        name: 'Привет'
        gradientType: 'linear'
        rotate: 90
        width: 300
        height: 200
        ColorHandles: [
          new @ColorHandle 'rgba(255, 255, 255, 1.00)', 0.00
          new @ColorHandle 'rgba(255, 255, 255, 1.00)', 0.33
          new @ColorHandle 'rgba(0, 0, 255, 1.00)', 0.331
          new @ColorHandle 'rgba(0, 0, 255, 1.00)', 0.69
          new @ColorHandle 'rgba(255, 0, 0, 1.00)', 0.691
          new @ColorHandle 'rgba(255, 0, 0, 1.00)', 1.00
        ]

      angular.extend new @GradientPreset, @presetDefaults,
        id: 'Maisha mazuri'
        name: 'Maisha mazuri'
        gradientType: 'linear'
        rotate: 71
        width: 300
        height: 200
        ColorHandles: [
          new @ColorHandle 'rgba(30, 181, 58, 1.00)', 0.00
          new @ColorHandle 'rgba(30, 181, 58, 1.00)', 0.35
          new @ColorHandle 'rgba(252, 209, 22, 1.00)', 0.351
          new @ColorHandle 'rgba(252, 209, 22, 1.00)', 0.4
          new @ColorHandle 'rgba(0, 0, 0, 1.00)', 0.401
          new @ColorHandle 'rgba(0, 0, 0, 1.00)', 0.6
          new @ColorHandle 'rgba(252, 209, 22, 1.00)', 0.601
          new @ColorHandle 'rgba(252, 209, 22, 1.00)', 0.65
          new @ColorHandle 'rgba(0, 163, 221, 1.00)', 0.651
          new @ColorHandle 'rgba(0, 163, 221, 1.00)', 1.00
        ]
    ]

  ###
    Apply preset gradient to working area.

    @param {GradientPreset} Preset
  ###
  applyPreset: (Preset) ->
    # Deep clone so updates in the working area don't immediately affect the preset
    Preset = Preset.clone()

    @$scope.gradientType = Preset.gradientType
    @$scope.bigCanvasWidth = Preset.width
    @$scope.bigCanvasHeight = Preset.height
    @$scope.rotateDegrees = Preset.rotate
    @$scope.innerCircleX = Preset.innerCircleX
    @$scope.innerCircleY = Preset.innerCircleY
    @$scope.outerCircleX = Preset.outerCircleX
    @$scope.outerCircleY = Preset.outerCircleY
    @$scope.ColorHandles = Preset.ColorHandles
    @$scope.ActiveColorHandle = null
    @$scope.LoadedPreset = Preset
    @$scope.LoadedPreset.initialChange = true

  ###
    Marks loaded preset as dirty as appropriate.
  ###
  manageLoadedPresetDirty: ->
    # Marks loaded preset dirty under certain conditions...
    manageLoadedPresetDirty = =>
      # 1. There actually is a loaded preset
      # 2. The data watch fired wasn't the "initial change"
      if @$scope.LoadedPreset? and !@$scope.LoadedPreset.initialChange
        @$scope.LoadedPreset.dirty = true
      else
        @$scope.LoadedPreset.initialChange = false

    # Watch data that should dirtify
    @$scope.$watch =>
      gradientType: @$scope.gradientType
      width: @$scope.bigCanvasWidth
      height: @$scope.bigCanvasHeight
      rotate: @$scope.rotateDegrees
      innerCircleX: @$scope.innerCircleX
      innerCircleY: @$scope.innerCircleY
      outerCircleX: @$scope.outerCircleX
      outerCircleY: @$scope.outerCircleY
      ColorHandles: @$scope.ColorHandles
    , (newData, oldData) ->
      # Some data actually changed
      if typeof newData != typeof oldData or
          newData.gradientType != oldData.gradientType or
          newData.width != oldData.width or
          newData.height != oldData.height or
          newData.rotate != oldData.rotate or
          newData.innerCircleX != oldData.innerCircleX or
          newData.innerCircleY != oldData.innerCircleY or
          newData.outerCircleX != oldData.outerCircleX or
          newData.outerCircleY != oldData.outerCircleY or
          angular.toJson(newData.ColorHandles) != angular.toJson(oldData.ColorHandles)
        manageLoadedPresetDirty()
    , true

  ###
    Saves currently loaded preset to local storage.

    @param {Boolean} [saveAs=false] TRUE to force "save as" with a new preset name.
  ###
  saveLoadedPreset: (saveAs = false) ->
    SavedPresets = @$scope.SavedPresets
    LoadedPreset = angular.extend new @GradientPreset, @$scope.LoadedPreset

    # Copy data from scope to loaded preset
    angular.extend LoadedPreset,
      gradientType: @$scope.gradientType
      width: @$scope.bigCanvasWidth
      height: @$scope.bigCanvasHeight
      rotate: @$scope.rotateDegrees
      innerCircleX: @$scope.innerCircleX
      innerCircleY: @$scope.innerCircleY
      outerCircleX: @$scope.outerCircleX
      outerCircleY: @$scope.outerCircleY
      ColorHandles: (angular.extend({}, ColorHandle) for ColorHandle in @$scope.ColorHandles)

    # Gradient is new or force "save as"
    if !LoadedPreset.id? or saveAs
      name = prompt 'Unique name for your preset:', ''
      name = prompt 'Name already in use. Try another (or cancel to abort):', '' while name isnt null and (
        Preset for Preset in SavedPresets when Preset.name == name
      ).length

      # Canceled
      if name is null then return

      LoadedPreset.id = LoadedPreset.name = name
      LoadedPreset.saveable = true
      LoadedPreset.deleteable = true
      SavedPresets.push LoadedPreset
    # Non-new
    else
      SavedPresets[i] = LoadedPreset for Preset, i in SavedPresets when Preset.id == LoadedPreset.id

    LoadedPreset.dirty = false

    # Save
    LoadedPreset.save()

    # "Load" back what was just saved
    @$scope.LoadedPreset = angular.extend new @GradientPreset, LoadedPreset

  ###
    Deletes currently loaded preset from local storage.
  ###
  deleteLoadedPreset: ->
    SavedPresets = @$scope.SavedPresets
    LoadedPreset = angular.extend new @GradientPreset, @$scope.LoadedPreset

    # Remove our copy
    for Preset, i in SavedPresets when Preset.id == LoadedPreset?.id
      SavedPresets.splice i, 1
      break

    # Remove from storage
    LoadedPreset.delete()

    # Mark as dirty, saveable, undeleteable, and unsaved
    angular.extend LoadedPreset,
      dirty: true
      saveable: true
      deleteable: false
      id: null
      name: null

    # Load back into scope
    @$scope.LoadedPreset = LoadedPreset

  sortColorHandlesByStop: ->
    @$scope.ColorHandles.sort (LeftHandle, RightHandle) -> LeftHandle.stop - RightHandle.stop