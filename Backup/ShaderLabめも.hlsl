
    Properties
    {
        _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)

        [HDR]
        _EmissionColor("Emission Color", Color) = (0,0,0)

        _Metallic("Metallic", Range(0.0, 1.0)) = 1.0
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 1.0

        _MaxSize("Max Size", Float) = 0.1
    }

// SubShader
Tags
{
    "Queue" = "Background" "Geometry" "AlphaTest" "Transparent" "Overlay+1"
    "DisableBatching" = "True"
    "IgnoreProjector" = "True"
}

GrabPass
{
    "_GrabPass"
}

// Pass
Tags
{
    "LightMode" = "Always" "ForwardBase" "ForwardAdd" "ShadowCaster"
}

Blend SrcAlpha OneMinusSrcAlpha

Cull Back Front Off

Offset

ZClip False

ZTest Always

ZWrite Off

Stencil

#pragma require tessellation
#pragma require geometry

#pragma vertex VertexShaderStage
#pragma hull HullShaderStage
#pragma domain DomainShaderStage
#pragma geometry GeometryShaderStage
#pragma fragment FragmentShaderStage

#define 

#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"

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

#if !defined(UNITY_MATRIX_I_M)
#define UNITY_MATRIX_I_M unity_WorldToObject
#endif

#define COMPUTE_VIEW_NORMAL normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal))

SamplerState _InlineSampler_Linear_Repeat;

SamplerState _InlineSampler_Point_Clamp;



sampler2D _MainTex;

Texture2D _MainTex;
SamplerState sampler_MainTex;

float4 _MainTex_TexelSize;



#if defined(UNITY_PASS_FORWARDBASE)
#endif

#if defined(UNITY_PASS_FORWARDADD)
#endif

#if defined(UNITY_PASS_SHADOWCASTER)
#endif

UNITY_SINGLE_PASS_STEREO

UNITY_STEREO_INSTANCING_ENABLED

UNITY_STEREO_MULTIVIEW_ENABLED

#if defined(UNITY_REVERSED_Z)
    // DirectX
#else
    // OpenGL
#endif



// nan
asfloat(0xFFFFFFFF)

static bool _IsInMirror = UNITY_MATRIX_P._31 != 0.0 || UNITY_MATRIX_P._32 != 0.0;
��
float _VRChatMirrorMode;
static bool _IsInMirror = _VRChatMirrorMode != 0.0;



//�J�����������Ă������(World)
float3 wCameraDir = -UNITY_MATRIX_I_V._m02_m12_m22;

float3 wCameraDir = -UNITY_MATRIX_V._m20_m21_m22;

float3 wCameraDir = -UNITY_MATRIX_V[2].xyz;

//�J�����������Ă������(Local)
float3 lCameraDir = -UNITY_MATRIX_IT_MV[2].xyz;



// �|�C���g���C�g�̌��̌���
// Unity��Shade4PointLights
pointLightAtten = 1.0 / (1.0 + lengthSq * unity_4LightAtten0);

// huwahuwa��
pointLightAtten = (1.0 - lengthSq * unity_4LightAtten0 * 0.04) / (1.0 + lengthSq * unity_4LightAtten0);
pointLightAtten = max(0.0, pointLightAtten);

//https://github.com/lilxyzw/OpenLit/blob/main/Assets/OpenLit/core.hlsl
float4 atten = saturate(saturate((25.0 - lengthSq * unity_4LightAtten0) * 0.111375) / (0.987725 + lengthSq * unity_4LightAtten0));



float3 wPos = mul(UNITY_MATRIX_M, input.lPos).xyz;





void MatrixMemoryLayout()
{
    float4x4 a;

    float4x3
    (
        a[0][0], a[0][1], a[0][2],
        a[1][0], a[1][1], a[1][2],
        a[2][0], a[2][1], a[2][2],
        a[3][0], a[3][1], a[3][2]
    );

    float4x3
    (
        a._m00, a._m01, a._m02,
        a._m10, a._m11, a._m12,
        a._m20, a._m21, a._m22,
        a._m30, a._m31, a._m32
    );

    float4x3
    (
        a._11, a._12, a._13,
        a._21, a._22, a._23,
        a._31, a._32, a._33,
        a._41, a._42, a._43
    );
    
    float4x4
    (
        a._11, a._12, a._13, a._14,
    
        a._21, a._22, a._23, a._24,
    
        a._31, a._32, a._33, a._34,
    
        a._41, a._42, a._43, a._44
    );
}





// 2���������̉��̌����̐F�X�Ȏ���
void Temp0()
{
    float a, b, c, result;
    float s = 1; // 1 or -1

    {
        float d = b * b - 4.0 * a * c;
        result = (-b + s * sqrt(d)) / (2.0 * a);
    }

    {
        float d = b * b - 4.0 * a * c;
        result = (2.0 * c) / (-b - s * sqrt(d));
    }

    {
        b *= 0.5;
        float d = b * b - a * c;
        result = (-b + s * sqrt(d)) / a;
    }

    {
        b *= 0.5;
        float d = b * b - a * c;
        result = c / (-b - s * sqrt(d));
    }
}





// �ڋ�Ԃ̌v�Z����
void Temo1(I2V input)
{
    float3 lNormal = input.lNormal;
    float3 lTangent = input.lTangent.xyz;
    float3 lBinormal = cross(lNormal, lTangent) * input.lTangent.w;

    float3 wNormal = UnityObjectToWorldNormal(lNormal);
    float3 wTangent = UnityObjectToWorldDir(lTangent);
    float3 wBinormal = cross(wNormal, wTangent) * (input.lTangent.w * unity_WorldTransformParams.w);

    //float3 unpackNormal = UnpackNormal(tex2Dlod(_NormalMap, float4(uv, 0.0, 0.0)));
    //float3 unpackNormal = UnpackNormal(tex2D(_BumpMap, uv));
    float3 unpackNormal = UnpackScaleNormalRGorAG(tex2D(_BumpMap, uv), _BumpScale);
    
    // R = tangent
    // G = binormal
    // B = normal
    unpackNormal = wTangent * unpackNormal.r + wBinormal * unpackNormal.g + wNormal * unpackNormal.b;
    unpackNormal = normalize(unpackNormal);
}





//�����Ɨǂ�����������͂�
float SafeDivision(float a, float b)
{
    return (b == 0.0) ? 0.0 : a / b;
}

//�����Ɨǂ�����������͂�
float3 SafeNormalize(float3 inVec)
{
    float dp3 = dot(inVec, inVec);
    return inVec * rsqrt(dp3 + (dp3 == 0.0));
}

float ClampNormalize(float value, float min, float max)
{
    return saturate((value - min) / (max - min));
}

float3 PositionExtraction(float4x4 targetMatrix)
{
    return targetMatrix._14_24_34;
}

float3x3 ScalarMul(float3x3 mat, float scalar)
{
    return mat * scalar;
}





float3x3 LookRotation(float3 fv, float3 uv)
{
    fv = normalize(fv);
    float3 rv = normalize(cross(uv, fv));
    uv = cross(fv, rv);

    return float3x3
    (
        rv.x, uv.x, fv.x,
        rv.y, uv.y, fv.y,
        rv.z, uv.z, fv.z
    );
}





float4 SVPosToCPos(float4 svPos)
{
    svPos.xy /= _ScreenParams.xy;

#if defined(UNITY_SINGLE_PASS_STEREO)
    svPos.x -= unity_StereoEyeIndex;
#endif
    
#if defined(UNITY_REVERSED_Z)
    svPos.xy = svPos.xy * 2.0 - 1.0;
#else
    svPos.xyz = svPos.xyz * 2.0 - 1.0;
#endif

    svPos.xyz *= svPos.w;
    
    svPos.y *= _ProjectionParams.x;
    
    return svPos;
}

float4 SVPosToCPos(float4 svPos)
{
#if defined(UNITY_SINGLE_PASS_STEREO)
    svPos.x -= unity_StereoEyeIndex ? _ScreenParams.x : 0.0;
#endif
    
    svPos.xy /= _ScreenParams.xy;

#if defined(UNITY_REVERSED_Z)
    svPos.xy = svPos.xy * 2.0 - 1.0;
#else
    svPos.xyz = svPos.xyz * 2.0 - 1.0;
#endif

    svPos.xyz *= svPos.w;
    
    svPos.y *= _ProjectionParams.x;
    
//#if UNITY_UV_STARTS_AT_TOP
//    svPos.y = -svPos.y;
//#endif
    
    return svPos;
}





// Ray�̊J�n�ʒu��World���W�n�ŕԂ�
// ����ȓ��e�s��ł͎g���Ȃ����Ƃ�����
float3 WorldRayStartPos(float4 cPos)
{
    float4x4 mp = UNITY_MATRIX_P;
    
    // ���s���e������
    // unity_OrthoParams.w��ShadowCaster�ł͎g���Ȃ��̂ŕs�̗p
    if (any(mp[3] != float4(0.0, 0.0, 0.0, 1.0)))
    {
        return _WorldSpaceCameraPos;
    }
    
#if defined(UNITY_REVERSED_Z)
    cPos.z = 1.0;
#else
    cPos.z = -1.0;
#endif
    
    float3 temp0 = mul(Inverse((float3x3) mp), cPos.xyz - mp._m03_m13_m23);
    return mul(UNITY_MATRIX_I_V, float4(temp0, 1.0));
}

// https://discussions.unity.com/t/raycasting-through-a-custom-camera-projection-matrix/459472/9
// near clip�ʂ��l������Ray�̊J�n�ʒu��View���W�n�ŕԂ�
// ���m�������ׂ����� FragmentShader��p
float4 ViewRayStartPos(float4 vPos)
{
    float4 cPos = mul(unity_CameraProjection, vPos);
    cPos.xy /= cPos.w;
    cPos.z = -1.0;
    cPos.w = 1.0;
    
    float4 result = mul(unity_CameraInvProjection, cPos);
    return result / result.w;
}

// ��L�̏�����unity_CameraInvProjection�╽�s���e�p�̋t�s��̎��ō�����
float4 ViewRayStartPos(float4 vPos)
{
    float4 cPos;
    float4 result;
    
#if defined(UNITY_PASS_SHADOWCASTER)
    float4x4 mp = UNITY_MATRIX_P;
    
    // ���s���e������
    // unity_OrthoParams.w��ShadowCaster�ł͎g���Ȃ��̂ŕs�̗p
    if(all(mp[3] == float4(0.0, 0.0, 0.0, 1.0)))
    {
        cPos = mul(mp, vPos);
        //cPos.xy /= cPos.w;    ���s���e����cPos.w=1.0�ɂȂ�̂ŕK�v�Ȃ�����
        
#if defined(UNITY_REVERSED_Z)
        cPos.z = 1.0;
#else
        cPos.z = -1.0;
#endif
        
        result.xyz = mul(Inverse((float3x3)mp), cPos.xyz - mp._m03_m13_m23);
        result.w = 1.0;
        return result;
    }
#endif
    
    cPos = mul(unity_CameraProjection, vPos);
    cPos.xy /= cPos.w;
    cPos.z = -1.0;
    cPos.w = 1.0;
    
    result = mul(unity_CameraInvProjection, cPos);
    return result / result.w;
}





// HLSLSupport.cginc

struct sampler1D_f
{
    Texture1D<float4> t;
    SamplerState s;
};
struct sampler2D_f
{
    Texture2D<float4> t;
    SamplerState s;
};
struct sampler3D_f
{
    Texture3D<float4> t;
    SamplerState s;
};
struct samplerCUBE_f
{
    TextureCube<float4> t;
    SamplerState s;
};

float4 tex1D(sampler1D_f x, float v)
{
    return x.t.Sample(x.s, v);
}
float4 tex2D(sampler2D_f x, float2 v)
{
    return x.t.Sample(x.s, v);
}
float4 tex3D(sampler3D_f x, float3 v)
{
    return x.t.Sample(x.s, v);
}
float4 texCUBE(samplerCUBE_f x, float3 v)
{
    return x.t.Sample(x.s, v);
}

float4 tex1Dbias(sampler1D_f x, in float4 t)
{
    return x.t.SampleBias(x.s, t.x, t.w);
}
float4 tex2Dbias(sampler2D_f x, in float4 t)
{
    return x.t.SampleBias(x.s, t.xy, t.w);
}
float4 tex3Dbias(sampler3D_f x, in float4 t)
{
    return x.t.SampleBias(x.s, t.xyz, t.w);
}
float4 texCUBEbias(samplerCUBE_f x, in float4 t)
{
    return x.t.SampleBias(x.s, t.xyz, t.w);
}

float4 tex1Dlod(sampler1D_f x, in float4 t)
{
    return x.t.SampleLevel(x.s, t.x, t.w);
}
float4 tex2Dlod(sampler2D_f x, in float4 t)
{
    return x.t.SampleLevel(x.s, t.xy, t.w);
}
float4 tex3Dlod(sampler3D_f x, in float4 t)
{
    return x.t.SampleLevel(x.s, t.xyz, t.w);
}
float4 texCUBElod(samplerCUBE_f x, in float4 t)
{
    return x.t.SampleLevel(x.s, t.xyz, t.w);
}

float4 tex1Dgrad(sampler1D_f x, float t, float dx, float dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}
float4 tex2Dgrad(sampler2D_f x, float2 t, float2 dx, float2 dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}
float4 tex3Dgrad(sampler3D_f x, float3 t, float3 dx, float3 dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}
float4 texCUBEgrad(samplerCUBE_f x, float3 t, float3 dx, float3 dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}

float4 tex1D(sampler1D_f x, float t, float dx, float dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}
float4 tex2D(sampler2D_f x, float2 t, float2 dx, float2 dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}
float4 tex3D(sampler3D_f x, float3 t, float3 dx, float3 dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}
float4 texCUBE(samplerCUBE_f x, float3 t, float3 dx, float3 dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}

float4 tex1Dproj(sampler1D_f s, in float2 t)
{
    return tex1D(s, t.x / t.y);
}
float4 tex1Dproj(sampler1D_f s, in float4 t)
{
    return tex1D(s, t.x / t.w);
}
float4 tex2Dproj(sampler2D_f s, in float3 t)
{
    return tex2D(s, t.xy / t.z);
}
float4 tex2Dproj(sampler2D_f s, in float4 t)
{
    return tex2D(s, t.xy / t.w);
}
float4 tex3Dproj(sampler3D_f s, in float4 t)
{
    return tex3D(s, t.xyz / t.w);
}
float4 texCUBEproj(samplerCUBE_f s, in float4 t)
{
    return texCUBE(s, t.xyz / t.w);
}








