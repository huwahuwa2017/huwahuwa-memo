


#pragma require tessellation
#pragma require geometry

#pragma vertex VertexShaderStage
#pragma hull HullShaderStage
#pragma domain DomainShaderStage
#pragma geometry GeometryShaderStage
#pragma fragment FragmentShaderStage

#define 

#include 

struct TessellationFactor
{
    float tessFactor[3] : SV_TessFactor;
    float insideTessFactor : SV_InsideTessFactor;
};

struct I2V
{
    float4 lPos : POSITION;
    float3 lNormal : NORMAL;
    float4 lTangent : TANGENT;
    float2 uv : TEXCOORD0;
};

struct V2G
{
    float4 cPos : TEXCOORD0;
    float2 uv : TEXCOORD1;
};

struct G2F
{
    float4 cPos : SV_POSITION;
    float2 uv : TEXCOORD0;
};



sampler2D _ShadowMapTexture;

// Created based on Unity 2022.3.8f1 AutoLight.cginc UNITY_SHADOW_ATTENUATION
// cspXYW = computeScreenPos.xyw
half ShadowAttenuationLod(float3 cspXYW, half lod)
{
#if defined(DIRECTIONAL) && defined(SHADOWS_SCREEN) && !defined(UNITY_NO_SCREENSPACE_SHADOWS) && \
    !defined(UNITY_STEREO_MULTIVIEW_ENABLED) && !defined(UNITY_STEREO_INSTANCING_ENABLED)
    
    float4 coord = float4(cspXYW.xy / cspXYW.z, 0.0, lod);
    return tex2Dlod(_ShadowMapTexture, coord).r;
#else
    return 1.0;
#endif
}



float3 WorldRayStartPos(float4 vPos, float4 cPos)
{
    float4x4 pm = UNITY_MATRIX_P;
    
    float diffZ0, diffZ1;
    {
        float focusZ = (vPos.w * pm._m33) / -pm._m32;
        
        float nearZ;
        
#if defined(UNITY_REVERSED_Z)
        //DirectX True near z   1 = dot(vPos, (0, 0, m22, m23)) / dot(vPos, (0, 0, m32, m33)) Å® vPos.z =
        nearZ = (vPos.w * pm._m23 - pm._m33) / (pm._m32 - pm._m22);
#else
        //OpenGL True near z   -1 = dot(vPos, (0, 0, m22, m23)) / dot(vPos, (0, 0, m32, m33)) Å® vPos.z =
        nearZ = (vPos.w * (pm._m23 + pm._m33)) / -(pm._m32 + pm._m22);
#endif
        
        diffZ0 = abs(nearZ - focusZ);
        
#if defined(UNITY_REVERSED_Z)
        // DirectX True near z   1 = dot(vPos, m20m21m22m23) / dot(vPos, (0, 0, m32, m33)) Å® vPos.z =
        nearZ = dot(vPos.xyw, float3(pm._m20, pm._m21, pm._m23 - pm._m33)) / (pm._m32 - pm._m22);
#else
        // OpenGL True near z   -1 = dot(vPos, m20m21m22m23) / dot(vPos, (0, 0, m32, m33)) Å® vPos.z =
        nearZ = dot(vPos.xyw, float3(pm._m20, pm._m21, pm._m23 + pm._m33)) / -(pm._m32 + pm._m22);
#endif
        
        diffZ1 = abs(nearZ - focusZ);
    }
    
    float temp42 = length(vPos.xy);
    float nearGradient = (diffZ1 - diffZ0) / temp42;
    float rayGradient = cPos.w / temp42;

    // (x * rayGradient) Ç∆ (x * nearGradient + diffZ1) ÇÃåì_ÇÃZç¿ïWÇãÅÇﬂÇÈ
    float temp1 = (diffZ0 / (rayGradient - nearGradient)) * rayGradient;
    
    float4 temp0 = cPos;
    temp0.x *= temp1 / temp0.w;
    temp0.y *= temp1 / temp0.w;
    temp0.w = temp1;
    
#if defined(UNITY_REVERSED_Z)
    temp0.z = temp1;
#else
    temp0.z = -temp1;
#endif
    
    float4x4 unity_matrix_i_vp = inverse(UNITY_MATRIX_VP);
    return mul(unity_matrix_i_vp, temp0).xyz;
}





