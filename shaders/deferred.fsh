#version 130
/* DRAWBUFFERS:4 */

uniform sampler2D colortex0;
in vec2 texcoord;

void main(){
	gl_FragData[0] = vec4(texture2D(colortex0, texcoord).rgb, 1.0);
}
