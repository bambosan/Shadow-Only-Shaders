#version 130

#define SHADOW_DIST_FACTOR 0.85 //[0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95]

out vec2 texCoord;

void main(){
	vec4 pos = gl_ModelViewProjectionMatrix * gl_Vertex;
		pos.xy /= mix(1.0, length(pos.xy), SHADOW_DIST_FACTOR);
		pos.z *= 0.25;
	gl_Position = pos;
	texCoord = gl_MultiTexCoord0.xy;
}
