#version 130

out vec2 texCoord;

void main(){
	vec4 pos = gl_ModelViewProjectionMatrix * gl_Vertex;
		pos.xy /= mix(1.0, length(pos.xy), 0.85);
		pos.z *= 0.25;
	gl_Position = pos;
	texCoord = gl_MultiTexCoord0.xy;
}
