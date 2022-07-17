if (typeof shinyjs !== 'undefined') { // protect against a golem problem

shinyjs.init = function(){
  firstEvent = null
  lastEvent = null
  lastMove = null
  lastCrossX = null
  lastCrossY = null
  point_radius = 5
  tick = 6
  tick2 = 2*tick+1
  is_hrm = true
  move_timeout = null
  move_timeout2 = null
  fill_range = 10 // conventional manometry
  fill_range_width = 2*fill_range
  $("#comment").keyup(function(e){
    Shiny.setInputValue("comment_changed", {value: e.keyCode}, {priority: "event"})
  })
}

clear_last_rubberband = function(context){
  if (!firstEvent || !lastEvent) return
  if (firstEvent.offsetX > lastEvent.offsetX){
    var fromX = lastEvent.offsetX - point_radius
    var width = (firstEvent.offsetX + point_radius) - fromX
  } else {
    fromX = firstEvent.offsetX - point_radius
    width = (lastEvent.offsetX + point_radius) - fromX
  }
  if (firstEvent.offsetY > lastEvent.offsetY) {
    var fromY = lastEvent.offsetY - point_radius
    var height = (firstEvent.offsetY + point_radius) - fromY
  } else {
    fromY = firstEvent.offsetY - point_radius
    height = (lastEvent.offsetY + point_radius) - fromY
  }
  context.clearRect(fromX, fromY, width, height)
}

draw_rubber = function(context, event){
  clear_last_rubberband(context)
  lastEvent = event
  if (!event.ctrlKey ) {
    const hor =
      (Math.abs(lastEvent.offsetX - firstEvent.offsetX) >
       Math.abs(lastEvent.offsetY - firstEvent.offsetY))
    if (hor){
      lastEvent.offsetY = firstEvent.offsetY
    } else {
      lastEvent.offsetX = firstEvent.offsetX
    }
  }
  draw_section(context, firstEvent.offsetX, firstEvent.offsetY,
               lastEvent.offsetX, lastEvent.offsetY)
}

draw_section = function(context, x1, y1, x2, y2){
  context.beginPath()
  context.strokeStyle = '#FFFFFF'
  context.lineWidth = 2
  context.moveTo(x1, y1)
  context.lineTo(x2, y2)
  context.stroke()
  draw_point(context, x1, y1)
  draw_point(context, x2, y2)
}

draw_point = function(context, x, y) {
  context.fillStyle = "#ffffff"
  context.beginPath()
  context.moveTo(x, y)
  context.arc(x, y, point_radius, 0, Math.PI * 2, false)
  context.fill()
}

draw_cross = function(context, x, y) {
  if (firstEvent) return

  clear_cross(context)
  context.beginPath()
  context.moveTo(x-tick, y)
  context.lineTo(x+tick, y)
  context.moveTo(x, y - tick)
  context.lineTo(x, y + tick)
  context.lineWidth = 2;
  context.strokeStyle = '#000000';
  context.stroke()
  lastCrossX = x
  lastCrossY = y
}

clear_cross = function(context) {
  if (firstEvent) return
  if (lastCrossX) {
    context.clearRect(lastCrossX - tick, lastCrossY-tick,
                       tick2, tick2)
  }
  lastCrossX = null
  lastCrossY = null
}

shinyjs.image_clicked = function (event) {
  var canvas = document.getElementById('canvas1')
  if (canvas === null) return
  if (!canvas.getContext)  return
  const context = canvas.getContext('2d')
  const e = event[0]
  if (firstEvent === null){
    context.clearRect(0, 0, canvas.width, canvas.height)
    draw_point(context, e.offsetX, e.OffsetY)
    firstEvent = e
  } else {
    draw_rubber(context, e)
    lastEvent = e
    var hor = true
    if (!e.ctrlKey) {
       hor = Math.abs(lastEvent.offsetX - firstEvent.offsetX) >
             Math.abs(lastEvent.offsetY - firstEvent.offsetY)
      if (hor){
        lastEvent.offsetY = firstEvent.offsetY
      } else {
        lastEvent.offsetX = firstEvent.offsetX
      }
    }
    Shiny.setInputValue("section",
      { x1: firstEvent.offsetX, y1: firstEvent.offsetY,
        x2: lastEvent.offsetX, y2: lastEvent.offsetY,
        user_drawn: true
      })
    lastCrossX = null
    lastCrossY = null
    firstEvent = null
    lastEvent= null
  }
}

move_timed_out = function(){
  Shiny.setInputValue("mouse_move",{ x: lastMove.offsetX, y: lastMove.offsetY})
  const canvas = document.getElementById('canvas1')
  if (canvas != null) {
    const context = canvas.getContext('2d')
    draw_cross(context, lastMove.offsetX, lastMove.offsetY)
  }
}

shinyjs.mouse_move = function (event) {
  const canvas = document.getElementById('canvas1')
  if (canvas === null) return
  lastMove = event[0]
  // Stop and restart readout timer
  if (move_timeout) clearTimeout(move_timeout)
  if (!firstEvent)
    move_timeout = setTimeout(move_timed_out, 50)
  const context = canvas.getContext('2d')
  if (firstEvent !== null){
    draw_rubber(context, lastMove)
  }
}

shinyjs.canvas_resize = function(size) {
  var canvas = document.getElementById('canvas1')
  if (canvas != null){
    canvas.setAttribute("width",  size[0])
    canvas.setAttribute("height", size[1])
  }
  canvas = document.getElementById('canvas2')
  if (canvas != null){
    canvas.setAttribute("width",  size[0])
    canvas.setAttribute("height", size[1])
  }
  const container = document.getElementById('image-container')
  container.style.height =  (size[1]) + "px"
  const mainimage = document.getElementById('mainimage')
  mainimage.style.height =  size[1] + "px"
  if (move_timeout) clearTimeout(move_timeout)
}

shinyjs.clear_all = function() {
  const canvas = document.getElementById('canvas1')
  if (canvas === null) return
  const context = canvas.getContext('2d')
  if (move_timeout) clearTimeout(move_timeout)
  context.clearRect(0, 0, canvas.width, canvas.height)
  firstEvent = null
  lastEvent = null
  // this will clear the image
  Shiny.setInputValue("section",
    { x1: null, y1: null, x2: null, y2: null, user_drawn: false})
}

shinyjs.draw_section = function(cd) {
  var canvas = document.getElementById('canvas1')
  if (canvas === null) return
  if (!canvas.getContext)  return
  const context = canvas.getContext('2d')
  shinyjs.clear_all()
  draw_section(context, cd[0], cd[1], cd[2], cd[3])
  Shiny.setInputValue("section",
    { x1: cd[0], y1:  cd[1], x2:  cd[2], y2:  cd[3], user_drawn: false})

}

// Conventional manometry
shinyjs.mouse_move2 = function (event) {
  const canvas = document.getElementById('canvas2')
  const context = canvas.getContext('2d')
  if (lastMove != null){
    context.clearRect(lastMove.offsetX-fill_range, 0,
                      fill_range_width, canvas.height)
  }
  if (move_timeout2) clearTimeout(move_timeout2)
  move_timeout2 = setTimeout(move_timed_out2, 100)

  lastMove = event[0]
  x = lastMove.offsetX

  context.fillStyle= 'rgba(225,225,225,0.4)'
  context.fillRect(x-fill_range, 0, fill_range_width, canvas.height)
  context.beginPath()
  context.moveTo(x, 0)
  context.lineTo(x, canvas.height)
  context.strokeStyle = 'rgba(70,70,70,0.8)';
  context.stroke()
}

move_timed_out2 = function(){
  Shiny.setInputValue("mouse_move2",{
    x: lastMove.offsetX,
    y: lastMove.offsetY,
    fill_range: fill_range
  })
}


}