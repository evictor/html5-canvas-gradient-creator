###
  Apply this to an element to prevent the right-click context menu within that element.

  Usage:

    <ANY kill-context-menu-area>...</ANY>
###
GradientCreatorApp.directive 'killContextMenuArea', ->
  return (scope, elem) ->
    elem.bind 'contextmenu', false