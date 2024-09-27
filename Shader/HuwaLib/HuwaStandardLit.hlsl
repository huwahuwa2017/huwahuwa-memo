// Ver3 2024-09-27 20:53

/*
RewriteStandardShader(MediumQuality)Çå≥Ç…çÏê¨

half nv = saturate(dot(wNormal, wViewDir));
Pow4(1.0 - nv)
Å´
roughness = max(roughness, 0.002);
half nv = abs(dot(wNormal, wViewDir));
Pow5(1.0 - nv)
*/

#if !defined(HUWA_STANDARD_LIT)
#define HUWA_STANDARD_LIT

#include "RewriteUnityGlobalIllumination.hlsl"

half4 _LightColor0;

half HSL_InternalFunction_SurfaceReduction(half perceptualRoughness, half roughness)
{
#if defined(UNITY_COLORSPACE_GAMMA)
    // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
    return 1.0 - 0.28 * roughness * perceptualRoughness;
#else
    // fade \in [0.5;1]
    return 1.0 / (roughness * roughness + 1.0);
#endif
}

half3 HSL_InternalFunction_Lighting(float3 unpackNormal, float3 wViewDir, float3 wLightDir, half3 diffColor, half3 specColor, half3 lightColor, half roughness)
{
    half nl = saturate(dot(unpackNormal, wLightDir));
    float3 halfDir = normalize(wLightDir + wViewDir);
    float nh = saturate(dot(unpackNormal, halfDir));
    float lh = saturate(dot(wLightDir, halfDir));
    
    half3 specular;
    {
        float a2 = roughness * roughness;
        float d = nh * nh * (a2 - 1.0) + 1.00001;
        
#if defined(UNITY_COLORSPACE_GAMMA)
        float specularTerm = roughness / (max(0.32, lh) * (1.5 + roughness) * d);
#else
        float specularTerm = a2 / (max(0.1, lh * lh) * (roughness + 0.5) * (d * d) * 4.0);
#endif

        specular = specColor * specularTerm;

    }

    return (diffColor + specular) * lightColor * nl;
}

half4 BRDF(float3 wPos, float3 unpackNormal, half4 mainColor, half3 emissionColor, half3 ambient,
    half metallic, half smoothness, half occlusion, half directionalLightShadow)
{
    half alpha = mainColor.a;
    
#if defined(_MODE_ALPHATEST_ON)
    clip(alpha - _Cutoff);
#endif
    
    float3 wViewDir = normalize(_WorldSpaceCameraPos - wPos);
    float3 wReflectDir = reflect(-wViewDir, unpackNormal);
    
    half oneMinusReflectivity = unity_ColorSpaceDielectricSpec.a - metallic * unity_ColorSpaceDielectricSpec.a;
    half reflectivity = 1.0 - oneMinusReflectivity;
    
    half perceptualRoughness = 1.0 - smoothness;
    half roughness = max(perceptualRoughness * perceptualRoughness, 0.002);
    
    half3 albedo = mainColor.rgb;
    half3 diffColor = albedo * oneMinusReflectivity;
    
#if defined(_MODE_ALPHAPREMULTIPLY_ON)
    diffColor *= alpha;
    alpha = reflectivity + oneMinusReflectivity * alpha;
#endif
    
    half3 specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
    
    half3 color;
    {
        color = emissionColor;
        
        half nv = abs(dot(unpackNormal, wViewDir));
        
        half3 giDiffuse = ambient;
        half3 giSpecular = UnityGI_IndirectSpecular(wPos, wReflectDir, perceptualRoughness, occlusion);
        
        half grazingTerm = saturate(smoothness + reflectivity);
        half surfaceReduction = HSL_InternalFunction_SurfaceReduction(perceptualRoughness, roughness);
        
        float pow5 = 1.0 - nv;
        pow5 = pow5 * pow5 * pow5 * pow5 * pow5;
        
        color += giDiffuse * diffColor;
        color += giSpecular * lerp(specColor, grazingTerm, pow5) * surfaceReduction;
    }
    
    float4 pointLightAtten;
    float3 pointLightDir0, pointLightDir1, pointLightDir2, pointLightDir3;
    {
        float4 toLightX = unity_4LightPosX0 - wPos.x;
        float4 toLightY = unity_4LightPosY0 - wPos.y;
        float4 toLightZ = unity_4LightPosZ0 - wPos.z;

        float4 lengthSq = toLightX * toLightX + toLightY * toLightY + toLightZ * toLightZ;
        float4 corr = rsqrt(lengthSq);
        
        //pointLightAtten = 1.0 / (1.0 + lengthSq * unity_4LightAtten0);
        pointLightAtten = (1.0 - lengthSq * unity_4LightAtten0 * 0.04) / (1.0 + lengthSq * unity_4LightAtten0);
        pointLightAtten = max(0.0, pointLightAtten);
        
        pointLightDir0 = float3(toLightX.x, toLightY.x, toLightZ.x) * corr.x;
        pointLightDir1 = float3(toLightX.y, toLightY.y, toLightZ.y) * corr.y;
        pointLightDir2 = float3(toLightX.z, toLightY.z, toLightZ.z) * corr.z;
        pointLightDir3 = float3(toLightX.w, toLightY.w, toLightZ.w) * corr.w;
    }
    
    half3 lightColor = _LightColor0.rgb * directionalLightShadow;
    float3 wLightDir = normalize(_WorldSpaceLightPos0.xyz - wPos * _WorldSpaceLightPos0.w);
    color += HSL_InternalFunction_Lighting(unpackNormal, wViewDir, wLightDir, diffColor, specColor, lightColor, roughness);
    
    lightColor = unity_LightColor[0].rgb * pointLightAtten.x;
    wLightDir = pointLightDir0;
    color += HSL_InternalFunction_Lighting(unpackNormal, wViewDir, wLightDir, diffColor, specColor, lightColor, roughness);
    
    lightColor = unity_LightColor[1].rgb * pointLightAtten.y;
    wLightDir = pointLightDir1;
    color += HSL_InternalFunction_Lighting(unpackNormal, wViewDir, wLightDir, diffColor, specColor, lightColor, roughness);
    
    lightColor = unity_LightColor[2].rgb * pointLightAtten.z;
    wLightDir = pointLightDir2;
    color += HSL_InternalFunction_Lighting(unpackNormal, wViewDir, wLightDir, diffColor, specColor, lightColor, roughness);
    
    lightColor = unity_LightColor[3].rgb * pointLightAtten.w;
    wLightDir = pointLightDir3;
    color += HSL_InternalFunction_Lighting(unpackNormal, wViewDir, wLightDir, diffColor, specColor, lightColor, roughness);
    
#if !(defined(_MODE_ALPHABLEND_ON) || defined(_MODE_ALPHAPREMULTIPLY_ON))
    alpha = 1.0;
#endif
    
    return half4(color, alpha);
}

#endif // #if !defined(HUWA_STANDARD_LIT)
