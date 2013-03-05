###
  Eval's a scope expression on DOM ready.

  Usage:
    <ANY on-dom-ready="{expression}">...</ANY>

    onDomReady - {expression} - Eval'd on scope.
###
GradientCreatorApp.directive 'onDomReady', ->
  (scope, elem, attrs) ->
    jQuery -> scope.$apply attrs.onDomReady