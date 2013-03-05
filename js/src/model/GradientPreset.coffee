###
  Gradient preset with ID, name, color handles, persistence, etc.

  @param {Object} localStorageService From "LocalStorageModule".
###
GradientCreatorApp.factory 'GradientPreset', (localStorageService) ->
  localStorageKey = 'SavedPresets'

  class GradientPreset
    ###
      @param {String}  [id=]
      @param {String}  [name=]
      @param {String}  gradientType       "linear" or "radial"
      @param {Number}  width              Pixel width.
      @param {Number}  height             Pixel height.
      @param {Number}  rotate             Rotation in degrees 0-360 ("linear" gradientType only).
      @param {Number}  innerCircleX       Percent from 0-100 ("radial" gradientType only).
      @param {Number}  innerCircleY       Percent from 0-100 ("radial" gradientType only).
      @param {Number}  outerCircleX       Percent from 0-100 ("radial" gradientType only).
      @param {Number}  outerCircleY       Percent from 0-100 ("radial" gradientType only).
      @param {Array}   ColorHandles       Array of ColorHandle.
      @param {Boolean} [saveable=false]
      @param {Boolean} [deleteable=false]
      @param {Boolean} [dirty=false]
    ###
    constructor: (
      @id
      @name
      @gradientType
      @width
      @height
      @rotate
      @innerCircleX
      @innerCircleY
      @outerCircleX
      @outerCircleY
      @ColorHandles
      @saveable = false
      @deleteable = false
      @dirty = false
    ) ->

    ###
      @return {GradientPreset} Deep clone of this preset.
    ###
    clone: ->
      angular.extend {}, @,
        ColorHandles: (angular.extend({}, CH) for CH in @ColorHandles)

    ###
      @return {Array} Array of gradient presets saved to storage.
    ###
    @query: ->
      # Fetch from storage and convert each to this class
      for presetConfig in angular.fromJson localStorageService.get(localStorageKey) ? '[]'
        angular.extend(new @, presetConfig)

    ###
      Saves this preset to storage.
    ###
    save: ->
      throw "This preset isn't saveable." if not @saveable

      # Get from storage
      SavedPresets = GradientPreset.query()

      # Save it over the top of preset with same ID if possible
      wasSaved = false
      for Preset, i in SavedPresets when Preset.id == @id
        SavedPresets[i] = @
        wasSaved = true

      # Didn't find one with same ID (new preset)
      if !wasSaved then SavedPresets.push @

      # Save all to storage
      localStorageService.add localStorageKey, angular.toJson SavedPresets

    ###
      Deletes this preset from storage.
    ###
    delete: ->
      throw "This preset isn't saveable." if not @deleteable

      # Get from storage
      SavedPresets = GradientPreset.query()

      # Remove
      for Preset, i in SavedPresets when Preset.id == @id
        SavedPresets.splice i, 1
        break

      # Save all to storage
      localStorageService.add localStorageKey, angular.toJson SavedPresets