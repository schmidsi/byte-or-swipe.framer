# Import file "byte-or-swipe" (sizes and positions are scaled 1:2)
sketch = Framer.Importer.load("imported/byte-or-swipe@2x")

state =
	percanvas: []
	default:
		liked: false
	
	details: false
	faded: false
	swiping: false

Framer.Defaults.Animation =
	curve: "spring(713, 45, 0)"

NUMBER_OF_CANVASES = 3

canvasList = []

for canvas in [1..NUMBER_OF_CANVASES]
	canvasNumber = ("00" + canvas).slice(-2)
	canvasList.push(sketch["canvas#{ canvasNumber }"])

activeCanvasIndex = 0

# fix fixed elements
sketch.metafix.superLayer = Framer.Device.screen

# set background color
Framer.Device.screen.backgroundColor = 'black'

# define states
#########################################################
sketch.metafix.states.add
	faded:
		opacity: 0
	unfaded:
		opacity: 1

for canvas in [1..NUMBER_OF_CANVASES]
	canvasNumber = ("00" + canvas).slice(-2)
	
	state.percanvas[canvas-1] = state.default
	
	sketch["canvas#{ canvasNumber }"].states.add
		active:
			x: 0
			scale: 1
			visible: true
		outleft:
			x: -750
		outright:
			x: 750
		scaledout:
			x: 0
			scale: 0

	sketch["iconactive#{ canvasNumber }"].states.add
		shown:
			visible: true
		hidden:
			visible: false
	
	sketch["iconinactive#{ canvasNumber }"].states.add
		shown:
			visible: true
		hidden:
			visible: false

	sketch["details#{ canvasNumber }"].states.add
		shown:
			y: 172
		hidden:
			y: sketch["details#{ canvasNumber }"].y
		faded:
			opacity: 0
		unfaded:
			opacity: 1
	
	sketch["overlay#{ canvasNumber }"].states.add
		faded:
			opacity: 0
		unfaded:
			opacity: 1
	
	sketch["infos#{ canvasNumber }"].states.add
		shown:
			visible: true
		hidden:
			visible: false
	
	sketch["image#{ canvasNumber }"].states.add
		blurred:
			opacity: 0.5
			blur: 10
		normal:
			opacity: 1
			blur: 0

# setup states
#########################################################

for canvas in [1..NUMBER_OF_CANVASES]
	canvasNumber = ("00" + canvas).slice(-2)
	
	sketch["canvas#{ canvasNumber }"].visible = true
	sketch["iconactive#{ canvasNumber }"].states.switch('hidden')
	sketch["infos#{ canvasNumber }"].states.switch('hidden')
	
	if canvas > 1
		sketch["canvas#{ canvasNumber }"].states.switchInstant('scaledout')

# events
#########################################################

# dragging
for canvas in canvasList
	canvas.draggable.enabled = true
	canvas.draggable.horizontal = true
	canvas.draggable.vertical = false
	canvas.draggable.constraints =
		x: -750
		width: 750 * 3
	
	canvas.on Events.Move, ->
		activeCanvas = canvasList[activeCanvasIndex]
		nextCanvas = canvasList[(activeCanvasIndex + 1) % NUMBER_OF_CANVASES]
		
		if state.details
			activeCanvas.x = 0
		else
			state.swiping = true
		
		nextCanvas.states.switchInstant('scaledout')
		nextCanvas.scale = Math.min(Math.abs(activeCanvas.draggable.offset.x) / 750, 1)
		
	canvas.on Events.DragEnd, ->
		activeCanvas = canvasList[activeCanvasIndex]
		nextCanvas = canvasList[(activeCanvasIndex + 1) % NUMBER_OF_CANVASES]
		
		state.swiping = false
		
		if activeCanvas.draggable.offset.x > (750/3) or activeCanvas.draggable.offset.x < -(750/3)
			activeCanvas.states.switch('outright')
			nextCanvas.states.switch('active')
			nextCanvas.bringToFront()
			activeCanvasIndex = (activeCanvasIndex + 1) % NUMBER_OF_CANVASES
			
			if activeCanvas.draggable.offset.x > (750/3)
				activeCanvas.states.switch('outright')
			else
				activeCanvas.states.switch('outleft')
		else
			activeCanvas.states.switch('active')
			nextCanvas.states.switch('scaledout')

canvasList[activeCanvasIndex].bringToFront()


for canvas in [1..NUMBER_OF_CANVASES]
	canvasNumber = ("00" + canvas).slice(-2)
	
	# favorite
	sketch["fav#{ canvasNumber }"].on Events.Click, (event, layer) ->
		canvasNumber = layer.name.slice(-2)
		canvasIndex = parseInt(canvasNumber, 10)-1
		
		if state.percanvas[canvasIndex].liked
			sketch["iconactive#{ canvasNumber }"].states.switch('hidden')
			sketch["iconinactive#{ canvasNumber }"].states.switch('shown')
		else
			sketch["iconactive#{ canvasNumber }"].states.switch('shown')
			sketch["iconinactive#{ canvasNumber }"].states.switch('hidden')
				
		state.percanvas[canvasIndex].liked = not state.percanvas[canvasIndex].liked
	
	# show details
	sketch["title#{ canvasNumber }"].on Events.Click, (event, layer) ->
		canvasNumber = layer.name.slice(-2)
		
		if state.details
			sketch["details#{ canvasNumber }"].states.switch('hidden')
			sketch["image#{ canvasNumber }"].states.switch('normal')
		else
			sketch["details#{ canvasNumber }"].states.switch('shown')
			sketch["infos#{ canvasNumber }"].states.switch('shown')
			sketch["image#{ canvasNumber }"].states.switch('blurred')
		
		state.details = not state.details
	
	# - wait for hiding the details after animation is finished:
	sketch["details#{ canvasNumber }"].on Events.AnimationEnd, (event, layer) ->
		canvasNumber = layer.name.slice(-2)
		
		if not state.details
			sketch["infos#{ canvasNumber }"].states.switch('hidden')
	
	# fade all on tab
	sketch["image#{ canvasNumber }"].on Events.Click, (event, layer) ->
		# abort if details are shown
		if state.details or state.swiping
			return false
		
		if state.faded
			sketch.metafix.states.switch('unfaded')
		else
			sketch.metafix.states.switch('faded')
									
		for canvas in [1..NUMBER_OF_CANVASES]
			canvasNumber = ("00" + canvas).slice(-2)
			
			if state.faded
				sketch["overlay#{ canvasNumber }"].states.switch('unfaded')
				sketch["details#{ canvasNumber }"].states.switch('unfaded')
			else
				sketch["overlay#{ canvasNumber }"].states.switch('faded')
				sketch["details#{ canvasNumber }"].states.switch('faded')
		
		state.faded = not state.faded