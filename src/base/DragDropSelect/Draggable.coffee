globalDrag = null

class CUI.Draggable extends CUI.DragDropSelect
	@cls = "draggable"

	initOpts: ->
		super()
		@addOpts
			dragClass:
				default: "cui-dragging"
				check: String

			helper:
				default: "clone"
				check: (v) ->
					v == "clone" or isElement(v) or CUI.isFunction(v)

			helper_contain_element:
				check: (v) ->
					isElement(v)

			helper_set_pos:
				check: Function

			dragend:
				check: Function

			dragstart:
				check: Function

			dragging:
				check: Function

			create:
				default: -> true
				check: Function

			axis:
				check: ["x", "y"]

			# helper_remove_always:
			# 	check: Boolean

			# helper_parent:
			# 	default: "document"
			# 	check: ["document", "parent"]

			threshold:
				default: 2
				check: (v) ->
					v >= 0

			ms:
				default: CUI.MouseIsDownListener.interval_ms
				check: (v) ->
					# must be multiple of MouseIsDownListener.interval_ms or 0
					v % CUI.MouseIsDownListener.interval_ms == 0

			selector:
				check: (v) =>
					isString(v) or CUI.isFunction(v)

	__killTimeout: ->
		if globalDrag?.autoRepeatTimeout
			CUI.clearTimeout(globalDrag.autoRepeatTimeout)
			globalDrag.autoRepeatTimeout = null
		@

	__cleanup: ->
		@__killTimeout()
		if @__ref
			Events.ignore(instance: @__ref)
			@__ref = null
		globalDrag = null

	destroy: ->
		super()
		globalDrag?.helperNode?.remove()
		@__cleanup()
		@

	init: ->
		# CUI.debug "Draggable", @options.selector
		assert(not @_helper_contain_element or CUI.DOM.closest(@_element, @_helper_contain_element), "new Draggable", "opts.helper_contain_element needs to be parent of opts.element", opts: @opts)

		DOM.addClass(@element, "no-user-select")

		Events.listen
			type: "mouseisdown"
			node: @element
			capture: true
			instance: @
			selector: @_selector
			call: (ev) =>
				# CUI.debug getObjectClass(@), "drag drop mouseisdown...", ev.getUniqueId(), ev.getMilliseconds(), ev.isImmediatePropagationStopped()
				if ev.getButton() > 0
					# ignore if not the main button
					return

				if window.globalDrag
					# ignore if dragging is in progress
					return

				switch ev.getMilliseconds()
					when @_ms
						# hint possible click event listeners like Sidebar to
						# not execute the click anymore...
						#
						position = elementGetPosition(getCoordinatesFromEvent(ev), $(ev.getTarget()))
						dim = DOM.getDimensions(ev.getTarget())

						if dim.clientWidthScaled > 0 and position.left - dim.scrollLeftScaled > dim.clientWidthScaled
							CUI.warn("Mouseisdown on a vertical scrollbar, not starting drag.")
							return

						if dim.clientHeightScaled > 0 and position.top - dim.scrollTopScaled > dim.clientHeightScaled
							CUI.warn("Mouseisdown on a horizontal scrollbar, not starting drag.")
							return

						target = ev.getCurrentTarget()
						target_dim = DOM.getDimensions(target)
						if not DOM.isInDOM(target) or target_dim.clientWidth == 0 or target_dim.clientHeight == 0
							return

						$target = $(target)

						# CUI.debug "attempting to start drag", ev.getUniqueId(), $target[0]

						@init_drag(ev, $target)
					else
						return
				return

	init_drag: (ev, $target) ->

		overwrite_options = {}
		globalDrag = @_create?(ev, overwrite_options, $target)

		if globalDrag == false
			CUI.debug("not creating drag handle, opts.create returned 'false'.", ev)
			return

		for k, v of overwrite_options
			@["_#{k}"] = v

		if isNull(globalDrag) or globalDrag == true
			globalDrag = {}

		assert(CUI.isPlainObject(globalDrag), "CUI.Draggable.init_drag", "returned data must be a plain object", data: globalDrag)
		point = getCoordinatesFromEvent(ev)
		position = elementGetPosition(point, $target)

		init =
			$source: $target
			startEvent: ev
			startCoordinates: point
			startScroll:
				top: $target[0].scrollTop
				left: $target[0].scrollLeft
			start: position # offset to the $target
			threshold: @_threshold

		# CUI.debug "drag drop init", init
		for k, v of init
			globalDrag[k] = v

		# CUI.debug "starting drag...", globalDrag

		ev.stopImmediatePropagation()
		# ev.preventDefault()

		@before_drag(ev, $target)

		@__ref = new CUI.Dummy() # instance to easily remove events

		$target = null

		dragover_scroll = (mousemoveEvent) =>

			# the mousemove event is repeated automatically
			# the _counter provides a way for users to figure out if the event
			# is a repeated one or not
			if not mousemoveEvent.hasOwnProperty("_counter")
				mousemoveEvent._counter = 0
			else
				mousemoveEvent._counter++

			# send our own scroll event
			Events.trigger
				type: "dragover-scroll"
				node: $target
				info:
					mousemoveEvent: mousemoveEvent

			globalDrag.autoRepeatTimeout = CUI.setTimeout
				ms: 100
				track: false
				call: =>
					dragover_scroll(mousemoveEvent)

		Events.listen
			node: document
			type: "mousemove"
			instance: @__ref
			call: (ev) =>
				if not globalDrag
					return

				# this prevents chrome from focussing element while
				# we drag
				ev.preventDefault()

				# remove selection in firefox
				if document.selection
					document.selection.empty()
				else
					window.getSelection().removeAllRanges()

				# ok, in firefox the target of the mousemove
				# event is WRONG while dragging. we need to overwrite
				# this with elementFromPoint, true story :(
				pointTarget = ev.getPointTarget()
				@__killTimeout()

				if not pointTarget
					return

				$target = $(pointTarget)
				dragover_scroll(ev)

				if globalDrag.dragend
					return

				coordinates = getCoordinatesFromEvent(ev)

				diff =
					x: coordinates.pageX - globalDrag.startCoordinates.pageX
					y: coordinates.pageY - globalDrag.startCoordinates.pageY
					eventPoint: coordinates

				switch @_axis
					when"x"
						diff.y = 0
					when "y"
						diff.x = 0

				diff.x += globalDrag.$source.scrollLeft - globalDrag.startScroll.left
				diff.y += globalDrag.$source.scrollTop - globalDrag.startScroll.top

				if Math.abs(diff.x) >= globalDrag.threshold or
					Math.abs(diff.y) >= globalDrag.threshold or
					globalDrag.dragStarted

						if not globalDrag.dragStarted
							@__startDrag(ev, $target, diff)

						globalDrag.dragDiff = diff

						@do_drag(ev, $target, diff)
						@_dragging?(ev, $target, diff)
				return


		Events.listen
			node: document
			type: ["mouseup", "keyup"]
			capture: true
			instance: @__ref
			call: (ev) =>
				if ev.getType() == "keyup" and ev.keyCode() == 83 and ev.altKey() # ALT-S
					CUI.warn("Stopping Drag and Drop")
					@__cleanup()
					return

				if not (ev.getType() == "mouseup" or ev.keyCode() == 27)
					return

				# CUI.debug "mouseup/keyup: ", ev.getType()
				ev.preventDefault()
				# CUI.debug "draggable", ev.type
				#
				globalDrag.dragend = true
				if globalDrag.dragStarted
					@end_drag(ev)
					@_dragend?(ev, globalDrag, @)
				@__cleanup()
				# CUI.debug "mouseup, resetting drag stuff"
				#
		return


	__startDrag: (ev, $target, diff) ->
		Events.listen
			type: "click"
			node: window.globalDrag.startEvent.getCurrentTarget()
			capture: true
			only_once: true
			call: (ev, info) ->
				ev.stopPropagation()
				return

		# CUI.debug "start drag", diff
		@_dragstart?(ev, window.globalDrag)
		@init_helper(ev, $target, diff)
		globalDrag.$source.addClass(@_dragClass)
		@start_drag(ev, $target, diff)
		globalDrag.dragStarted = true

	# call after first mousedown
	before_drag: ->

	start_drag: (ev, $target, diff) ->

	# do drag
	# first call
	do_drag: (ev, $target, diff) ->

		# position helper
		@position_helper(ev, $target, diff)

		if globalDrag.dragoverTarget and globalDrag.dragoverTarget[0] != $target[0]
			Events.trigger
				type: "cui-dragleave"
				node: globalDrag.dragoverTarget
				info:
					globalDrag: globalDrag
					originalEvent: ev

			globalDrag.dragoverTarget = null

		if not globalDrag.dragoverTarget
			globalDrag.dragoverTarget = $target
			# console.debug "target:", $target
			Events.trigger
				type: "cui-dragenter"
				node: globalDrag.dragoverTarget
				info:
					globalDrag: globalDrag
					originalEvent: ev

		# trigger our own dragover event on the correct target
		Events.trigger
			node: globalDrag.dragoverTarget
			type: "cui-dragover"
			info:
				globalDrag: globalDrag
				originalEvent: ev

		return

	# find_target: (ev, $target=$(ev.getTarget())) ->
	# 	# hide helper and a drag-drop-select-transparent div
	# 	# if necessaray
	# 	$hide = $target.closest(".cui-drag-drop-select-transparent")
	# 	if $hide.length
	# 		# hide helper and determine the "real" target
	# 		oldDisplay = $hide[0].style.display
	# 		$hide.css(display: "none")
	# 		$target = @find_target(ev, $(document.elementFromPoint(ev.clientX(), ev.clientY())))
	# 		$hide.css(display: oldDisplay)
	# 	$target

	end_drag: (ev) ->
		# CUI.debug globalDrag.dragoverTarget, ev.getType(), ev

		if @isDestroyed()
			return

		helper_animate_back = false

		if globalDrag.dragoverTarget
			# CUI.debug "sending pf_dragleave", globalDrag.dragoverTarget
			# CUI.debug "pf_dragleave.event", globalDrag.dragoverTarget[0]

			CUI.Events.trigger
				node: globalDrag.dragoverTarget
				type: "cui-dragleave"
				info:
					globalDrag: globalDrag
					originalEvent: ev

			if ev.getType() == "mouseup"
				drop_event = CUI.Event.require
					type: "cui-drop"
					node: globalDrag.dragoverTarget
					info:
						globalDrag: globalDrag
						originalEvent: ev

				CUI.Events.trigger(drop_event)

				# it can happen that the trigger deletes globalDrag by removing the
				# draggable element, so we need to check if that has happened and
				# do nothing in case
				if not globalDrag
					return

				if drop_event.isPropagationStopped()
					# currently unimplemented
					helper_animate_back = false

			globalDrag.dragoverTarget = null

		# animate the helperNode back to its origin
		globalDrag.$source.removeClass(@_dragClass)
		globalDrag.helperNode?.remove()
		@

	position_helper: (ev, $target, diff) ->
		if not globalDrag.helperNode
			return

		top = globalDrag.helperNodeStart.top + diff.y
		left = globalDrag.helperNodeStart.left + diff.x

		helper_pos =
			top: top
			left: left
			start:
				top: globalDrag.helperNodeStart.top
				left: globalDrag.helperNodeStart.left

		if @_helper_contain_element
			dim_contain = CUI.DOM.getDimensions(@_helper_contain_element)

			pos =
				x: helper_pos.left
				y: helper_pos.top
				w: globalDrag.helperNodeStart.width
				h: globalDrag.helperNodeStart.height

			# pos is changed in place
			Draggable.limitRect pos,
				min_x: dim_contain.viewportLeft + dim_contain.borderLeftWidth
				max_x: dim_contain.viewportRight - dim_contain.borderRightWidth
				min_y: dim_contain.viewportTop + dim_contain.borderTopWidth
				max_y: dim_contain.viewportBottom - dim_contain.borderBottomWidth

			helper_pos =
				top: pos.y
				left: pos.x

			helper_pos.dragDiff =
				y: helper_pos.top - globalDrag.helperNodeStart.top
				x: helper_pos.left - globalDrag.helperNodeStart.left

		else
			helper_pos.dragDiff =
				y: diff.y
				x: diff.x

		@_helper_set_pos?(globalDrag, helper_pos)

		CUI.DOM.setStyle globalDrag.helperNode,
			top: helper_pos.top
			left: helper_pos.left

		# console.debug "FINAL helper pos:", globalDrag, diff,  "top", top, "left", left, dump(helper_pos)

	getSourceCloneForHelper: ->
		globalDrag.$source.cloneNode(true)

	init_helper: (ev, $target, diff) ->
		drag_source = globalDrag.$source

		if @_helper == "clone"
			hn = CUI.jQueryCompat(@getSourceCloneForHelper())
			# offset the layer to the click
			offset =
				top: globalDrag.start.top
				left: globalDrag.start.left

		if CUI.isFunction(@_helper)
			hn = globalDrag.helperNode = @_helper(globalDrag)
			offset =
				top: 0
				left: 0
			set_dim = null

		if not hn
			return

		globalDrag.helperNode = hn

		hn.addClass("drag-drop-select-helper cui-debug-node-copyable cui-drag-drop-select-transparent")

		start =
			top: globalDrag.startCoordinates.pageY - offset.top
			left: globalDrag.startCoordinates.pageX - offset.left

		CUI.DOM.setStyle hn,
			position: "absolute"
			top: start.top
			left: start.left
			zIndex: 1000

		# console.debug "INITIAL POS", globalDrag.startCoordinates.pageY - offset.top, globalDrag.startCoordinates.pageX - offset.left
		document.body.appendChild(hn)

		if @_helper == "clone"
			# set width & height
			set_dim = DOM.getDimensions(drag_source)

			DOM.setDimensions hn,
				marginBoxWidth: set_dim.marginBoxWidth
				marginBoxHeight: set_dim.marginBoxHeight

		dim = DOM.getDimensions(hn)

		# console.debug "globalDrag", globalDrag, offset, hn, set_dim.marginBoxWidth, set_dim.marginBoxHeight

		start.width = dim.borderBoxWidth
		start.height = dim.borderBoxHeight
		start.marginTop = dim.marginTop
		start.marginLeft = dim.marginLeft

		globalDrag.helperNodeStart = start


	# keep pos inside certain constraints
	# pos.fix is an Array containing any of "n","w","e","s"
	# limitRect: min_w, min_h, max_w, max_h, min_x, max_x, min_y, max_y
	# !!! The order of the parameters is how we want them, in Movable it
	# is different for compability reasons
	@limitRect: (pos, limitRect, defaults={}) ->
		pos.fix = pos.fix or []
		for k, v of defaults
			if isUndef(pos[k])
				pos[k] = v

		# CUI.debug "limitRect", pos, defaults, limitRect

		for key in [
			"min_w"
			"max_w"
			"min_h"
			"max_h"
			"min_x"
			"max_x"
			"min_y"
			"max_y"
			]
			value = limitRect[key]
			if isUndef(value)
				continue

			assert(not isNaN(value), "#{getObjectClass(@)}.limitRect", "key #{key} in pos isNaN", pos: pos, defaults: defaults, limitRect: limitRect)

			skey = key.substring(4)
			mkey = key.substring(0,3)
			if key == "max_x"
				value -= pos.w
			if key == "max_y"
				value -= pos.h

			diff = pos[skey] - value
			if mkey == "min"
				if diff >= 0
					continue
			if mkey == "max"
				if diff <= 0
					continue

			if skey == "y" and "n" in pos.fix
				pos.h -= diff
				continue
			if skey == "x" and "w" in pos.fix
				pos.w -= diff
				continue

			# CUI.debug "correcting #{skey} by #{diff} from #{pos[skey]}"

			pos[skey]-=diff

			if skey == "h" and "s" in pos.fix
				# CUI.debug "FIX y"
				pos.y += diff
			if skey == "w" and "e" in pos.fix
				# CUI.debug "FIX x"
				pos.x += diff
			if skey == "x" and "e" in pos.fix
				# CUI.debug "FIX w"
				pos.w += diff
			if skey == "y" and "s" in pos.fix
				# CUI.debug "FIX h"
				pos.h += diff

		# CUI.debug "limitRect AFTER", pos, diff
		return pos


Draggable = CUI.Draggable