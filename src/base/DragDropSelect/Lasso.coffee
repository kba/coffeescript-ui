globalDrag = null

class CUI.Lasso extends CUI.Draggable
	@cls = "lasso"

	initOpts: ->
		super()
		@addOpts
			filter:
				check: String

			selected:
				default: (ev, info) ->
					alert("You lassoed #{info.elements.length} elements.")
				check: Function

			# only lasso rectangle cuts with this
			lasso_filter:
				check: String

			lassoClass:
				default: "cui-lasso"
				check: String

		@removeOpt("helper")

	readOpts: ->
		super()
		@_helper = null

	lasso_cls: "cui-drag-drop-select-lasso-element-in-lasso"

	init: ->
		super()
		# @makeElementRelative @element
		@element.addClass("cui-lasso-area")
		# assert @element.css("position") in ["relative","absolute","fixed"], "Lasso.init", "Element needs to be positioned (relative, absolute, fixed)", element: @element
		@position = null

	start_drag: (ev, $target, diff) ->
		if not CUI.DOM.isInDOM(@element[0])
			throw("DragDropSelect: Creating lasso failed, element is not in DOM.")

		globalDrag.lasso = $div(@_lassoClass+" cui-debug-node-copyable")
		# CUI.debug "create lasso", @_lassoClass
		#
		globalDrag.lasso.appendTo(@element)

	do_drag: (ev, $target, diff) ->
		# CUI.debug "Lasso do drag", globalDrag.start, globalDrag.$source[0] == @element[0], diff, @scroll?.top, @element[0].scrollTop
		set_css =  {}
		if diff.x <= 0
			set_css.left = globalDrag.start.left + diff.x
			set_css.width = -diff.x
			over = -set_css.left
			if over > 0
				set_css.width -= over
				set_css.left = 0
		else
			set_css.left = globalDrag.start.left
			set_css.width = diff.x
			over = set_css.left + set_css.width - @element[0].scrollWidth
			if over > 0
				set_css.width -= over

		if diff.y <= 0
			set_css.top = globalDrag.start.top + diff.y
			set_css.height = -diff.y
			over = -set_css.top
			if over > 0
				set_css.height -= over
				set_css.top = 0
		else
			set_css.top = globalDrag.start.top
			set_css.height = diff.y
			over = set_css.top + set_css.height - @element[0].scrollHeight
			if over > 0
				set_css.height -= over

		@resetLassoedElements()
		for el in @get_lassoed_elements()
			el.classList.add(@lasso_cls)

		# set_css.top += @position.top
		# set_css.left += @position.left

		globalDrag.lasso.css(set_css)

	resetLassoedElements: ->
		for el in DOM.matchSelector(@element, "."+@lasso_cls)
			el.classList.remove(@lasso_cls)
		@

	get_lassoed_elements: ->
		get_dim = (el) ->
			dim = el.getBoundingClientRect()
			dim

		do_overlap = (dims1, dims2) ->
			x1 = dims1.left
			y1 = dims1.top
			w1 = dims1.width
			h1 = dims1.height
			x2 = dims2.left
			y2 = dims2.top
			w2 = dims2.width
			h2 = dims2.height
			!(y2 + h2 <= y1 || y1 + h1 <= y2 || x2 + w2 <= x1 || x1 + w1 <= x2)

		globalDrag.lasso_dim = get_dim(globalDrag.lasso)
		lassoed = []
		if @_lasso_filter
			for el in CUI.DOM.matchSelector(globalDrag.$source, @_lasso_filter)
				if not do_overlap(globalDrag.lasso_dim, get_dim(el))
					continue
				# find lasso filtered
				if @_filter
					lassoed_el = CUI.DOM.closest(el, @_filter, globalDrag.$source)
				else
					parents = CUI.DOM.parentsUntil(el, globalDrag.$source)
					lassoed_el = parents[parents.length-2]

				if lassoed_el
					lassoed.push(lassoed_el)
		else if @_filter
			for el in CUI.DOM.matchSelector(globalDrag.$source, @_filter)
				if do_overlap(globalDrag.lasso_dim, get_dim(el))
					lassoed.push(el)
		else
			for el in globalDrag.$source.children
				if do_overlap(globalDrag.lasso_dim, get_dim(el))
					lassoed.push(el)
		lassoed

	end_drag: (ev) ->
		if ev.getType() == "mouseup"
			globalDrag.elements = @get_lassoed_elements()
			ret = @_selected(ev, globalDrag)
			if isPromise(ret)
				ret.always =>
					@resetLassoedElements()
			else
				@resetLassoedElements()
		else
			@resetLassoedElements()
		globalDrag.lasso.remove()


Lasso = CUI.Lasso