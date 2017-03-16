###
 * coffeescript-ui - Coffeescript User Interface System (CUI)
 * Copyright (c) 2013 - 2016 Programmfabrik GmbH
 * MIT Licence
 * https://github.com/programmfabrik/coffeescript-ui, http://www.coffeescript-ui.org
###

class CUI.LayerPane extends CUI.Layer

	constructor: (@opts={}) ->
		super(@opts)
		@setPane(@_pane)

	initOpts: ->
		super()
		@addOpts
			pane:
				mandatory: true
				default:
					new SimplePane()
				check: (v) ->
					v instanceof Pane or CUI.isPlainObject(v)

	getPane: ->
		@__pane

	setPane: (pane) ->
		if CUI.isPlainObject(pane)
			# for k in ["force_header", "force_footer"]
			# 	if not pane.hasOwnProperty(k)
			# 		pane[k] = true

			@__pane = new SimplePane(pane)

			if @__pane.hasHeader()
				@__layer_root.DOM.classList.add("ez5-simple-pane--has-header")
		else
			@__pane = pane
		@__pane.addClass("cui-layer-pane");
		# add pane to layer, using the layers append
		# method, so subclasses (like Modal does!) cannot interfer
		CUI.Layer::replace.call(@, @__pane)

	destroy: ->
		# CUI.debug "destroying pane", @__pane
		@__pane.destroy()
		super()
