###
  Basic wrapper for Mike Samuel's Prettify plugin (code syntax highlighter). Code language is inferred by Prettify.

  Usage:
    <div prettify="{expression}"></div>

    prettify - {expression} - Code to prettify (probably given as a variable or function on your scope).

  @link http://code.google.com/p/google-code-prettify/
###
GradientCreatorApp.directive 'prettify', ($timeout) ->
  scope: prettify: '='
  template: '<pre class="prettyprint"></pre>'
  link: (scope, elem, attrs) ->
    $pre = elem.find 'pre'

    # Redraw on content change
    scope.$watch 'prettify', (content) ->
      $pre.text content
      prettyPrint()