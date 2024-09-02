
#if !defined(UNITY_MATRIX_I_M)
#define UNITY_MATRIX_I_M unity_WorldToObject
#endif

#include "UnityCG.cginc"

struct Empty
{
};

struct V2F
{
    float4 cPos : SV_POSITION;
    float3 lPos : TEXCOORD0;
};

struct F2O
{
    half4 color : SV_Target;
    float depth : SV_Depth;
};

static float4 VertexPosition[] =
{
    float4(-1.0, -1.0, -1.0, 1.0),
    float4(1.0, -1.0, -1.0, 1.0),
    float4(-1.0, 1.0, -1.0, 1.0),
    float4(1.0, 1.0, -1.0, 1.0),
    float4(-1.0, -1.0, 1.0, 1.0),
    float4(1.0, -1.0, 1.0, 1.0),
    float4(-1.0, 1.0, 1.0, 1.0),
    float4(1.0, 1.0, 1.0, 1.0)
};

static float _Epsilon = 0.001;
static float _DrawingDistance = 1000.0;
static float _FoldingLimit = 1.0;
static int _Iterations = 12;

fixed4 _LightColor0;



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



float3 boxFold(float3 z, float dz)
{
    return clamp(z, -_FoldingLimit, _FoldingLimit) * 2.0 - z;
}

void sphereFold(inout float3 z, inout float dz, float minRadius, float fixedRadius)
{
    float m2 = minRadius * minRadius;
    float f2 = fixedRadius * fixedRadius;
    float r2 = dot(z, z);
    
    float temp = 1.0;
    temp = lerp(temp, f2 / r2, r2 < f2);
    temp = lerp(temp, f2 / m2, r2 < m2);
    
    z *= temp;
    dz *= temp;
}

float deMandelbox(float3 p, float scale, float minRadius, float fixedRadius)
{
    float3 z = p;
    float dr = 1.0;
    
    for (int i = 0; i < _Iterations; i++)
    {
        z = boxFold(z, dr);
        sphereFold(z, dr, minRadius, fixedRadius);
        z = scale * z + p;
        dr = dr * abs(scale) + 1.0;
    }
    
    float r = length(z);
    return r / abs(dr);
}

float dist_func(float3 p)
{
    return deMandelbox(p, 2.0, 0.75 + _SinTime.z * 0.25, 1.25 + _CosTime.z * 0.25);
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



void VertexShaderStage()
{
}

V2F FragmentDataGeneration(int index)
{
    V2F output = (V2F) 0;
    output.lPos = VertexPosition[index] * 6.0;
    output.cPos = UnityObjectToClipPos(output.lPos);
    return output;
}

[maxvertexcount(16)]
void GeometryShaderStage(point Empty input[1], inout TriangleStream<V2F> stream)
{
    stream.Append(FragmentDataGeneration(2));
    stream.Append(FragmentDataGeneration(3));
    stream.Append(FragmentDataGeneration(0));
    stream.Append(FragmentDataGeneration(1));
    stream.Append(FragmentDataGeneration(4));
    stream.Append(FragmentDataGeneration(5));
    stream.Append(FragmentDataGeneration(6));
    stream.Append(FragmentDataGeneration(7));
    stream.RestartStrip();
    stream.Append(FragmentDataGeneration(0));
    stream.Append(FragmentDataGeneration(4));
    stream.Append(FragmentDataGeneration(2));
    stream.Append(FragmentDataGeneration(6));
    stream.Append(FragmentDataGeneration(3));
    stream.Append(FragmentDataGeneration(7));
    stream.Append(FragmentDataGeneration(1));
    stream.Append(FragmentDataGeneration(5));
}

F2O FragmentShaderStage(V2F input)
{
    float3 localSpaceCameraPos = mul(UNITY_MATRIX_I_M, float4(_WorldSpaceCameraPos, 1.0));
    float3 rayDirection = normalize(input.lPos - localSpaceCameraPos);
    
    float3 lPos = localSpaceCameraPos;
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
    half3 color = abs(wNormal) * (_LightColor0.rgb * diffuse + ambient);
    
    float2 temp15 = UnityWorldToClipPos(wPos).zw;
    float depth = temp15.x / temp15.y;
    
    F2O output = (F2O) 0;
    output.color = half4(color, 1.0);
    output.depth = depth;
    return output;
}
