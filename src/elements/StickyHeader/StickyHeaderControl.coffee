###
 * coffeescript-ui - Coffeescript User Interface System (CUI)
 * Copyright (c) 2013 - 2016 Programmfabrik GmbH
 * MIT Licence
 * https://github.com/programmfabrik/coffeescript-ui, http://www.coffeescript-ui.org
###

class CUI.StickyHeaderControl extends CUI.Element
	constructor: (@opts={}) ->
		super(@opts)

		# destroy old instances, in case we are re-initialized
		# on an .empty()ied element
		DOM.data(@_element, "stickyHeaderControl")?.destroy()

		DOM.data(@_element, "stickyHeaderControl", @)

		@__control = $div("cui-sticky-header-control")

		Events.listen
			instance: @
			type: "viewport-resize"
			node: @_element
			call: =>
				@__positionControl()

		@__positionControl()

		@_element.append(@__control)

		@headers = []
		@newStickyHeaders = []
		@__hiddenHeaders = []
		@__positioned = false

		Events.listen
			node: @_element
			type: "scroll"
			instance: @
			call: (ev) =>
				# console.time "scroll"
				@position()
				# console.timeEnd "scroll"
				return

	initOpts: ->
		super()
		@addOpts
			element:
				mandatory: true
				check: (v) ->
					isElement(v)

	__positionControl: ->
		dim = CUI.DOM.getDimensions(@_element)
		CUI.DOM.setStyle @__control,
			left: dim.clientBoundingRect.left
			top: dim.clientBoundingRect.top

		CUI.DOM.setDimension(@__control, "marginBoxWidth", dim.clientWidth)
		# console.error "__positionControl", @_element, @__control
		return

	isInDOM: ->
		@__control and DOM.isInDOM(@__control)

	addStickyHeader: (stickyHeader) ->
		assert(not @__positioned or DOM.isInDOM(@__control), "#{@__cls}.addStickyHeader", "StickyHeaderControl is not in DOM tree anymore. Cannot add a new StickyHeader.")

		assert(stickyHeader instanceof StickyHeader, "#{@__cls}.addStickyHeader", "Needs to be instance of StickyHeader but is #{getObjectClass(stickyHeader)}", stickyHeader: stickyHeader)
		@newStickyHeaders.push(stickyHeader)

	initNewStickyHeaders: ->
		measure_headers = []
		for nsh in @newStickyHeaders
			dom = nsh.DOM

			header =
				stickyHeader: nsh
				level: nsh.getLevel()
				node: dom.cloneNode(true)

			@headers.push(header)

			measure_headers.push(header)
			header.node.style.visiblity = "hidden"
			@__control.prepend(header.node)

		@newStickyHeaders.splice(0)

		for header in measure_headers
			header.dimInControl = DOM.getDimensions(header.node)
			@__control.removeChild(header.node)
			header.node.style.visiblity = ""
		@

	destroy: ->
		# CUI.warn "destroying sticky header control"
		DOM.removeData(@_element, "stickyHeaderControl")
		Events.ignore
			instance: @

		@__control.remove()
		@__headers = null
		@newStickyHeaders = null

	position: ->
		if not @isInDOM()
			return

		@__positioned = true
		@initNewStickyHeaders()
		# make sure the control is at the end
		@_element.append(@__control)

		scrollTop = @_element.scrollTop
		slots = []
		extraTop = 0
		for header, idx in @headers
			extraTop = 0
			for i in [0...header.level] by 1
				slot = slots[i]
				if slot == null
					break
				extraTop += slots[i].dimInControl.marginBoxHeight

			if header.stickyHeader.DOM.offsetTop < scrollTop + extraTop + header.dimInControl.marginTop
				slots[header.level] = header
				for i in [header.level+1...slots.length] by 1
					slots[i] = null
			else
				next_header = header
				top_space = 0
				for slot in slots
					if slot == null
						break
					top_space += slot.dimInControl.marginBoxHeight
				break

		if next_header
			cut = next_header.stickyHeader.DOM.offsetTop - scrollTop - top_space
			cut = cut - next_header.dimInControl.marginTop
			# console.debug cut, next_header.stickyHeader.DOM[0], next_header.stickyHeader.DOM[0].offsetTop, scrollTop, top_space
		else
			cut = 0

		for hiddenHeader in @__hiddenHeaders
			hiddenHeader.style.visibility = ""

		@__hiddenHeaders.splice(0)

		@__control.empty()

		top = 0
		for slot, idx in slots
			if slot == null
				break

			@__control.prepend(slot.node)

			if cut < 0 and slot.level == next_header.level
				top += cut

			hideHeader = slot.stickyHeader.DOM
			hideHeader.style.visibility = "hidden"

			@__hiddenHeaders.push(hideHeader)

			slot.node.style.top = top+"px"
			top += slot.dimInControl.marginBoxHeight

		@__control.css
			height: top

		@
