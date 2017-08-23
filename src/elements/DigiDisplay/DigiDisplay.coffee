###
 * coffeescript-ui - Coffeescript User Interface System (CUI)
 * Copyright (c) 2013 - 2016 Programmfabrik GmbH
 * MIT Licence
 * https://github.com/programmfabrik/coffeescript-ui, http://www.coffeescript-ui.org
###

class CUI.DigiDisplay extends CUI.DOM

	constructor: (@opts={}) ->
		super(@opts)
		@__digitsMap = []
		@createMarkup()
		@registerDOMElement(@__displayDiv)

	initOpts: ->
		super()
		@addOpts
			digits:
				mandatory: true
				check: Array

	display: (str) ->
		for c, idx in str.split("")
			if idx == @_digits.length
				break

			info = @__digitsMap[idx]

			if not info
				continue

			if info.map.hasOwnProperty(c)
				_idx = info.map[c]
			else
				_idx = 0

			fc = info.first_div

			if not info.height
				info.height = fc.outerHeight()
			CUI.DOM.setStyleOne(fc, "marginTop", "-"+(_idx*info.height)+"px")
			fc.setAttribute("c", c)
			fc.setAttribute("idx", _idx)
		@

	createMarkup: ->
		@__displayDiv = $div("cui-digi-display")

		for digit, digit_idx in @_digits
			if digit.static
				CUI.DOM.append(@__displayDiv, container = $div("cui-digi-display-static cui-digi-display-#{digit_idx}"))
				CUI.DOM.append(container, $text(digit.static)).addClass(digit.class)
				if digit.attr
					container.getAttribute(digit.attr)
				continue
			digit.__regexp = new RegExp(digit.mask)
			CUI.DOM.append(@__displayDiv, container = $div("cui-digi-display-container cui-digi-display-#{digit_idx}"))
			container.addClass(digit.class)
			if digit.attr
				container.getAttribute(digit.attr)

			@__digitsMap[digit_idx] = map: (map = {})

			# for the "unknown character
			CUI.DOM.append(container, fc = $div("cui-digi-display-digit").html("&nbsp;"))
			@__digitsMap[digit_idx].first_div = fc
			idx = 1
			matched = false
			for i in [32..128]
				if digit.__regexp.exec(c = String.fromCharCode(i))
					if i == 32
						CUI.DOM.append(container, $div("cui-digi-display-digit").html("&nbsp;"))
					else
						CUI.DOM.append(container, $div("cui-digi-display-digit").text(c))
					map[c] = idx
					idx++
					matched = true

			assert(matched, "DigiDisplay.createMarkup", "Digit #{digit_idx} not matched against the regexp. ASCII range 32-128 is allowed.", digit: digit)

			# CUI.debug "created markup with map", map
		@__displayDiv
