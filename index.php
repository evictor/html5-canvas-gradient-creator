<!doctype html>
<html>
<head>
  <link rel="stylesheet" type="text/css" href="js/prettify/prettify.css" />
  <link rel="stylesheet" type="text/css" href="js/prettify/sunburst.css" />
  <link rel="stylesheet" type="text/css" href="css/iconic_fill.css" />
  <link rel="Stylesheet" type="text/css" href="js/jpicker/css/jPicker-1.1.6.min.css" />
  <link rel="Stylesheet" type="text/css" href="js/jpicker/jPicker.css" />
  <link rel="Stylesheet" type="text/css" href="js/qtip/jquery.qtip.min.css" />
  <link rel="stylesheet" type="text/css" href="css/style.css" />

  <meta http-equiv="Content-Type" content="text/html; charset=utf8" />
  <meta name="description" content="Easily generate JS and HTML needed for a custom canvas gradient." />
  <meta name="keywords" content="HTML5, gradient, generator, editor, creator, linear, radial, JavaScript, JS" />
  <title>HTML5 Canvas Gradient Creator</title>
</head>
<body ng-app="GradientCreatorApp" ng-controller="MainCtrl" on-dom-ready="loading = false">
  <h1>
    HTML5 Canvas Gradient Creator
    <span class="titleCredit">
      by <a href="http://ezekielvictor.com/">Ezekiel Victor</a>
      &ndash; <a href="http://victorblog.com/2013/03/05/html5-canvas-gradient-creator/">learn more</a>
    </span>
  </h1>
  <div class="clear"></div>

  <div ng-show="loading" class="loading">
    Loading...
    <div class="ballWrapper"><span class="ball"></span></div>
  </div>

  <div ng-hide="loading" ng-cloak>
    <div class="gradientEditorWrapper" ng-class="{hasActiveColorHandle: ActiveColorHandle != null}">
      <div class="colorHandlesWorkAreaWrapper" kill-context-menu-area>
        <div class="colorHandlesWorkArea">
          <canvas preview-canvas class="smallPreviewCanvas" gradient-type="'linear'" color-handles="ColorHandles"
                  width="543" height="35"></canvas>
          <div new-color-handle-click-area></div>
          <div ng-repeat="ColorHandle in ColorHandles" color-handle="ColorHandle" ng-cloak></div>
        </div>
        <form name="stopInputForm">
          <div class="colorHandleStopInputWrapper" ng-show="ActiveColorHandle" ng-cloak>
            <label for="activeColorHandleStopPercent">Position:</label>
            <input type="number" min="0" max="100" ng-model="activeColorHandleStopPercent"
                   id="activeColorHandleStopPercent" name="stop" />
            <label for="activeColorHandleStopPercent">%</label>
            <span ng-show="stopInputForm.stop.$error.min || stopInputForm.stop.$error.max" class="error">
              ← Must be between 0 and 100.
            </span>
          </div>
        </form>
      </div>

      <div color-picker="{
        window: {
          alphaSupport: true,
          effects: {
            speed: {
              show: 0
            }
          }
        }
      }" ng-show="ActiveColorHandle != null" ng-model="ActiveColorHandle.color"
         cancel="ActiveColorHandle = null"></div>

      <div class="instructions" ng-cloak>
        <a class="showLink" ng-show="!showInstructions" ng-click="showInstructions = true">+ Show instructions</a>
        <a class="hideLink" ng-show="showInstructions && ActiveColorHandle" ng-click="showInstructions = false">&ndash; Hide instructions</a>
        <div ng-show="showInstructions">
          <h2>Pro Tips</h2>
          <ul>
            <li>Right-click a color handle to remove it.</li>
            <li>Click and drag bottom-right corner of big gradient box to resize.</li>
          </ul>

          <h2>Basic Instructions</h2>
          <ul>
            <li>Click a color handle to bring up the color picker.</li>
            <li>Drag color handles left and right.</li>
            <li>Click in the empty space between color handles to add a new handle.</li>
          </ul>
        </div>
      </div>


      <div class="presetsWrapper">
        <h2 ng-show="SavedPresets.length">My presets</h2>
        <div class="preset" ng-repeat="Preset in SavedPresets" title="{{Preset.name}}" ng-click="applyPreset(Preset)"
             tooltip="presetTooltipOpts" ng-class="{
               loaded: LoadedPreset.id == Preset.id,
               dirty: LoadedPreset.id == Preset.id && LoadedPreset.dirty
             }">
          <canvas width="50" height="50" preview-canvas
                  gradient-type="Preset.gradientType"
                  color-handles="Preset.ColorHandles"
                  rotate="Preset.rotate"
                  inner-circle-x="Preset.innerCircleX"
                  inner-circle-y="Preset.innerCircleY"
                  outer-circle-x="Preset.outerCircleX"
                  outer-circle-y="Preset.outerCircleY"></canvas>
        </div>

        <h2 ng-hide="SavedPresets.length">Presets</h2>
        <h3 ng-show="SavedPresets.length">Built-in presets</h3>
        <div class="preset" ng-repeat="Preset in Presets" title="{{Preset.name}}" ng-click="applyPreset(Preset)"
             tooltip="presetTooltipOpts" ng-class="{
               loaded: LoadedPreset.id == Preset.id,
               dirty: LoadedPreset.id == Preset.id && LoadedPreset.dirty
             }">
          <canvas width="50" height="50" preview-canvas
                  gradient-type="'linear'"
                  color-handles="Preset.ColorHandles"
                  rotate="45"></canvas>
        </div>

        <h3>Just for fun</h3>
        <div class="preset" ng-repeat="Preset in FunPresets" title="{{Preset.name}}" ng-click="applyPreset(Preset)"
             tooltip="presetTooltipOpts" ng-class="{
               loaded: LoadedPreset.id == Preset.id,
               dirty: LoadedPreset.id == Preset.id && LoadedPreset.dirty
             }">
          <canvas width="50" height="50" preview-canvas gradient-type="Preset.gradientType"
                  color-handles="Preset.ColorHandles"
                  rotate="Preset.rotate"
                  inner-circle-x="Preset.innerCircleX"
                  inner-circle-y="Preset.innerCircleY"
                  outer-circle-x="Preset.outerCircleX"
                  outer-circle-y="Preset.outerCircleY"></canvas>
        </div>
      </div>

    </div>

    <div class="bigPreviewCanvasWrapper">
      <div class="gradientTypesAndPersistence">
        <div class="persistBtns" ng-show="localStorageSupported">
          <a class="btn save" title="Save" tooltip
              ng-show="LoadedPreset.dirty && (LoadedPreset.saveable || !LoadedPreset.id)"
              ng-click="saveLoadedPreset()"></a>

          <a class="btn saveAs" title="Save As..." tooltip
              ng-show="LoadedPreset.id"
              ng-click="saveLoadedPreset(true)"></a>

          <a class="btn delete" title="Delete" tooltip ng-show="LoadedPreset.id && LoadedPreset.deleteable"
              ng-click="deleteLoadedPreset()"></a>
        </div>
        <div class="gradientType">
          <input type="radio" ng-model="gradientType" value="linear"
            id="gradientTypeLinear" /><label for="gradientTypeLinear">Linear</label>
        </div>
        <div class="gradientType">
          <input type="radio" ng-model="gradientType" value="radial"
            id="gradientTypeRadial" /><label for="gradientTypeRadial">Radial</label>
        </div>
      </div>
      <canvas preview-canvas class="bigPreviewCanvas" gradient-type="gradientType" color-handles="ColorHandles"
              width="bigCanvasWidth" height="bigCanvasHeight" resizable-canvas
              rotate="rotateDegrees"
              inner-circle-x="innerCircleX" inner-circle-y="innerCircleY"
              outer-circle-x="outerCircleX" outer-circle-y="outerCircleY"
              html-code="gradientHtmlCode"
              js-code="gradientJsCode"></canvas>
      <form name="linearGradientForm" ng-show="gradientType == 'linear'" ng-cloak>
        <label for="rotateDegreesInput">Rotate:</label>
        <div slider value="rotateDegrees" min="0" max="360" precision="1"></div>
        <span ng-show="linearGradientForm.rotateDegrees.$error.min || linearGradientForm.rotateDegrees.$error.max"
              class="error sliderValueDispError">
          Must be between 0 and 360. →
        </span>
        <div class="sliderValueDisp">
          <input type="number" min="0" max="360" ng-model="rotateDegrees"
                 name="rotateDegrees" id="rotateDegreesInput" /> &deg;
        </div>
      </form>
      <form name="radialGradientForm" ng-show="gradientType == 'radial'" ng-cloak>
        <label for="innerCircleXInput">Inner circle X:</label>
        <div slider value="innerCircleX" min="0" max="100" precision="1"></div>
        <span ng-show="radialGradientForm.innerCircleX.$error.min || radialGradientForm.innerCircleX.$error.max"
              class="error sliderValueDispError">
          Must be between 0 and 100. →
        </span>
        <div class="sliderValueDisp">
          <input type="number" min="0" max="100" ng-model="innerCircleX" id="innerCircleXInput" name="innerCircleX" /> %
        </div>

        <label for="innerCircleYInput">Inner circle Y:</label>
        <div slider value="innerCircleY" min="0" max="100" precision="1"></div>
        <span ng-show="radialGradientForm.innerCircleY.$error.min || radialGradientForm.innerCircleY.$error.max"
              class="error sliderValueDispError">
          Must be between 0 and 100. →
        </span>
        <div class="sliderValueDisp">
          <input type="number" min="0" max="100" ng-model="innerCircleY" id="innerCircleYInput" name="innerCircleY" /> %
        </div>

        <label for="outerCircleXInput">Outer circle X:</label>
        <div slider value="outerCircleX" min="0" max="100" precision="1"></div>
        <span ng-show="radialGradientForm.outerCircleX.$error.min || radialGradientForm.outerCircleX.$error.max"
              class="error sliderValueDispError">
          Must be between 0 and 100. →
        </span>
        <div class="sliderValueDisp">
          <input type="number" min="0" max="100" ng-model="outerCircleX" id="outerCircleXInput" name="outerCircleX" /> %
        </div>

        <label for="outerCircleYInput">Outer circle Y:</label>
        <div slider value="outerCircleY" min="0" max="100" precision="1"></div>
        <span ng-show="radialGradientForm.outerCircleY.$error.min || radialGradientForm.outerCircleY.$error.max"
              class="error sliderValueDispError">
          Must be between 0 and 100. →
        </span>
        <div class="sliderValueDisp">
          <input type="number" min="0" max="100" ng-model="outerCircleY" id="outerCircleYInput" name="outerCircleY" /> %
        </div>
      </form>
    </div>

    <div class="gradientCodeWrapper" ng-cloak>
      <h2>HTML and JS for Your Gradient</h2>
      <div prettify="gradientHtmlPageCode" ng-cloak></div>
    </div>
  </div>

  <script type="text/javascript" src="js/jquery/jquery-1.9.0.min.js"></script>
  <script type="text/javascript" src="js/prettify/prettify.js"></script>
  <script type="text/javascript" src="js/jpicker/jpicker-1.1.6.min.js"></script>
  <script type="text/javascript" src="js/qtip/jquery.qtip.min.js"></script>
  <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/angularjs/1.0.4/angular.min.js"></script>
  <script type="text/javascript" src="js/local-storage/localStorageModule.min.js"></script>
  <script type="text/javascript" src="js/build/module/GradientCreatorApp.js"></script>
  <script type="text/javascript" src="js/build/model/ColorHandle.js"></script>
  <script type="text/javascript" src="js/build/model/GradientPreset.js"></script>
  <script type="text/javascript" src="js/build/directive/colorHandle.js"></script>
  <script type="text/javascript" src="js/build/directive/colorPicker.js"></script>
  <script type="text/javascript" src="js/build/directive/killContextMenuArea.js"></script>
  <script type="text/javascript" src="js/build/directive/newColorHandleClickArea.js"></script>
  <script type="text/javascript" src="js/build/directive/onDomReady.js"></script>
  <script type="text/javascript" src="js/build/directive/prettify.js"></script>
  <script type="text/javascript" src="js/build/directive/previewCanvas.js"></script>
  <script type="text/javascript" src="js/build/directive/resizableCanvas.js"></script>
  <script type="text/javascript" src="js/build/directive/slider.js"></script>
  <script type="text/javascript" src="js/build/directive/tooltip.js"></script>
  <script type="text/javascript" src="js/build/controller/MainCtrl.js"></script>
</body>
</html>