


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





void MatrixMemoryLayout()
{
    float4x3 a;

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
}





// 2次方程式の解の公式の色々な実装
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





float4 ClipPosRestore(float4 cPos)
{
#if defined(UNITY_SINGLE_PASS_STEREO)
    cPos.x -= unity_StereoEyeIndex ? _ScreenParams.x : 0.0;
#endif
    
    cPos.xy /= _ScreenParams.xy;

#if defined(UNITY_REVERSED_Z)
    cPos.xy = cPos.xy * 2.0 - 1.0;
#else
    cPos.xyz = cPos.xyz * 2.0 - 1.0;
#endif

    cPos.xyz *= cPos.w;
    cPos.y *= _ProjectionParams.x;

    return cPos;
}





#if !defined(UNITY_MATRIX_I_M)
#define UNITY_MATRIX_I_M unity_WorldToObject
#endif

float3 Huwa_ObjectToWorldUnnormalizedDirection(float3 direction)
{
    return mul((float3x3) UNITY_MATRIX_M, direction);
}

float3 Huwa_ObjectToWorldUnnormalizedNormal(float3 normal)
{
#if defined(UNITY_ASSUME_UNIFORM_SCALING)
    return Huwa_ObjectToWorldUnnormalizedDirection(normal);
#else
    return mul(normal, (float3x3) UNITY_MATRIX_I_M);
#endif
}

float4 Huwa_ObjectToWorldUnnormalizedTangent(float4 tangent)
{
    return float4(Huwa_ObjectToWorldUnnormalizedDirection(tangent.xyz), tangent.w);
}

float3 Huwa_ObjectToWorldDirection(float3 direction)
{
    return normalize(Huwa_ObjectToWorldUnnormalizedDirection(direction));
}

float3 Huwa_ObjectToWorldNormal(float3 normal)
{
    return normalize(Huwa_ObjectToWorldUnnormalizedNormal(normal));
}

float4 Huwa_ObjectToWorldTangent(float4 tangent)
{
    return float4(Huwa_ObjectToWorldDirection(tangent.xyz), tangent.w);
}





float3 Huwa_SafeNormalize(float3 inVec)
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

//アフィン変換用行列の逆行列の計算式
float4x4 AffineInverse(float4x4 mat)
{
    float3x3 temp0 = Inverse((float3x3) mat);
    float3 temp1 = -mul(temp0, mat._14_24_34);

    return float4x4
    (
        float4(temp0[0], temp1.x),
        float4(temp0[1], temp1.y),
        float4(temp0[2], temp1.z),
        float4(0.0, 0.0, 0.0, 1.0)
    );
}

// 複数の親オブジェクトがある場合は使えない
float3 ScaleExtraction(float4x4 targetMatrix)
{
    float x = length(targetMatrix._11_21_31);
    float y = length(targetMatrix._12_22_32);
    float z = length(targetMatrix._13_23_33);
    
    return float3(x, y, z);
}

// 複数の親オブジェクトがある場合は使えない
float3x3 RotationExtraction(float4x4 targetMatrix)
{
    float3 rv = normalize(targetMatrix._11_21_31);
    float3 uv = normalize(targetMatrix._12_22_32);
    float3 fv = normalize(targetMatrix._13_23_33);
    
    return float3x3
    (
        rv.x, uv.x, fv.x,
        rv.y, uv.y, fv.y,
        rv.z, uv.z, fv.z
    );
}





float3 WorldRayStartPos(float4 vPos, float4 cPos)
{
    float4x4 pm = UNITY_MATRIX_P;
    
    float diffZ0, diffZ1;
    {
        float focusZ = (vPos.w * pm._m33) / -pm._m32;
        
        float nearZ;
        
#if defined(UNITY_REVERSED_Z)
        //DirectX True near z   1 = dot(vPos, (0, 0, m22, m23)) / dot(vPos, (0, 0, m32, m33)) → vPos.z =
        nearZ = (vPos.w * pm._m23 - pm._m33) / (pm._m32 - pm._m22);
#else
        //OpenGL True near z   -1 = dot(vPos, (0, 0, m22, m23)) / dot(vPos, (0, 0, m32, m33)) → vPos.z =
        nearZ = (vPos.w * (pm._m23 + pm._m33)) / -(pm._m32 + pm._m22);
#endif
        
        diffZ0 = abs(nearZ - focusZ);
        
#if defined(UNITY_REVERSED_Z)
        // DirectX True near z   1 = dot(vPos, m20m21m22m23) / dot(vPos, (0, 0, m32, m33)) → vPos.z =
        nearZ = dot(vPos.xyw, float3(pm._m20, pm._m21, pm._m23 - pm._m33)) / (pm._m32 - pm._m22);
#else
        // OpenGL True near z   -1 = dot(vPos, m20m21m22m23) / dot(vPos, (0, 0, m32, m33)) → vPos.z =
        nearZ = dot(vPos.xyw, float3(pm._m20, pm._m21, pm._m23 + pm._m33)) / -(pm._m32 + pm._m22);
#endif
        
        diffZ1 = abs(nearZ - focusZ);
    }
    
    float temp42 = length(vPos.xy);
    float nearGradient = (diffZ1 - diffZ0) / temp42;
    float rayGradient = cPos.w / temp42;

    // (x * rayGradient) と (x * nearGradient + diffZ1) の交点のZ座標を求める
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
    
    float4x4 unity_matrix_i_vp = Inverse(UNITY_MATRIX_VP);
    return mul(unity_matrix_i_vp, temp0).xyz;
}





