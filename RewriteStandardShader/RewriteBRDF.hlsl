// Ver3 2024-08-08 09:08

// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)
// Created based on Unity 2022.3.8f1 UnityStandardBRDF.cginc

#if !defined(REWRITE_BRDF)
#define REWRITE_BRDF

sampler2D unity_NHxRoughness;

half Pow4(half x)
{
    return x * x * x * x;
}

half2 Pow4(half2 x)
{
    return x * x * x * x;
}

half3 Pow4(half3 x)
{
    return x * x * x * x;
}

half4 Pow4(half4 x)
{
    return x * x * x * x;
}

half Pow5(half x)
{
    return x * x * x * x * x;
}

half2 Pow5(half2 x)
{
    return x * x * x * x * x;
}

half3 Pow5(half3 x)
{
    return x * x * x * x * x;
}

half4 Pow5(half4 x)
{
    return x * x * x * x * x;
}

float3 Unity_SafeNormalize(float3 inVec)
{
    float dp3 = max(0.001, dot(inVec, inVec));
    return inVec * rsqrt(dp3);
}

half SurfaceReduction(half perceptualRoughness, half roughness)
{
#if defined(UNITY_COLORSPACE_GAMMA)
    // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
    return 1.0 - 0.28 * roughness * perceptualRoughness;
#else
    // fade \in [0.5;1]
    return 1.0 / (roughness * roughness + 1.0);
#endif
}



// High Quality
half3 BRDF1_Unity_PBS(half3 lightColor, half3 diffColor, half3 specColor, half reflectivity, half smoothness, half3 giDiffuse, half3 giSpecular,
    float3 wNormal, float3 wViewDir, float3 wLightDir)
{
    float nl = saturate(dot(wNormal, wLightDir));
    half nv = abs(dot(wNormal, wViewDir));
    
    float3 halfDir = Unity_SafeNormalize(wLightDir + wViewDir);
    float nh = saturate(dot(wNormal, halfDir));
    half lh = saturate(dot(wLightDir, halfDir));
    
    half perceptualRoughness = 1.0 - smoothness;
    half roughness = perceptualRoughness * perceptualRoughness;
    roughness = max(roughness, 0.002);
    
    
    
    half3 diffuse;
    {
        half fd90 = 0.5 + 2.0 * lh * lh * perceptualRoughness;
        half lightScatter = (1.0 + (fd90 - 1.0) * Pow5(1.0 - nl));
        half viewScatter = (1.0 + (fd90 - 1.0) * Pow5(1.0 - nv));
        half diffuseTerm = lightScatter * viewScatter;
        diffuse = diffColor * diffuseTerm;
    }
    
    half3 specular;
    {
        float V;
        {
            float lambdaV = nl * (nv * (1.0 - roughness) + roughness);
            float lambdaL = nv * (nl * (1.0 - roughness) + roughness);
            V = 0.5 / (lambdaV + lambdaL + 1e-5f);
        }
        
        float D;
        {
            float a2 = roughness * roughness;
            float d = nh * nh * (a2 - 1.0) + 1.0;
            D = a2 / (d * d + 1e-7f);
        }
        
        float specularTerm = V * D;
        
#if defined(UNITY_COLORSPACE_GAMMA)
        specularTerm = sqrt(max(1e-4h, specularTerm));
#endif
        
        half3 F = specColor + (1.0 - specColor) * Pow5(1.0 - lh);
        
        specular = F * specularTerm;
    }
    
    half3 color = (diffuse + specular) * lightColor * nl;
    
#if defined(UNITY_PASS_FORWARDBASE)
    half grazingTerm = saturate(smoothness + reflectivity);
    half surfaceReduction = SurfaceReduction(perceptualRoughness, roughness);
    
    color += giDiffuse * diffColor;
    color += giSpecular * lerp(specColor, grazingTerm, Pow5(1.0 - nv)) * surfaceReduction;
#endif
    
    return color;
}



// Medium Quality
half3 BRDF2_Unity_PBS(half3 lightColor, half3 diffColor, half3 specColor, half reflectivity, half smoothness, half3 giDiffuse, half3 giSpecular,
    float3 wNormal, float3 wViewDir, float3 wLightDir)
{
    half nl = saturate(dot(wNormal, wLightDir));
    half nv = saturate(dot(wNormal, wViewDir));
    
    float3 halfDir = Unity_SafeNormalize(wLightDir + wViewDir);
    float nh = saturate(dot(wNormal, halfDir));
    float lh = saturate(dot(wLightDir, halfDir));
    
    half perceptualRoughness = 1.0 - smoothness;
    half roughness = perceptualRoughness * perceptualRoughness;
    
    
    
    half3 diffuse = diffColor;
    
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
    
    half3 color = (diffuse + specular) * lightColor * nl;
    
#if defined(UNITY_PASS_FORWARDBASE)
    half grazingTerm = saturate(smoothness + reflectivity);
    half surfaceReduction = SurfaceReduction(perceptualRoughness, roughness);
    
    color += giDiffuse * diffColor;
    color += giSpecular * lerp(specColor, grazingTerm, Pow4(1.0 - nv)) * surfaceReduction;
#endif
    
    return color;
}



// Low Quality
half3 BRDF3_Unity_PBS(half3 lightColor, half3 diffColor, half3 specColor, half reflectivity, half smoothness, half3 giDiffuse, half3 giSpecular,
    float3 wNormal, float3 wViewDir, float3 wLightDir)
{
    half nl = saturate(dot(wNormal, wLightDir));
    half nv = saturate(dot(wNormal, wViewDir));
    
    half perceptualRoughness = 1.0 - smoothness;
    
    
    
    half3 diffuse = diffColor;
    
    half3 specular;
    {
        half rlPow4 = Pow4(dot(reflect(wViewDir, wNormal), wLightDir));
        half LUT_RANGE = 16.0;
        float specularTerm = tex2Dlod(unity_NHxRoughness, half4(rlPow4, perceptualRoughness, 0.0, 0.0)).r * LUT_RANGE;
        specular = specColor * specularTerm;
    }
    
    half3 color = (diffuse + specular) * lightColor * nl;
    
#if defined(UNITY_PASS_FORWARDBASE)
    half grazingTerm = saturate(smoothness + reflectivity);
    
    color += giDiffuse * diffColor;
    color += giSpecular * lerp(specColor, grazingTerm, Pow4(1.0 - nv));
#endif
    
    return color;
}



half3 BRDF(half3 lightColor, half3 diffColor, half3 specColor, half reflectivity, half smoothness, half3 giDiffuse, half3 giSpecular,
    float3 wNormal, float3 wViewDir, float3 wLightDir)
{
#if defined(UNITY_PBS_USE_BRDF3)
    // Low Quality
    return BRDF3_Unity_PBS(lightColor, diffColor, specColor, reflectivity, smoothness, giDiffuse, giSpecular, wNormal, wViewDir, wLightDir);
#elif defined(UNITY_PBS_USE_BRDF2)
    // Medium Quality
    return BRDF2_Unity_PBS(lightColor, diffColor, specColor, reflectivity, smoothness, giDiffuse, giSpecular, wNormal, wViewDir, wLightDir);
#elif defined(UNITY_PBS_USE_BRDF1)
    // High Quality
    return BRDF1_Unity_PBS(lightColor, diffColor, specColor, reflectivity, smoothness, giDiffuse, giSpecular, wNormal, wViewDir, wLightDir);
#else
    return 0.0;
#endif
}

#endif // !defined(REWRITE_BRDF)
