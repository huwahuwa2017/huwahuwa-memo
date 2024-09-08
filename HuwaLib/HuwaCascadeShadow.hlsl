// Ver4 2024-09-09 00:12

// #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap

#if !defined(HUWA_CASCADE_SHADOW)
#define HUWA_CASCADE_SHADOW

#include "UnityCG.cginc"

#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
Texture2DArray _ShadowMapTexture;
#else
Texture2D _ShadowMapTexture;
#endif

half HuwaCascadeShadow(uint2 pixelPos)
{
#if !(defined(DIRECTIONAL) && defined(SHADOWS_SCREEN) && !defined(UNITY_NO_SCREENSPACE_SHADOWS))
    return 1.0;
#elif defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
    return _ShadowMapTexture[uint3(pixelPos, unity_StereoEyeIndex)].r;
#else
    return _ShadowMapTexture[uint2(pixelPos)].r;
#endif
}

half HuwaCascadeShadow_cPos(float3 cPos_XYW)
{
#if !(defined(DIRECTIONAL) && defined(SHADOWS_SCREEN) && !defined(UNITY_NO_SCREENSPACE_SHADOWS))
    return 1.0;
#endif
    
    float2 uv = cPos_XYW.xy / cPos_XYW.z;
    uv.y *= _ProjectionParams.x;
    uv = uv * 0.5 + 0.5;
    
    uint2 screenSize = uint2(_ScreenParams.xy + 0.5);
    uint2 pixelPos = uint2(uv * _ScreenParams.xy);
    pixelPos = clamp(pixelPos, 0, screenSize - 1);
    
#if defined(UNITY_SINGLE_PASS_STEREO)
    pixelPos.x += (unity_StereoEyeIndex) ? screenSize.x : 0;
#endif
    
    return HuwaCascadeShadow(pixelPos);
}

// cnssPos_XYW = ComputeNonStereoScreenPos(float4).xyw
half HuwaCascadeShadow_cnssPos(float3 cnssPos_XYW)
{
#if !(defined(DIRECTIONAL) && defined(SHADOWS_SCREEN) && !defined(UNITY_NO_SCREENSPACE_SHADOWS))
    return 1.0;
#endif
    
    float2 uv = cnssPos_XYW.xy / cnssPos_XYW.z;
    
    uint2 screenSize = uint2(_ScreenParams.xy + 0.5);
    uint2 pixelPos = uint2(uv * _ScreenParams.xy);
    pixelPos = clamp(pixelPos, 0, screenSize - 1);
    
#if defined(UNITY_SINGLE_PASS_STEREO)
    pixelPos.x += (unity_StereoEyeIndex) ? screenSize.x : 0;
#endif
    
    return HuwaCascadeShadow(pixelPos);
}

// csPos_XYW = ComputeScreenPos(float4).xyw
half HuwaCascadeShadow_csPos(float3 csPos_XYW)
{
#if !(defined(DIRECTIONAL) && defined(SHADOWS_SCREEN) && !defined(UNITY_NO_SCREENSPACE_SHADOWS))
    return 1.0;
#endif
    
    float2 uv = csPos_XYW.xy / csPos_XYW.z;
    
#if defined(UNITY_SINGLE_PASS_STEREO)
    uv.x = uv.x * 2.0 - unity_StereoEyeIndex;
#endif
    
    uint2 screenSize = uint2(_ScreenParams.xy + 0.5);
    uint2 pixelPos = uint2(uv * _ScreenParams.xy);
    pixelPos = clamp(pixelPos, 0, screenSize - 1);
    
#if defined(UNITY_SINGLE_PASS_STEREO)
    pixelPos.x += (unity_StereoEyeIndex) ? screenSize.x : 0;
#endif
    
    return HuwaCascadeShadow(pixelPos);
}

#endif // #if !defined(HUWA_CASCADE_SHADOW)
