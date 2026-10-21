shader_type canvas_item;
uniform float fill : hint_range(0.0,1.0) = 1.0;
uniform vec4 liquid_color : source_color = vec4(0.65,0.08,0.10,1.0);
uniform float activity : hint_range(0.0,1.0) = 0.0;
void fragment() {
 vec2 p=UV*2.0-1.0;
 float radius=length(p);
 float edge=1.0-smoothstep(0.91,0.96,radius);
 float wave=activity>0.001 ? sin(UV.x*18.0+TIME*4.0)*0.008*activity : 0.0;
 float liquid=step(1.0-fill+wave,UV.y)*step(0.001,fill);
 float light=0.65+0.3*(1.0-UV.y);
 float reflection=pow(max(0.0,1.0-length((UV-vec2(0.32,0.27))*vec2(5.0,8.0))),2.0)*0.18;
 vec3 shade=mix(vec3(0.045,0.039,0.031),liquid_color.rgb*light,liquid)+vec3(reflection);
 COLOR=vec4(shade,edge);
}
