#version 130
out vec2 uv0;

void main(){
	uv0 = gl_MultiTexCoord0.xy;
	gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
	gl_Position.xy /= mix(1.0, length(gl_Position.xy), 0.85);
	gl_Position.z *= 0.25;
}