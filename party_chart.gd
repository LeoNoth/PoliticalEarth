extends Control

var segments: Array = [40,30,20,10]
const COLORS: Array[Color] = [Color("#7da6c7"),Color("#d9ab65"),Color("#91b78b"),Color("#bc7f8a")]

func _draw() -> void:
    var center: Vector2 = size * 0.5
    var radius: float = minf(size.x,size.y) * 0.46
    var total: float = 0.0
    for number in segments:
        total += maxf(0.0,float(number))
    if total <= 0.0:
        return
    var angle: float = -PI * 0.5
    for i in range(mini(segments.size(),COLORS.size())):
        var percent: float = maxf(0.0,float(segments[i])) / total
        var arc_size: float = TAU * percent
        var steps: int = maxi(3,int(ceil(arc_size*22.0)))
        for k in range(steps):
            var a: float = angle+arc_size*float(k)/float(steps)
            var b: float = angle+arc_size*float(k+1)/float(steps)
            draw_colored_polygon(PackedVector2Array([center,center+Vector2(cos(a),sin(a))*radius,center+Vector2(cos(b),sin(b))*radius]),COLORS[i])
        if percent >= 0.075:
            var midpoint: float = angle + arc_size*0.5
            var spot: Vector2 = center + Vector2(cos(midpoint),sin(midpoint)) * radius * 0.72
            var label_text: String = "%d%%" % int(round(percent*100.0))
            var font: Font = ThemeDB.fallback_font
            var fontsize: int = 17
            var label_width: float = font.get_string_size(label_text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize).x
            draw_string(font,spot+Vector2(-label_width*0.5,fontsize*0.35),label_text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize,Color("#18232c"))
        angle += arc_size
    draw_arc(center,radius,0.0,TAU,80,Color("#e3cb9f"),2.0,true)

