uniform mat4 gbufferModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform vec4 entityColor;
uniform vec3 shadowLightPosition;
uniform vec3 upPosition;
uniform vec3 fogColor;
uniform vec3 skyColor;

uniform float rainStrength;
uniform float far;

uniform int isEyeInWater;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;
uniform sampler2D lightmap;
uniform sampler2D texture;

const int noiseTextureResolution = 256;
const float sunPathRotation = -30.0;
const bool shadowHardwareFiltering = false;
const float shadowDistance = 128.0; //[64.0 96.0 128.0 160.0 192.0 224.0 256.0 288.0 320.0 352.0 384.0 416.0 448.0 480.0 512.0]
const int shadowMapResolution = 2048; //[512 1024 2048 4096 8192]

#define ENABLE_FOG
#define ENABLE_PCSS
#define ENABLE_COLORED_SHADOW
#define SHADOW_BRIGHTNESS 0.65 //[0.0 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define PCF_SAMPLE 16 //[8 16 32 64]
#define PCF_BLUR_RADIUS 1.0 //[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define PENUMBRA_SAMPLE 8 //[8 16]
#define PENUMBRA_RADIUS 1.5 //[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

#define clamp01(x) clamp(x, 0.0, 1.0)
#define max0(x) max(x, 0.0)
#define rot2d(rot) mat2(cos(rot), sin(rot), -sin(rot), cos(rot))

// https://github.com/jhk2/glsandbox/blob/master/kgl/samples/shadow/pcss.glsl
// http://developer.download.nvidia.com/whitepapers/2008/PCSS_Integration.pdf
const vec2 poisson[64] = vec2[64](
	vec2(-0.04117257, -0.1597612),
	vec2(0.06731031, -0.4353096),
	vec2(-0.206701, -0.4089882),
	vec2(0.1857469, -0.2327659),
	vec2(-0.2757695, -0.159873),
	vec2(-0.2301117, 0.1232693),
	vec2(0.05028719, 0.1034883),
	vec2(0.236303, 0.03379251),
	vec2(0.1467563, 0.364028),
	vec2(0.516759, 0.2052845),
	vec2(0.2962668, 0.2430771),
	vec2(0.3650614, -0.1689287),
	vec2(0.5764466, -0.07092822),
	vec2(-0.5563748, -0.4662297),
	vec2(-0.3765517, -0.5552908),
	vec2(-0.4642121, -0.157941),
	vec2(-0.2322291, -0.7013807),
	vec2(-0.05415121, -0.6379291),
	vec2(-0.7140947, -0.6341782),
	vec2(-0.4819134, -0.7250231),
	vec2(-0.7627537, -0.3445934),
	vec2(-0.7032605, -0.13733),
	vec2(0.8593938, 0.3171682),
	vec2(0.5223953, 0.5575764),
	vec2(0.7710021, 0.1543127),
	vec2(0.6919019, 0.4536686),
	vec2(0.3192437, 0.4512939),
	vec2(0.1861187, 0.595188),
	vec2(0.6516209, -0.3997115),
	vec2(0.8065675, -0.1330092),
	vec2(0.3163648, 0.7357415),
	vec2(0.5485036, 0.8288581),
	vec2(-0.2023022, -0.9551743),
	vec2(0.165668, -0.6428169),
	vec2(0.2866438, -0.5012833),
	vec2(-0.5582264, 0.2904861),
	vec2(-0.2522391, 0.401359),
	vec2(-0.428396, 0.1072979),
	vec2(-0.06261792, 0.3012581),
	vec2(0.08908027, -0.8632499),
	vec2(0.9636437, 0.05915006),
	vec2(0.8639213, -0.309005),
	vec2(-0.03422072, 0.6843638),
	vec2(-0.3734946, -0.8823979),
	vec2(-0.3939881, 0.6955767),
	vec2(-0.4499089, 0.4563405),
	vec2(0.07500362, 0.9114207),
	vec2(-0.9658601, -0.1423837),
	vec2(-0.7199838, 0.4981934),
	vec2(-0.8982374, 0.2422346),
	vec2(-0.8048639, 0.01885651),
	vec2(-0.8975322, 0.4377489),
	vec2(-0.7135055, 0.1895568),
	vec2(0.4507209, -0.3764598),
	vec2(-0.395958, -0.3309633),
	vec2(-0.6084799, 0.02532744),
	vec2(-0.2037191, 0.5817568),
	vec2(0.4493394, -0.6441184),
	vec2(0.3147424, -0.7852007),
	vec2(-0.5738106, 0.6372389),
	vec2(0.5161195, -0.8321754),
	vec2(0.6553722, -0.6201068),
	vec2(-0.2554315, 0.8326268),
	vec2(-0.5080366, 0.8539945)
);

float fogify(float x, float w){
	return w / (x * x + w);
}

vec3 calcSkyColor(vec3 pos){
	float horizon = dot(pos, normalize(upPosition));
	return mix(skyColor, fogColor, fogify(max0(horizon), 0.2));
}

vec3 vmMAD(mat4 matx, vec3 pos){
	return mat3(matx) * pos + matx[3].xyz;
}

vec2 poissonBlur(int i, float blurRadius){
	float blueNoise = texture2D(noisetex, gl_FragCoord.xy / noiseTextureResolution).r;
	return rot2d(blueNoise * 6.28318531) * poisson[i] * blurRadius;
}

float shadowPCF(sampler2D shadowTex, vec3 shadowPos, float blurRadius){
	float shadowMap = 0.0;
	for(int i = 0; i < PCF_SAMPLE; ++i){
		vec2 offsetPos = shadowPos.xy + poissonBlur(i, blurRadius);
		shadowMap += step(shadowPos.z, texture2D(shadowTex, offsetPos).r);
	}
		shadowMap /= PCF_SAMPLE;
	return shadowMap;
}

#ifdef ENABLE_PCSS
	float findBlocker(vec3 shadowPos){
		float blocker = 0.0, numBlocker = 0.0, penumbraRad = PENUMBRA_RADIUS * 0.01;
		for(int i = 0; i < PENUMBRA_SAMPLE; ++i){
			vec2 offsetPos = shadowPos.xy + poissonBlur(i, penumbraRad);
			float shadowDepth = texture2D(shadowtex1, offsetPos).r;
			
			if(shadowDepth < shadowPos.z){
				blocker += shadowDepth;
				numBlocker++;
			}
		}
			blocker /= numBlocker;
			blocker = (shadowPos.z - blocker) / blocker;
		return clamp01(blocker);
	}
#endif

#ifdef GBUFFERS_SKYBASIC
	uniform mat4 gbufferProjectionInverse;
	uniform float viewWidth;
	uniform float viewHeight;

	in float starData;
#endif

in vec2 lmCoord;
in vec2 texCoord;
in vec3 viewPos;
in vec3 worldPos;
in vec4 flatNormal;
in vec4 vertColor;

void main(){
	vec4 outColor = vec4(0.0, 0.0, 0.0, 1.0);

#ifdef GBUFFERS_SKYBASIC
	if(starData > 0.5){
		outColor.rgb = vertColor.rgb;
	} else {
		vec4 pos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0, 1.0);
			pos = gbufferProjectionInverse * pos;
		outColor.rgb = calcSkyColor(normalize(pos.xyz));
	}
#else
	outColor = texture2D(texture, texCoord) * vertColor;
#endif

#ifdef GBUFFERS_ENTITIES
	outColor.rgb = mix(outColor.rgb, entityColor.rgb, entityColor.a);
#endif

#ifdef GBUFFERS_BASIC
	outColor = vertColor;
#endif

#if !defined(GBUFFERS_BEACON_BEAM) && !defined(GBUFFERS_CLOUDS) && !defined(GBUFFERS_SKYTEXTURED) && !defined(GBUFFERS_SPIDEREYES) && !defined(GBUFFERS_SKYBASIC)
	vec3 shadowPos = vmMAD(shadowModelView, worldPos);
		shadowPos = vmMAD(shadowProjection, shadowPos);

	float distShadowP = mix(1.0, length(shadowPos.xy), 0.85);
		shadowPos.xy /= distShadowP;
		shadowPos.z *= 0.25;
		
	float lightVis = clamp01(dot(normalize(shadowLightPosition), normalize(upPosition)));
	float shadowResCheck = 0.0;
	switch(shadowMapResolution){
		case 1024: shadowResCheck = 2.0 / 1024.0; break;
		case 2048: shadowResCheck = 4.0 / 2048.0; break;
		case 4096: shadowResCheck = 6.0 / 4096.0; break;
		case 8192: shadowResCheck = 8.0 / 8192.0; break;
		default: shadowResCheck = 1.0 / 512.0; break;
	}
		shadowPos.z -= (distShadowP * distShadowP * shadowResCheck) / lightVis;
		shadowPos = shadowPos * 0.5 + 0.5;
	
	float blurRadius = PCF_BLUR_RADIUS / shadowMapResolution;
	#ifdef ENABLE_PCSS
		float blocker = findBlocker(shadowPos);
			blurRadius = max(blurRadius, blocker);
	#endif

	float shadowMap0 = shadowPCF(shadowtex0, shadowPos, blurRadius);
	float shadowMap1 = shadowPCF(shadowtex1, shadowPos, blurRadius);

	vec3 shadedLight = vec3(1.0);
	if(length(worldPos) < shadowDistance){
		#ifdef ENABLE_COLORED_SHADOW
			vec4 shadowMapCol = texture2D(shadowcolor0, shadowPos.xy);
			shadedLight = mix(shadedLight, shadowMapCol.rgb, pow(shadowMapCol.a, 0.5)) * (shadowMap1 - shadowMap0) + shadowMap0;
		#else
			shadedLight = vec3(shadowMap1 + shadowMap0) * 0.5;
		#endif
	}

	#ifndef GBUFFERS_TEXTURED
		if(!(flatNormal.a > 0.0)) shadedLight = shadedLight * clamp01(dot(normalize(shadowLightPosition), flatNormal.xyz)) * 2.0;
	#endif

		lightVis = texture2D(lightmap, vec2(0, 1)).r * lmCoord.y;
	float shadowBrightness = mix(SHADOW_BRIGHTNESS, 1.0, rainStrength);
	vec3 ambientLightmap = texture2D(lightmap, vec2(lmCoord.x * clamp01(1.0 - lightVis), lmCoord.y * shadowBrightness)).rgb;

		shadowBrightness += clamp01(1.0 - lightVis) * clamp01(1.0 - shadowBrightness);
		ambientLightmap += (shadedLight * clamp01(1.0 - shadowBrightness));
	outColor.rgb *= ambientLightmap;
#endif

#ifdef ENABLE_FOG
	#if !defined(GBUFFERS_SKYTEXTURED) && !defined(GBUFFERS_SKYBASIC)
		float fogDist = pow(clamp01(length(worldPos) / far), 5.0);
		
		#ifdef GBUFFERS_CLOUDS
			fogDist = fogDist * 0.7;
		#endif
		
		if(isEyeInWater == 1) fogDist = fogify(1.0 - fogDist, 0.5);
		outColor.rgb = mix(outColor.rgb, calcSkyColor(normalize(viewPos)), fogDist);
	#endif
#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = outColor;
}