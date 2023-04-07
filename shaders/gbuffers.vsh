#if !defined(GBUFFERS_BASIC) && !defined(GBUFFERS_SKYBASIC)
	uniform mat4 gbufferModelViewInverse;
	attribute vec3 mc_Entity;

	out vec4 N;
	out vec3 wPos;
	out vec2 uv0;
	out vec2 uv1;
#endif

out vec4 vColor;

#ifndef GBUFFERS_BASIC
	out vec3 vPos;
#endif

void main(){
#ifndef GBUFFERS_BASIC
	vPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
#endif

	vColor = gl_Color;

#if !defined(GBUFFERS_BASIC) && !defined(GBUFFERS_SKYBASIC)
	uv0 = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	uv1  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	wPos = vec3(gbufferModelViewInverse * vec4(vPos, 1.0));

	N.xyz = normalize(gl_NormalMatrix * gl_Normal);
	N.a = (mc_Entity.x == 1) ? 1.0 : 0.0;
#endif
	gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}