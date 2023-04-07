#if !defined(GBUFFERS_BASIC) && !defined(GBUFFERS_SKYBASIC)
	#ifdef GBUFFERS_ENTITIES
		uniform vec4 entityColor;
	#endif

	#define ENABLE_FOG
	#if !defined(GBUFFERS_CLOUDS) && !defined(GBUFFERS_SKYTEXTURED) && !defined(GBUFFERS_SPIDEREYES)
		const int noiseTextureResolution = 256;
		const float sunPathRotation = 0.0; //[-30.0 -20.0 -10.0 0.0 10.0 20.0 30.0]
		const bool shadowHardwareFiltering = false;
		const float shadowDistance = 128.0; //[64.0 96.0 128.0 160.0 192.0 224.0 256.0 288.0 320.0 352.0 384.0 416.0 448.0 480.0 512.0]
		const int shadowMapResolution = 2048; //[512 1024 2048 4096 8192]

		#define SHADOW_BRIGHTNESS 0.8 //[0.0 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
		#define PCF_SAMPLE 16 //[8 16 32 64]
		#define PCF_BLUR_RADIUS 1.0 //[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
		#define ENABLE_COLORED_SHADOW

		///////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////////////////////////////////////

		uniform mat4 gbufferModelView;
		uniform mat4 shadowProjection;
		uniform mat4 shadowModelView;

		uniform vec3 shadowLightPosition;
		uniform float rainStrength;

		uniform sampler2D shadowtex0;
		uniform sampler2D shadowtex1;
		uniform sampler2D shadowcolor0;
		uniform sampler2D noisetex;

		///////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////////////////////////////////////

		// https://github.com/jhk2/glsandbox/blob/master/kgl/samples/shadow/pcss.glsl
		const vec2 offsets[64] = vec2[64](
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

		#define rot2D(r) mat2(cos(r), sin(r), -sin(r), cos(r))
		float sPCF(sampler2D sTex, vec3 sSPos, float bRad){
			float sMap = 0.0;
			float bNoise = texture(noisetex, gl_FragCoord.xy / vec2(noiseTextureResolution)).r;
			for(int i = 0; i < PCF_SAMPLE; i++){
				sMap += step(sSPos.z, texture(sTex, sSPos.xy + (rot2D(bNoise * 6.28318531) * offsets[i] * bRad)).r);
			}
			return sMap / PCF_SAMPLE;
		}
		#undef rot2D
	#endif

	uniform sampler2D lightmap;
	uniform sampler2D tex;

	in vec4 N;
	in vec3 wPos;
	in vec2 uv0;
	in vec2 uv1;
#endif

in vec4 vColor;

#ifndef GBUFFERS_BASIC
	uniform vec3 upPosition;
	uniform vec3 fogColor;
	uniform vec3 skyColor;
	uniform float far;
	uniform int isEyeInWater;

	in vec3 vPos;
#endif

/* DRAWBUFFERS:0 */
void main(){
#ifdef GBUFFERS_BASIC
	gl_FragData[0] = vColor;
#else
	float zSky = clamp(dot(normalize(vPos), normalize(upPosition)), 0.0, 1.0);
	vec3 skyFog = mix(fogColor, skyColor, zSky);
#endif

#if !defined(GBUFFERS_BASIC) && !defined(GBUFFERS_SKYBASIC)
		vec4 albedo = texture(tex, uv0);
			albedo.rgb *= vColor.rgb;

	#ifdef GBUFFERS_ENTITIES
		albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
	#endif

	#if !defined(GBUFFERS_CLOUDS) && !defined(GBUFFERS_SKYTEXTURED) && !defined(GBUFFERS_SPIDEREYES)
		vec3 sLight = vec3(1.0);
		if(length(wPos) < shadowDistance){
			vec3 sWorld = vec3(shadowModelView * vec4(wPos, 1.0));
			vec3 sClip = vec3(shadowProjection * vec4(sWorld, 1.0));
				sClip.z *= 0.25;

			float sBias = 0.0;
			switch(shadowMapResolution){
				case 2048: sBias = 0.0029296875; break;
				case 4096: sBias = 0.001953125; break;
				case 8192: sBias = 0.001220703125; break;
				default: sBias = 0.00390625;
			}

			float dist = mix(1.0, length(sClip.xy), 0.85);
				sClip.xy /= dist;
				sClip.z -= (dist * dist * sBias) / clamp(dot(normalize(shadowLightPosition), normalize(upPosition)), 0.0, 1.0);

			vec3 sSPos = sClip.xyz * 0.5 + 0.5;

			float bRad = PCF_BLUR_RADIUS / shadowMapResolution;
			float sMap0 = sPCF(shadowtex0, sSPos, bRad);
			float sMap1 = sPCF(shadowtex1, sSPos, bRad);

			#ifdef ENABLE_COLORED_SHADOW
				vec4 sMapC = texture2D(shadowcolor0, sSPos.xy);
				sLight = mix(sLight, sMapC.rgb, sqrt(sMapC.a * 2.0)) * (sMap1 - sMap0);
				sLight += sMap0;
			#else
				sLight = vec3(sMap1 + sMap0) * 0.5;
			#endif
		}

		#ifndef GBUFFERS_TEXTURED
			if(N.a < 1.0){
				sLight = sLight * clamp(dot(normalize(shadowLightPosition), N.xyz), 0.0, 1.0) * 2.0;
			}
		#endif

		float sBright = mix(SHADOW_BRIGHTNESS, 1.0, rainStrength);
		float lVis = texture2D(lightmap, vec2(0.0, uv1.y)).r;
		vec3 lMap = texture2D(lightmap, vec2(uv1.x * (1.0 - lVis), uv1.y * sBright)).rgb;
			lMap *= vColor.a;
			sBright += (1.0 - lVis) * (1.0 - sBright);
			lMap += sLight * (1.0 - sBright);
		albedo.rgb *= lMap;
	#endif

	#ifdef ENABLE_FOG
		#ifndef GBUFFERS_SKYTEXTURED
			float farDist = far;
			#ifdef GBUFFERS_CLOUDS
				farDist = farDist * 2.0;
			#endif
			float fogDist = clamp(length(wPos) / farDist, 0.0, 1.0);
				fogDist = (isEyeInWater == 1) ? fogDist : pow(fogDist, 3.0);
			albedo.rgb = mix(albedo.rgb, skyFog, fogDist);
		#endif
	#endif

	gl_FragData[0] = albedo;
#endif

#ifdef GBUFFERS_SKYBASIC
	gl_FragData[0] = vec4(skyFog, 1.0);
#endif
}