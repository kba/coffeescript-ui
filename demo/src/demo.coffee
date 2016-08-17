class Demo extends DOM

	display: ->
		"#{@__cls}.display: needs implementation."

	getRootCls: ->
		"ez-demo-#{toDash(@__cls)}"

	setConsole: (console) ->
		assert(console instanceof DemoConsole, "Demo.setConsole", "console needs to be instance of DemoConsole.")
		@__console = console

	log: (txt...) ->
		@__console.log(txt.join(" "))

	logTxt: (txt...) ->
		@log(toHtml(txt.join(" ")))

	undisplay: ->

	getBlindText: (repeat=1) ->
		r = """Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. Donec pede justo, fringilla vel, aliquet nec, vulputate eget, arcu. In enim justo, rhoncus ut, imperdiet a, venenatis vitae, justo. Nullam dictum felis eu pede mollis pretium. Integer tincidunt. Cras dapibus. Vivamus elementum semper nisi. Aenean vulputate eleifend tellus. """
		rs = []
		for i in [0...repeat]
			rs.push(r)
		rs.join(" ")

	getGroup: ->
		"Base"

	getName: ->
		s = getObjectClass(@)
		if s.endsWith("Demo")
			s.substring(0, s.length-4)
		else
			s

	@dividerLabel: (txt) ->
		new Label
			class: "cui-demo-divider-label"
			text: txt


Demo.demos = []

Demo.register = (demo) ->
	assert(demo instanceof Demo, "Demo.register", "demo must be instanceof Demo", demo: demo)
	Demo.demos.push(demo)

class DemoConsole extends DOM
	readOpts: ->
		super()
		@__logDiv = $div("cui-demo-console-log")[0]

	render: ->
		pane = new Pane
			top:
				content: new PaneHeader
					left:
						content: [
							new Button
								icon: "east"
								onClick: =>
									@__getPaneFlexHandle().close()
						,
							new Label(text: "Console")
						]
					right:
						content:
							icon: "trash"
							onClick: =>
								@__logDiv.innerHTML = ""

			center:
				content: @__logDiv

		@registerDOMElement(pane.DOM)
		pane

	__getPaneFlexHandle: ->
		DOM.data(@DOM.closest("[flex-handled-pane]")[0], "flexHandle")


	log: (txt) ->
		@__logDiv.appendChild($div().html(txt)[0])
		@__logDiv.scrollTop = @__logDiv.scrollHeight

class RunDemo extends Element
	constructor: (@opts={}) ->
		super(@opts)
		@demos = []
		@__console = new DemoConsole()
		@registerDemos()

		Events.listen
			type: "hashchange"
			node: window
			call: (ev) =>
				@displayDemo()

		@root = new Template
			name: "demo-root"
			map:
				body: true

		groups = ["Core", "Base", "Extra", "Demo", "Test"].reverse()

		@menuBtn = new Button
			class: "cui-demo-menu-button"
			menu:
				active_item_idx: null
				items: =>
					items = []
					demos = @demos.slice(0)

					demos.sort (a, b) ->

						a_group_id = 1000-(idxInArray(a.getGroup(), groups)+1)
						b_group_id = 1000-(idxInArray(b.getGroup(), groups)+1)

						compareIndex(a_group_id+"_"+a.getName(), b_group_id+"_"+b.getName())

					old_group = null

					for demo in demos
						demo.getGroup()
						if old_group != demo.getGroup()
							old_group = demo.getGroup()
							items.push(label: old_group)

						group_sort = (1000-(idxInArray(demo.getGroup(), groups)+1))+""

						do (demo) =>
							items.push
								active: demo == @current_demo
								# text: demo.getGroup()+" - "+demo.getName()
								text: demo.getName()
								_demo: demo
								onClick: =>
									document.location.hash = "##{demo.getName()}"
					items

			icon: new Icon
				icon: "menu"
			icon_right: false

		@themeSwitch = new Button
			class: "theme-switch"
			text: "Theme"
			menu:
				onClick: (ev, btn, item) ->
					window.localStorage.setItem("theme", item.value)
					document.location.reload()

					# FIXME: once "ng" is finished, we can remove the reload
					# CUI.loadTheme(item.value)
					# .done =>
					# 	window.localStorage.setItem("theme", item.value)

				active_item_idx: null
				items: ->
					theme_items = []
					for theme in CUI.getThemeNames()
						theme_items.push
							text: theme
							value: theme
							active: theme == CUI.getActiveTheme().getName()
					theme_items

		@menu_title_label = new Label
			class: "cui-demo-title"
			text: "CUI"

		@menu_sub_title_label = new Label
			class: "cui-demo-sub-title"
			text: ""

		@center_layout = new HorizontalLayout
			absolute: true
			center:
				class: "cui-demo-pane-center"
				content:
					new EmptyLabel
						centered: true
						text: "Choose a demo."
			right:
				class: "cui-demo-pane-right"
				content:
					@__console.render()
				flexHandle:
					label:
						text: "Console"
					hidden: false
					closed: false



		@main_menu_pane = new VerticalLayout
			class: "cui-root-layout"
			top:
				content:
					[
						new PaneHeader
							class: "cui-demo-header"
							left:
								content:
									[
										@menuBtn
										@menu_title_label
										@menu_sub_title_label
									]
							right:
								content:
										[
											@themeSwitch
										]
					]
			center:
				content: @center_layout

		@root.DOM.prependTo(document.body)
		@root.append( @main_menu_pane )

		CUI.loadHTMLFile("demo/easydbui_demo.html")
		.done =>
			@displayDemo()

	displayDemo: ->
		demo_name = document.location.hash.split("#")[1]

		demo = null
		for _demo in @demos
			if _demo.getName() == demo_name
				demo = _demo
				break

		if not demo or demo == @current_demo
			return

		bd = @main_menu_pane.center()
		#bd = @root.map.body.empty()

		if @current_demo
			bd.removeClass(@current_demo.getRootCls())
			@current_demo.undisplay()

		txt = "Demo.displayDemo #{demo_name}"
		console.time(txt)
		console.time("Wall:"+txt)
		@setTitle(demo)
		dfr = new CUI.Deferred()

		demo_content = demo.display()
		if not $(demo_content).hasClass("cui-pane")
			demo_content = new Pane
				center:
					content:
						demo_content
			.DOM
		@center_layout.replace( demo_content, "center" )
		console.timeEnd(txt)
		window.block_end_wall_time = 0
		end_wall_time = ->
			if window.block_end_wall_time
				CUI.setTimeout(end_wall_time, 0)
			else
				CUI.setTimeout ->
					console.timeEnd("Wall:"+txt)
				,
					0

		CUI.setTimeout(end_wall_time, 0)

		#@root.append(, "body").addClass(demo.getRootCls())
		# @root.triggerDOMInsert()

		@current_demo = demo
		@


	setTitle: (demo) ->
		@menu_sub_title_label.setText(demo.getName())

	registerDemos: ->
		@demos.splice(0)
		for demo in Demo.demos
			demo.setConsole(@__console)
			@demos.push(demo)
		@

# helps layouting examples, left column the example description, right column the example
class DemoTable
	constructor: (css_class="")->
		@table = $table("cui-demo-table "+css_class)
		@example_counter = 0

	addDivider: (text) ->

		td = $td("", colspan: 3)
		td.append(Demo.dividerLabel(text).DOM)
		@table.append($tr("cui-demo-divider").append(td))


	# Adds an example row
	#
	# @param [String] description
	# @param [Element] example
	# @param [Element] buttons or other controls for controlling the example
	addExample: (description, div, controls=null) ->
		@example_counter+=1
		label = new Label
			text: @example_counter+". "+description
			multiline: true

		row_elements = [label,div]
		if controls
			row_elements.push(controls)
		@table.append($tr_one_row( row_elements ))

	addRow: ->
		td = $td("", colspan: 3)
		td.append.apply(td, arguments)
		@table.append($tr("cui-demo-full-row").append(td))



CUI.ready ->
	CUI.debug "this:", @
	for k in ["light", "dark", "ng"]
		CUI.registerTheme(k, CUI.pathToScript+"/demo/css/cui_demo_#{k}.css")

	CUI.loadTheme(window.localStorage.getItem("theme") or "light")

	new RunDemo()

Object.values = (obj) =>
	Object.keys(obj).map((key) => obj[key])
