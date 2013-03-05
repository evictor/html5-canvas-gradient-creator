###
  Uses qTip and title attribute to make a tooltip.

  Usage:
    <ANY title="{String}" tooltip="{expression}">...</ANY>

    title - {String} - Tooltip text.
    tooltip - {expression} - qTip options.
###
GradientCreatorApp.directive 'tooltip', ->
  (scope, elem, attrs) ->
    throw 'qTip not loaded.' if !jQuery.fn.qtip?

    elem.qtip scope.$eval(attrs.tooltip || '{}');