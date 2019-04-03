#= require ./base

u = up.util

class up.Change.Plan.OpenLayer extends up.Change.Plan

  preflightLayer: ->
    undefined

  preflightTarget: ->
    # The target will always "exist" in the current page, since
    # we're opening a new layer just for that.
    @options.target

  execute: ->
    # Selecting the content needs to happen sync, since our caller
    # might expect and catch up.ExtractPlan.NOT_APPLICABLE.
    content = @responseDoc.first(@options.target) or @notApplicable()

    # If we cannot push state for some reason, we prefer disabling history for
    # child layers instead of blowing up the entire stack with a full page load.
    unless up.browser.canPushState()
      options.history = false

    layer = up.layer.build(@options)

    promise = up.event.whenEmitted('up:layer:open', { layer, log: 'Opening layer' })
    promise = promise.then =>
      layer.openNow(up.layer.container(), content, { @onContentAttached })

    promise = promise.then -> up.emit('up:layer:opened', { layer, log: 'Layer opened' })
    promise

  onContentAttached: (layer, content) =>
    up.fragment.setSource(content, @options.source)

    # Calling up.hello() will compile the new content
    # and emit an up:fragment:inserted event.
    up.hello(content, @options)

    # Call updateHistory() with the original options so it contains
    # non-layer keys like { title } or { location }
    layer.updateHistory(@options)