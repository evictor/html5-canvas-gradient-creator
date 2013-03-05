###
  Wrapper of jPicker color picker.

  Usage:
    <ANY color-picker="{expression}" ng-model="{expression}" [cancel="{expression}"]></ANY>

    colorPicker - {expression} - Options object for jPicker.
    ngModel - {expression} - Committed color will be bound to or read from this model.
    cancel - {expression} - Optional expression to eval on color picker cancel.

  Color model will always be set to rgba color or null; will only accept rgba and null input.
###
GradientCreatorApp.directive 'colorPicker', ($timeout) ->
  require: 'ngModel'
  link: (scope, elem, attrs, ngModelCtrl) ->
    domElem = elem[0]

    # Init jPicker
    opts = angular.extend {images: clientPath: 'js/jpicker/images/'}, scope.$eval attrs.colorPicker
    commitColor = (color) -> scope.$apply ->
      rgba = color.val 'rgba'
      ngModelCtrl.$setViewValue if rgba then "rgba(#{rgba.r}, #{rgba.g}, #{rgba.b}, #{rgba.a / 255})" else null
    elem.jPicker opts, commitColor, null, -> if attrs.cancel? then scope.$apply -> scope.$eval attrs.cancel

    # Color model change
    ngModelCtrl.$formatters.push (color) ->
      if color
        colorParts = color.replace(/[^\d.,]/g, '').split(',')

        rgba =
          r: parseInt colorParts[0]
          g: parseInt colorParts[1]
          b: parseInt colorParts[2]
          a: 255 * parseFloat colorParts[3]
        domElem.color.active.val 'rgba', rgba
        domElem.color.current.val 'rgba', rgba

    # Honor ngShow
    scope.$watch attrs.ngShow, (show) -> $timeout -> elem.toggle show