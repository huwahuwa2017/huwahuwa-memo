// MIT License
// Copyright (c) 2019 Inigo Quilez
// https://www.shadertoy.com/view/tl23RK

// MIT License
// Copyright (c) 2022 huwahuwa2017
// https://github.com/huwahuwa2017/huwahuwa-memo/blob/main/LICENSE

#include "UnityCG.cginc"

#if !defined(UNITY_MATRIX_I_M)
#define UNITY_MATRIX_I_M unity_WorldToObject
#endif

struct I2V
{
    float4 lPos : POSITION;
};

struct V2F
{
    float4 cPos : SV_POSITION;
    float3 lPos : TEXCOORD0;
    float3 lCameraPos : TEXCOORD1;
};

struct F2O
{
    float3 color : SV_Target;
    float depth : SV_Depth;
};

static float _Epsilon = 0.0001;
static float _DrawingDistance = 100.0;

fixed4 _LightColor0;

float _Thickness;
float _Size;
float _Cut;

#define AHS \
    rayPos.y -= ra;\
    \
    float2 sc = originalSC * ra;\
    float ra2 = sc.x * _Size;\
    \
    float3 rayPos2 = rayPos;\
    rayPos2.xy -= float2(sc.x, sc.y);\
    rayPos2 = float3(rayPos2.y, -rayPos2.x, rayPos2.z);\
    result = min(result, sdCappedTorus(rayPos2, originalSC, ra2, ra2 * _Thickness));\
    \
    float3 rayPos3 = rayPos;\
    rayPos3.xy -= float2(-sc.x, sc.y);\
    rayPos3 = float3(-rayPos3.z, rayPos3.x, -rayPos3.y);\
    result = min(result, sdCappedTorus(rayPos3, originalSC, ra2, ra2 * _Thickness));\

float sdCappedTorus(float3 p, float2 sc, float ra, float rb)
{
    p.y -= ra;
    
    // Created by Inigo Quilez
    // Capped Torus - exact
    // https://www.shadertoy.com/view/tl23RK
    p.x = abs(p.x);
    float k = (sc.y * p.x < sc.x * p.y) ? dot(p.xy, sc) : length(p.xy);
    return sqrt(dot(p, p) + ra * ra - 2.0 * ra * k) - rb;
}

void AHS_1(float3 rayPos, float2 originalSC, float ra, in out float result)
{
    AHS
}

void AHS_2(float3 rayPos, float2 originalSC, float ra, in out float result)
{
    AHS
    AHS_1(rayPos2, originalSC, ra2, result);
    AHS_1(rayPos3, originalSC, ra2, result);
}

void AHS_3(float3 rayPos, float2 originalSC, float ra, in out float result)
{
    AHS
    AHS_2(rayPos2, originalSC, ra2, result);
    AHS_2(rayPos3, originalSC, ra2, result);
}

void AHS_4(float3 rayPos, float2 originalSC, float ra, in out float result)
{
    AHS
    AHS_3(rayPos2, originalSC, ra2, result);
    AHS_3(rayPos3, originalSC, ra2, result);
}

void AHS_5(float3 rayPos, float2 originalSC, float ra, in out float result)
{
    AHS
    AHS_4(rayPos2, originalSC, ra2, result);
    AHS_4(rayPos3, originalSC, ra2, result);
}

void AHS_6(float3 rayPos, float2 originalSC, float ra, in out float result)
{
    AHS
    AHS_5(rayPos2, originalSC, ra2, result);
    AHS_5(rayPos3, originalSC, ra2, result);
}

void AHS_7(float3 rayPos, float2 originalSC, float ra, in out float result)
{
    AHS
    AHS_6(rayPos2, originalSC, ra2, result);
    AHS_6(rayPos3, originalSC, ra2, result);
}

void AHS_8(float3 rayPos, float2 originalSC, float ra, in out float result)
{
    AHS
    AHS_7(rayPos2, originalSC, ra2, result);
    AHS_7(rayPos3, originalSC, ra2, result);
}

float dist_func(float3 rayPos)
{
    float ra = 0.25;
    
    float an = UNITY_PI * _Cut;
    float2 originalSC = float2(sin(an), cos(an));
    
    rayPos.y += ra;
    float result = sdCappedTorus(rayPos, originalSC, ra, ra * _Thickness);
    AHS_6(rayPos, originalSC, ra, result);
    
    return result;
}

float3 CalcNormal(float3 pos, float origineD)
{
    float3 vx = pos;
    float3 vy = pos;
    float3 vz = pos;
    
    vx.x -= _Epsilon;
    vy.y -= _Epsilon;
    vz.z -= _Epsilon;
    
    return normalize(origineD.xxx - float3(dist_func(vx), dist_func(vy), dist_func(vz)));
}

// Created based on VertexGIForward
half3 SimpleGI(float3 wPos, half3 wNormal)
{
    half3 pointLights = Shade4PointLights
    (
        unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
        unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
        unity_4LightAtten0, wPos, wNormal
    );
    
    return pointLights + max(0.0, ShadeSH9(half4(wNormal, 1.0)));
}

V2F VertexShaderStage(I2V input)
{
    // カメラの位置(ワールド座標系)をローカル座標系に変換
    float3 localCameraPos = mul(UNITY_MATRIX_I_M, float4(_WorldSpaceCameraPos, 1.0)).xyz;
    
    // ローカル座標系でRayを計算
    float3 lRay = input.lPos.xyz - localCameraPos;
    
    V2F output = (V2F) 0;
    output.lCameraPos = localCameraPos;
    output.lPos = input.lPos;
    output.cPos = UnityObjectToClipPos(input.lPos);
    return output;
}

F2O FragmentShaderStage(V2F input)
{
    float3 localCameraPos = input.lCameraPos;
    float3 rayDirection = normalize(input.lPos - localCameraPos);
    
    float3 lPos = localCameraPos;
    bool culling = true;
    float d = 0.0;
    float totalD = 0.0;
    
    while (totalD < _DrawingDistance)
    {
        d = dist_func(lPos);
        
        if (d < totalD * _Epsilon)
        {
            culling = false;
            break;
        }
        
        lPos += rayDirection * d;
        totalD += d;
    }
    
    clip(-culling);
    
    float3 wPos = mul(UNITY_MATRIX_M, float4(lPos, 1.0));
    
    float3 lNormal = CalcNormal(lPos, d);
    float3 wNormal = UnityObjectToWorldNormal(lNormal);
    
    half3 ambient = SimpleGI(wPos, wNormal);
    half diffuse = saturate(dot(wNormal, _WorldSpaceLightPos0.xyz));
    half3 color = _LightColor0.rgb * diffuse + ambient;
    //half3 color = abs(wNormal) * (_LightColor0.rgb * diffuse + ambient);
    
    float2 temp15 = UnityWorldToClipPos(wPos).zw;
    float depth = temp15.x / temp15.y;
    
    F2O output = (F2O) 0;
    output.color = half4(color, 1.0);
    output.depth = depth;
    return output;
}
