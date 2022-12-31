#define UNITY_MATRIX_I_M unity_WorldToObject

#include "UnityCG.cginc"

struct VertexData
{
    float4 pos : POSITION;
};

struct FragmentData
{
    float4 cPos : SV_POSITION;
    float4 sPos : TEXCOORD0;
    float3 lPos : TEXCOORD1;
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

static float _Epsilon = 0.002;
static float _DrawingDistance = 1000.0;
static float _FoldingLimit = 1.0;
static int _Iterations = 12;

fixed4 _LightColor0;



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

float3 getNormal(float3 pos, float origineD)
{
    float3 vx = pos;
    float3 vy = pos;
    float3 vz = pos;
    
    vx.x -= _Epsilon;
    vy.y -= _Epsilon;
    vz.z -= _Epsilon;
    
    return normalize(float3(origineD, origineD, origineD) - float3(dist_func(vx), dist_func(vy), dist_func(vz)));
}



VertexData VertexStage(VertexData input)
{
    return input;
}

FragmentData FragmentDataGeneration(int index)
{
    FragmentData output = (FragmentData) 0;
    output.lPos = VertexPosition[index] * 6.0;
    output.cPos = UnityObjectToClipPos(output.lPos);
    output.sPos = ComputeScreenPos(output.cPos);
    return output;
}

[maxvertexcount(16)]
void GeometryStage(point VertexData input[1], inout TriangleStream<FragmentData> stream)
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

half4 FragmentStage(FragmentData input) : SV_Target
{
    float3 localSpaceCameraPos = mul(UNITY_MATRIX_I_M, float4(_WorldSpaceCameraPos, 1.0));
    float3 rayDirection = normalize(input.lPos - localSpaceCameraPos);
    float3 rayPosition = localSpaceCameraPos;
    
    bool culling = true;
    
    half3 col = 0.0;
    float d = 0.0;
    float totalD = 0.0;
    
    while (totalD < _DrawingDistance)
    {
        float d = dist_func(rayPosition);
        
        if (d < _Epsilon)
        {
            culling = false;
            
            float3 normal = getNormal(rayPosition, d);
            float3 worldNormal = UnityObjectToWorldNormal(normal);
            
            half3 ambient = ShadeSH9(half4(worldNormal, 1.0));
            half diffuse = saturate(dot(worldNormal, normalize(WorldSpaceLightDir(float4(rayPosition, 1.0)))));
            col = _LightColor0.rgb * diffuse + ambient;
            
            break;
        }
        
        rayPosition += rayDirection * d;
        totalD += d;
    }
    
    clip(-culling);
    
    return half4(col, 1.0);
}

half4 FragmentStage_Depth(FragmentData input) : SV_Target
{
    return 1.0;
}