class Tooltip extends LayerPane
	constructor: (@opts = {}) ->
		super(@opts)
		assert(xor(@_text, @_content), "new #{@__cls}", "One of opts.text or opts.content must be set.", opts: @opts)

		if not $.isFunction(@_text) and not $.isFunction(@_content)
			@__static = true
			@fillContent()
		else
			@__static = false

		# object to register events on the element
		@__dummyInst = new Dummy()

		if @_on_hover
			assert( @__element, "Element not set in Tooltip." )
			Events.listen
				type: "mouseenter"
				instance: @__dummyInst
				node: @__element
				call: (ev) =>
					if window.globalDrag
						return

					if @_on_hover == true or @_on_hover(@)
						@showTimeout(null, ev)
					return

			Events.listen
				type: "mouseleave"
				instance: @__dummyInst
				node: @__element
				call: (ev) =>
					if window.globalDrag
						@hide(ev)
						Tooltip.current = null
					else
						@hideTimeout(null, ev)
						.done =>
							Tooltip.current = null
					return

			@__element.addClass("cui-dom-element-has-tooltip cui-dom-element-has-tooltip-on-hover")
			return

		if @_on_click
			@__element.addClass("cui-dom-element-has-tooltip cui-dom-element-has-tooltip-on-click")

			Events.listen
				type: "mouseup"
				instance: @__dummyInst
				node: @__element
				call: (ev) =>
					@show()
					return

	initOpts: ->
		super()
		@addOpts
			text:
				check: (v) ->
					isString(v) or $.isFunction(v)
			markdown:
				mandatory: true
				default: false
				check: Boolean
			content:
				check: (v) ->
					isString(v) or $.isFunction(v) or isElement(v) or $.isArray(v) or isElement(v?.DOM)
			# hide/show on click on element
			on_click:
				mandatory: true
				default: false
				check: Boolean
			# hide/show on click on hover
			on_hover:
				check: (v) ->
					isBoolean(v) or $.isFunction(v)

		return


	readOpts: ->
		if not @opts.hasOwnProperty("on_hover")
			@opts.on_hover = not @opts.on_click

		# if isUndef(@opts.anchor)
		#	@opts.anchor = @opts.element
		if @opts.on_click
			if not @opts.backdrop
				@opts.backdrop = {}
			if not @opts.backdrop.policy
				@opts.backdrop.policy = "click"

		if isUndef(@opts.backdrop)
			@opts.backdrop = false
		# @opts.role = "tooltip"
		@opts.pointer = "arrow"
		@opts.check_for_element = true
		@opts.placement = @opts.placement or "n"

		super()

		assert(not (@_on_click and @_on_hover), "new Tooltip", "opts.on_click and opts.on_hover cannot be used together.", opts: @opts)
		@

	@current: null # global to store currently shown tooltip

	focusOnHide: (ev) ->

	focusOnShow: (ev) ->

	showTimeout: (ms=@_show_ms, ev) ->
		if Tooltip.current
			Tooltip.current.hide(ev)
			@show(ev)
		else
			super(null, ev)
		@

	hide: (ev) ->
		super(ev)
		Tooltip.current = null

	show: (ev) ->
		Tooltip.current = @
		if @__static
			super(null, ev)
		else
			@fillContent()
			.done =>
				super(null, ev)
		@

	fillContent: ->
		dfr = new CUI.Deferred()

		dfr.fail =>
			@__pane.empty("center")

		fill_text = (text) =>
			if isEmpty(text)
				return dfr.reject()

			fill_content(new Label(markdown: @_markdown, text: text, multiline: true))

		fill_content = (content) =>
			if not content
				return dfr.reject()

			@__pane.replace(content, "center")
			dfr.resolve()

		if $.isFunction(@_text)
			ret = @_text.call(@, @)
			if isPromise(ret)
				ret.done (text) ->
					fill_text(text)
				ret.fail ->
					dfr.reject()
			else
				fill_text(ret)
		else if $.isFunction(@_content)
			ret = @_content.call(@, @)
			if isPromise(ret)
				ret.done (text) ->
					fill_content(text)
				ret.fail (xhr) ->
					dfr.reject(xhr)
			else
				fill_content(ret)
		else if not isEmpty(@_text)
			fill_text(@_text)
		else
			fill_content(@_content)


		dfr.promise()

	preventOverflow: ->
		super()
		@DOM.width(@__layer_dim._css_width)

	resetLayer: ->
		super()
		# @DOM.css("width", "200px")
		@DOM.css("max-width", @__viewport.width/2)

	destroy: ->
		Events.ignore(instance: @__dummyInst)
		super()
		@__element.removeClass("cui-dom-element-has-tooltip cui-dom-element-has-tooltip-on-hover cui-dom-element-has-tooltip-on-click")


