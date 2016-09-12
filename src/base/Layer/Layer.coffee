# a layer is a top level positioned div
# which can be used to display Menu
# Popver, Modal, Autocompletion and
# other dialogs


class CUI.Layer extends CUI.DOM

	constructor: (@opts={}) ->
		super(@opts)

		@__layer = @getTemplate()

		# layer is registered as our main layer TODO register layer_root as our main layer!
		@registerTemplate(@__layer)
		# @__layer.DOM.attr("role", @_role)

		# layer root is a container for the backdrop, pointer and layer
		#
		# this is only to hold all nodes in one node, the backdrop is a sibling
		# of the layer, that way we can give the backdrop an opacity which does
		# not affect the layer's opacity as it would to if the layer would be
		# a child of backdrop
		@__layer_root = new Template
			class: "cui-layer-root-"+(toDash(@__cls)+" "+@_class).trim().split(/\s+/).join(" cui-layer-root-")
			name: "layer-root"

		@__backdropClickDisabled = false

		if @_backdrop or @_modal

			if @_modal
				@__bd_policy = "modal"
			else
				@__bd_policy = @_backdrop.policy or "click-thru"

			@__backdrop = new Template
				class: "cui-layer-backdrop"
				name: "layer-backdrop"

			@__backdrop.addClass("cui-layer-backdrop-policy-"+@__bd_policy)

			if @_backdrop.background_effect
				@__body_effect_class = "cui-layer-effect-" + @_backdrop.background_effect
				$(document.body).addClass(@__body_effect_class)

			if @_backdrop.content
				@setBackdropContent(@_backdrop.content)
			else if @_backdrop.blur

				# clone body
				body_clone = document.body.firstChild.cloneNode(true)

				if @__bd_policy == "click-thru"
					# backdrop needs to be cropped
					@__backdrop_crop = @__backdrop.DOM
					@setBackdropContent(body_clone)
				else
					@__backdrop_crop = $div("cui-layer-backdrop-body-clone")[0]
					@__backdrop_crop.appendChild(body_clone)
					@setBackdropContent(@__backdrop_crop)

				# console.error "crop this:", @__backdrop_crop

				@__layer_root.addClass("cui-layer-root-backdrop-blur")

			@__layer_root.DOM.appendChild(@__backdrop.DOM)

			# @__backdrop.DOM.attr("role", @_role)

			switch @__bd_policy
				when "click-thru"
					Events.listen
						type: "mousedown"
						node: @__backdrop
						call: (ev) =>
							if ev.ctrlKey() and ev.getButton() == 2
								return

							if @__backdropClickDisabled
								# this is used in Popover when all buttons are disabled
								# we need to eat this
								return

							@hide(ev)

							CUI.setTimeout
								ms: 0
								call: =>
									Events.trigger
										node: document.elementFromPoint(ev.clientX(), ev.clientY())
										type: "mousedown"
										button: ev.getButton()
										pageX: ev.pageX()
										pageY: ev.pageY()

							ev.stopPropagation()
							return


				when "click"
					Events.listen
						type: ["click", "contextmenu"]
						node: @__backdrop
						call: (ev) =>
							if ev.ctrlKey() and ev.getButton() == 2
								return

							if @__backdropClickDisabled
								return

							@hide(ev)
							ev.stopPropagation()

				when "modal"
					@__backdrop.addClass("layer-backdrop-modal")
					if @_backdrop.add_bounce_class != false
						if isString(@_backdrop.add_bounce_class)
							bc = @_backdrop.add_bounce_class
						else
							bc = "cui-layer-bounce"

						Events.listen
							type: "click"
							node: @__backdrop
							call: (ev) =>
								CUI.debug "clicked on modal backdrop", bc, @_backdrop
								if not @__layer
									return

								Events.wait
									type: "transitionend"
									node: @__layer
								.always =>
									if @isDestroyed()
										return

									@__layer.removeClass(bc)

								@__layer.addClass(bc)
								return

				else
					assert("new #{@__cls}", "Unknown backdrop policy: \"#{@__bd_policy}\".")

		if @_visible == false
			@setVisible(@_visible)

		@__layer_root.DOM.appendChild(@__layer.DOM)

		Events.listen
			type: "click"
			node: @__layer
			call: (ev) =>
				if not ev.altKey()
					return
				@hide()
				@show()

		if @_handle_focus
			DOM.setAttribute(@__layer.DOM, "tabindex", "0")

		if @_element
			@__setElement(@_element)

		if @_use_element_width_as_min_width
			assert(@__element, "new CUI.Layer", "opts.use_element_width_as_min_width requires opts.element to be set.", opts: @opts)

		if @_pointer
			if @_class
				cls = "cui-layer-pointer-"+@_class.split(/\s+/).join(" cui-layer-pointer-")

			@__pointer = new Template
				class: cls
				name: "layer-pointer"
			.DOM

			#append pointer and make sure pointer is rendered beneath layer.
			@__layer_root.DOM.appendChild(@__pointer)


		@__shown = false


	disableBackdropClick: ->
		@__backdropClickDisabled = true
		@

	enableBackdropClick: ->
		@__backdropClickDisabled = false
		@

	setBackdropContent: (content) ->
		assert(@__backdrop, "CUI.Layer.setBackdropContent", "No backdrop found in layer", layer: @)
		@__backdrop.DOM.append(content)

	getTemplate: ->
		new Template(name: "layer")

	getLayerRoot: ->
		@__layer_root

	getLayer: ->
		@__layer

	initOpts: ->
		super()
		@addOpts
			# role:
			#	mandatory: true
			#	check: String
			# set to true if a backdrop should be
			# added to the DOM tree
			backdrop:
				default:
					policy: "click-thru"
					add_bounce_class: true
					background_effect: null
					content: null

				check: (v) ->
					if CUI.isPlainObject(v) or v == false
						return true

			# if added, a bounce class will be added and after a css transition
			# removed to the layer, if the user clicks on a modal backdrop
			# the bounce class defaults to "cui-layer-bounce"
			add_bounce_class:
				deprecated: "use backdrop.add_bounce_class instead"


			# set to true, if a mousedown on the backdrop
			# does not destroy the layer
			# modal implies backdrop
			modal:
				deprecated: true
				check: Boolean
			onBeforeShow:
				check: Function
			onShow:
				check: Function
			onPosition:
				check: Function
			onHide:
				check: Function

			# handle focus on tab index
			handle_focus:
				default: true
				check: Boolean


			# a rectangle box to position the layer to
			# a pointer is a helper to show the position of the layer
			# allowed values are "arrow"
			pointer:
				check: ["arrow"]
			# the preferred placement
			placement:
				check: String
			placements:
				check: (v) ->
					if not CUI.isArray(v)
						return false
					for a in v
						if CUI.Layer.knownPlacements.indexOf(a) == -1
							return false
					return true

			# element to position the layer to
			element:
				check: (v) ->
					isElement(v) or isElement(v?.DOM)

			use_element_width_as_min_width:
				default: false
				check: Boolean

			show_at_position:
				check: (v) ->
					CUI.isPlainObject(v) and v.top >= 0 and v.left >= 0

			# fills the available space to the maximum
			# if used with "placement", the placement is not
			# chosen
			#
			# auto: check if width or height is already set, use the other
			#
			#
			# both: overwrite width and height, no matter what
			# horizontal: stretch width only
			# vertical: stretch height only
			fill_space:
				check: ["auto", "both", "horizontal", "vertical"]

			# if set, the Layer, when shown checks if the "element"
			# is still in the DOM tree
			check_for_element:
				default: false
				check: Boolean

			#
			# if set to true the Layer listens to content-resize events
			# and adjusts its size
			auto_size:
				default: false
				check: Boolean


			show_ms:
				default: 700
				check: (v) =>
					v > 0

			visible:
				check: Boolean

			hide_ms:
				default: 100
				check: (v) =>
					v > 0

			#
		@


	setVisible: (on_off=true) ->
		if on_off
			DOM.setStyleOne(@__layer_root.DOM[0], "visibility", "")
		else
			DOM.setStyleOne(@__layer_root.DOM[0], "visibility", "hidden")

	@knownPlacements: ["s", "e", "w", "ws", "wn", "n", "se", "ne", "es", "en", "nw", "sw", "c"]

	__setElement: (element) ->
		if element.DOM
			@__element = element.DOM
		else
			@__element = element

		assert(not DOM.closest(@__element, ".cui-tmpl"), "Layer.__setElement", "element cannot be inside a Template.", element: element)
		assert(@__element instanceof HTMLElement, "Layer.__setElement", "element needs to be HTMLElement.", element: element)
		@__element

	autoSize: ->
		@position()

	position: (ev) ->
		#
		set_more_dim = (dim) ->
			if dim == null
				return

			dim.halfHeight = dim.borderBoxHeight / 2
			dim.halfWidth = dim.borderBoxWidth / 2
			dim.viewportCenterHorizontal = dim.viewportLeft + dim.halfWidth
			dim.viewportCenterVertical = dim.viewportTop + dim.halfHeight

		dim_window = CUI.getViewport()

		if @__pointer
			dim_pointer = CUI.DOM.getDimensions(@__pointer)

			# reset pointer margin
			CUI.DOM.setStyle(@__pointer, margin: "")
		else
			dim_pointer =
				borderBoxWidth: 0
				borderBoxHeight: 0
				marginLeft: 0
				marginRight: 0
				marginTop: 0
				marginBottom: 0

		# reset previously set layer dimensions
		CUI.DOM.setStyle @__layer.DOM,
			top: 0
			left: 0
			width: ""
			height: ""
			margin: ""
			"max-width": ""
			"max-height": ""

		dim_layer = CUI.DOM.getDimensions(@__layer.DOM)
		allowed_placements = @_placements or CUI.Layer.knownPlacements
		wanted_placement = @_placement or allowed_placements[0]

		if @__element
			dim_element = CUI.DOM.getDimensions(@__element)

			if @_use_element_width_as_min_width
				dim_layer.borderBoxWidth = Math.max(dim_layer.borderBoxWidth, dim_element.borderBoxWidth)

		else if @_show_at_position
			dim_element =
				viewportTop: @_show_at_position.top
				viewportLeft: @_show_at_position.left

			dim_element.viewportBottom = dim_element.viewportTop
			dim_element.viewportRight = dim_element.viewportLeft
		else
			dim_element =
				viewportTop: 0
				viewportLeft: 0
				viewportBottom: dim_window.height
				viewportRight: dim_window.width
				borderBoxWidth: dim_window.width
				borderBoxHeight: dim_window.height

		set_more_dim(dim_element)
		set_more_dim(dim_pointer)
		set_more_dim(dim_layer)

		vp_pl = {}

		# calc all possible layer viewports
		for placement in CUI.Layer.knownPlacements
			if placement not in ["n", "s", "e", "w", "c"]
				continue

			vp_pl[placement] = vp = {}

			switch placement
				when "c"
					vp.top = dim_layer.marginTop
					vp.left = dim_layer.marginLeft
					vp.right = dim_window.width - dim_layer.marginRight
					vp.bottom = dim_window.height - dim_layer.marginBottom
					vp.align_vertical = "center"
					vp.align_horizontal = "center"
				when "n"
					vp.top = dim_layer.marginTop
					vp.left = dim_layer.marginLeft
					vp.right = dim_window.width - dim_layer.marginRight
					vp.bottom = dim_element.viewportTop - dim_pointer.borderBoxHeight - dim_pointer.marginBottom
					vp.align_vertical = "bottom"
					vp.align_horizontal = "center"
				when "s"
					vp.top = dim_element.viewportBottom + dim_pointer.borderBoxHeight + dim_pointer.marginTop
					vp.left = dim_layer.marginLeft
					vp.right = dim_window.width - dim_layer.marginRight
					vp.bottom = dim_window.height - dim_layer.marginBottom
					vp.align_vertical = "top"
					vp.align_horizontal = "center"
				when "e"
					vp.top = dim_layer.marginTop
					vp.right = dim_window.width - dim_layer.marginRight
					vp.bottom = dim_window.height - dim_layer.marginBottom
					vp.left = dim_element.viewportRight + dim_pointer.borderBoxWidth + dim_pointer.marginLeft
					vp.align_vertical = "center"
					vp.align_horizontal = "left"
				when "w"
					vp.top = dim_layer.marginTop
					vp.bottom = dim_window.height - dim_layer.marginBottom
					vp.right = dim_element.viewportLeft - dim_pointer.borderBoxWidth - dim_pointer.marginRight
					vp.left = dim_layer.marginLeft
					vp.align_vertical = "center"
					vp.align_horizontal = "right"

			vp.layer_align_vertical = vp.align_vertical
			vp.layer_align_horizontal = vp.align_horizontal


		# add two-direction placements
		for placement in CUI.Layer.knownPlacements
			if placement in ["n", "s", "e", "w", "c"]
				continue

			placement_parts = placement.split("")
			vp_pl[placement] = vp = copyObject(vp_pl[placement_parts[0]])

			if not vp
				continue

			switch placement_parts[1]
				when "s"
					vp.top = dim_element.viewportTop
					vp.align_vertical = "top"
					vp.layer_align_vertical = "center"
				when "n"
					vp.bottom = dim_element.viewportBottom
					vp.align_vertical = "bottom"
					vp.layer_align_vertical = "center"
				when "e"
					vp.left = dim_element.viewportLeft
					vp.align_horizontal = "left"
					vp.layer_align_horizontal = "center"
				when "w"
					vp.right = dim_element.viewportRight
					vp.align_horizontal = "right"
					vp.layer_align_horizontal = "center"


		# throw out placements which are too small
		for placement in CUI.Layer.knownPlacements
			if placement not in allowed_placements
				delete(vp_pl[placement])
				continue

			vp = vp_pl[placement]
			vp.width = vp.right - vp.left
			vp.height = vp.bottom - vp.top

			# placement might not be available, no space
			# FIXME: we can read minWidth & minHeight from layer
			# here, so the design can decide on a minimum
			if vp.width < 10 or vp.height < 10
				delete(vp_pl[placement])

		# now we need to position the layer within the available viewport
		for placement, vp of vp_pl

			layer_pos = vp.layer_pos = {}
			pointer_pos = vp.pointer_pos = {}

			# number of times we need to cut the layer
			# to make it fit into the viewport
			vp.cuts = 0

			pointer_pos.width = dim_pointer.borderBoxWidth
			pointer_pos.height = dim_pointer.borderBoxHeight

			# set width on height on the layer
			# depending on the available viewport and the
			# fill space policy
			switch @_fill_space
				when "both"
					layer_pos.width = vp.width
					layer_pos.height = vp.height
				when "vertical"
					layer_pos.height = vp.height
					layer_pos.width = dim_layer.borderBoxWidth
				when "horizontal"
					layer_pos.width = vp.width
					layer_pos.height = dim_layer.borderBoxHeight
				else
					layer_pos.width = dim_layer.borderBoxWidth
					layer_pos.height = dim_layer.borderBoxHeight

			if layer_pos.width > vp.width
				layer_pos.width = vp.width
				vp.cuts++

			if layer_pos.height > vp.height
				layer_pos.height = vp.height
				vp.cuts++

			# now align the layer within the available viewport
			switch vp.align_horizontal
				when "left"
					layer_pos.left = vp.left
				when "right"
					layer_pos.left = vp.right - layer_pos.width
				when "center"
					layer_pos.left = dim_element.viewportCenterHorizontal - layer_pos.width / 2

			switch vp.align_vertical
				when "top"
					layer_pos.top = vp.top
				when "bottom"
					layer_pos.top = vp.bottom - layer_pos.height
				when "center"
					layer_pos.top = dim_element.viewportCenterVertical - layer_pos.height / 2

			# move layer into viewport in case we overlap
			if layer_pos.top < vp.top
				layer_pos.top = vp.top
				vp.cuts++

			if layer_pos.left < vp.left
				layer_pos.left = vp.left
				vp.cuts++

			overlap_bottom = layer_pos.top + layer_pos.height - vp.bottom
			if overlap_bottom > 0
				layer_pos.top = layer_pos.top - overlap_bottom

			overlap_right = layer_pos.left + layer_pos.width - vp.right
			if overlap_right > 0
				layer_pos.left = layer_pos.left - overlap_right


			# now align the pointer within the available viewport
			switch vp.layer_align_horizontal
				when "left"
					pointer_pos.left = dim_element.viewportRight + dim_pointer.marginLeft
					pointer_pos.direction = "w"
				when "right"
					pointer_pos.left = dim_element.viewportLeft - dim_pointer.borderBoxWidth - dim_pointer.marginLeft
					pointer_pos.direction = "e"
				when "center"
					pointer_pos.left = dim_element.viewportCenterHorizontal - dim_pointer.borderBoxWidth / 2

			switch vp.layer_align_vertical
				when "top"
					pointer_pos.top = dim_element.viewportBottom + dim_pointer.marginTop
					pointer_pos.direction = "n"
				when "bottom"
					pointer_pos.top = dim_element.viewportTop - dim_pointer.marginBoxHeight + dim_pointer.marginTop
					pointer_pos.direction = "s"
				when "center"
					pointer_pos.top = dim_element.viewportCenterVertical - dim_pointer.borderBoxHeight / 2

		# pick best placement
		available_placements = []
		for placement, vp of vp_pl
			available_placements.push(placement)

		if vp_pl[wanted_placement]
			# wanted placement is available, we take it
			placement = wanted_placement
		else if available_placements.length == 1
			placement = available_placements[0]
		else
			# sort available placements
			available_placements.sort (a, b) ->
				compareIndex(a.width * a.height, b.width * b.height)

			# first is "c", so take it only if it is the only one
			placement = available_placements[1]

		if ev?.hasModifierKey()
			console.debug "layer", dim_layer
			console.debug "element", dim_element
			console.debug "pointer", dim_pointer
			console.debug "window", dim_window

			console.debug "placements", placement, vp_pl

			show_dbg_div = (placement) =>

				@__removeDebugDivs()

				_vp = vp_pl[placement]

				console.info("Layer: Placement", placement, _vp)

				@__dbg_div1 = CUI.DOM.element("DIV")
				@__dbg_div2 = CUI.DOM.element("DIV")
				@__dbg_div3 = CUI.DOM.element("DIV")

				style1 =
					position: "absolute"
					zIndex: 2
					border: "2px solid #ff0032"
					backgroundColor: "rgba(255, 0, 0, 0.4)"
					top: _vp.top
					left: _vp.left
					width: _vp.width
					height: _vp.height

				DOM.setStyle(@__dbg_div1, style1)

				style2 =
					position: "absolute"
					zIndex: 2
					border: "2px solid #00ff32"
					backgroundColor: "rgba(0, 255, 0, 0.4)"
					top: _vp.layer_pos.top
					left: _vp.layer_pos.left
					width: _vp.layer_pos.width
					height: _vp.layer_pos.height
					alignItems: "center"
					justifyContent: "center"
					fontSize: 40
					color: "rgb(0,255,50)"

				span = CUI.DOM.element("SPAN")
				span.textContent = placement

				@__dbg_div2.appendChild(span)
				DOM.setStyle(@__dbg_div2, style2)

				style3 =
					position: "absolute"
					zIndex: 2
					border: "2px solid #0032ff"
					backgroundColor: "rgba(0, 0, 255, 0.4)"
					top: _vp.pointer_pos.top
					left: _vp.pointer_pos.left
					width: _vp.pointer_pos.width
					height: _vp.pointer_pos.height

				DOM.setStyle(@__dbg_div3, style3)

				@__layer_root.DOM.appendChild(@__dbg_div1)
				@__layer_root.DOM.appendChild(@__dbg_div2)

				if @__pointer
					@__layer_root.DOM.appendChild(@__dbg_div3)

			dbg_pl = 0

			listener = Events.listen
				node: window
				type: "keyup"
				call: (ev, info) =>
					if ev.keyCode() != 32
						return

					while (true)
						dbg_pl = dbg_pl + 1
						if dbg_pl == CUI.Layer.knownPlacements.length
							@__removeDebugDivs()
							listener.destroy()
							return

						_placement = CUI.Layer.knownPlacements[dbg_pl]

						if vp_pl[_placement]
							show_dbg_div(_placement)
							return

						console.warn("Placement", _placement, "is unavailable.")
					return


		vp = vp_pl[placement]

		console.debug "Layer.position: Placement:", placement, "Wanted:", wanted_placement, "Allowed:", allowed_placements, "Viewports:", vp_pl, @

		# set layer
		CUI.DOM.setStyle @__layer.DOM,
			top: vp.layer_pos.top
			left: vp.layer_pos.left
			width: vp.layer_pos.width
			height: vp.layer_pos.height
			maxWidth: vp.width
			maxHeight: vp.height
			margin: 0

		if @__pointer
			# set pointer
			CUI.DOM.setStyle @__pointer,
				top: vp.pointer_pos.top
				left: vp.pointer_pos.left
				margin: 0

		if @__backdrop_crop
			DOM.setStyle @__backdrop_crop,
				top: vp.layer_pos.top
				left: vp.layer_pos.left
				width: vp.layer_pos.width
				height: vp.layer_pos.height

			DOM.setStyle @__backdrop_crop.firstChild,
				width: dim_window.width
				height: dim_window.height
				top: -vp.layer_pos.top
				left: -vp.layer_pos.left

		return

	__removeDebugDivs: ->
		@__dbg_div1?.remove()
		@__dbg_div2?.remove()
		@__dbg_div3?.remove()
		@__dbg_div1 = null
		@__dbg_div2 = null
		@__dbg_div3 = null


	clearTimeout: ->
		if @__timeout
			CUI.clearTimeout(@__timeout)
		@__timeout = null
		@

	showTimeout: (ms=@_show_ms, ev) ->
		# console.error "Layer.showTimeout ", @getUniqueId()

		@clearTimeout()
		dfr = new CUI.Deferred()
		@__timeout = CUI.setTimeout
			ms: ms
			track: false
			onReset: =>
				dfr.reject()
			onDone: =>
				dfr.resolve()
			call: =>
				if @__element and not @elementIsInDOM()
					@destroy()
					return
				@show(null, ev)
		dfr.promise()

	hideTimeout: (ms=@_hide_ms, ev) ->
		@clearTimeout()
		dfr = new CUI.Deferred()

		@__timeout = CUI.setTimeout
			ms: ms
			track: false
			onReset: =>
				dfr.reject()
			onDone: =>
				dfr.resolve()
			call: =>
				@hide(ev)

		dfr.promise()

	hide: (ev) ->
		#remove our fixed size
		@clearTimeout()
		if @isDestroyed()
			return

		if not @isShown()
			return @

		@__removeDebugDivs()

		if @__element
			if @__check_for_element
				CUI.clearInterval(@__check_for_element)
			@__element.removeClass("cui-layer-active")

		if @__body_effect_class
			$(document.body).removeClass(@__body_effect_class)
			@__body_effect_class = null

		@__layer_root.DOM.detach()
		@__shown = false

		if @_handle_focus
			@focusOnHide(ev)

		# if @__orig_element
		# 	@__element = @__orig_element
		# 	delete(@__orig_element)

		Events.ignore
			instance: @

		@_onHide?(@, ev)
		@

	# use element to temporarily overwrite element used
	# for positioning
	show: (ev) ->
		# console.error "show ", @getUniqueId()

		# "element" as first parameter is gone, i don't think we need this

		assert(not @isDestroyed(), "#{@__cls}.show", "Unable to show, Layer ##{@getUniqueId()} is already destroyed", layer: @)

		if Tooltip.current and @ not instanceof Tooltip
			Tooltip.current.hide()

		@clearTimeout()
		if @isShown()
			@position()
			return @

		# if element
		# 	@__orig_element = @__element
		# 	@__setElement(element)

		# @__layer.DOM.css
		# 	top: 0
		# 	left: 0

		document.body.appendChild(@__layer_root.DOM)

		if @_element
			@_element.addClass("cui-layer-active")

			if @_check_for_element
				@__check_for_element = CUI.setInterval =>
					if not @elementIsInDOM()
						@destroy()
				,
					200

		if @_auto_size
			Events.listen
				type: "content-resize"
				instance: @
				node: @__layer
				call: (ev) =>
					console.info("Layer caught event:", ev.getType)
					@position()

		Events.listen
			type: "viewport-resize"
			instance: @
			node: @__layer
			call: (ev) =>
				if @__element and not @elementIsInDOM()
					# ignore the event
					return

				console.info("Layer caught event:", ev.getType)
				@position()
				return

		@_onBeforeShow?(@, ev)
		@__shown = true

		@position(ev)
		if @_handle_focus
			@focusOnShow(ev)

		@_onShow?(@, ev)
		@

	isKeyboardCancellable: (ev) ->
		if @__bd_policy in ["click", "click-thru"] and not @__backdropClickDisabled
			true
		else
			false

	doCancel: (ev) ->
		@hide(ev)

	focusOnShow: (ev) ->
		if ev == CUI.KeyboardEvent
			@__focused_on_show = true
		else if @__element and DOM.matchSelector(document.documentElement, ":focus").length > 0
			; # @__focused_on_show = true
		else
			@__focused_on_show = false

		if @__focused_on_show
			@DOM[0].focus()
		@

	focusOnHide: (ev) ->
		if not @__element
			return @

		if ev == CUI.KeyboardEvent or @__focused_on_show
			DOM.findElement(@__element[0], "[tabindex]")?.focus()
		@

	elementIsInDOM: ->
		# console.debug "element:", @__element, @, @_element, @getUniqueId()
		@__element and DOM.isInDOM(@__element[0])

	getElement: ->
		@__element

	isShown: ->
		@__shown


	destroy: ->
		# CUI.error "Layer.destroy",@, @isDestroyed()
		@clearTimeout()
		if @__shown
			@hide()

		super()

		@__layer?.destroy()
		@__layer_root?.destroy()

		@__layer = null
		@__layer_root = null

		@__pointer?.remove()
		@__pointer = null

		@__backdrop?.destroy()
		@__backdrop = null


CUI.ready ->
	Events.listen
		type: "keyup"
		node: document
		call: (ev) ->
			if ev.keyCode() != 27
				return

			layer_elements = DOM.findElements(document.body, "body > .cui-tmpl-layer-root > .cui-layer")
			layer_element = layer_elements[layer_elements.length-1]
			element = DOM.closest(ev.getTarget(), "[tabindex],input,textarea")

			if (element and element != layer_element) or not layer_element
				# ignore this
				return

			ev.stopImmediatePropagation()
			ev.preventDefault()

			layer = DOM.data(layer_element, "element")
			if layer.isKeyboardCancellable(ev)
				layer.doCancel(ev)
				return false
			return