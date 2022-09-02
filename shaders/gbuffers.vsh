uniform mat4 gbufferModelViewInverse;
attribute vec3 mc_Entity;

#ifdef GBUFFERS_SKYBASIC
out float starData;
#endif

out vec2 lmCoord;
out vec2 texCoord;
out vec3 viewPos;
out vec3 worldPos;
out vec4 flatNormal;
out vec4 vertColor;

void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	vertColor = gl_Color;

#ifdef GBUFFERS_SKYBASIC
	starData = float(vertColor.r == vertColor.g && vertColor.g == vertColor.b && vertColor.r > 0.0);
#endif

	viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	worldPos = mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;

	flatNormal.xyz = normalize(gl_NormalMatrix * gl_Normal);
	flatNormal.a = float(mc_Entity.x == 1);

	gl_Position = ftransform();
}