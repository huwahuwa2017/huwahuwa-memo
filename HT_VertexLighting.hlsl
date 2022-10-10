//Ver3 2022年10月11日 7時15分

#ifndef HT_VERTEX_LIGHTING_INCLUDED
#define HT_VERTEX_LIGHTING_INCLUDED

#include "UnityCG.cginc"

static float4 LightPositionRecalculation(int index)
{
#if UNITY_SINGLE_PASS_STEREO
    float4 temp = mul(unity_StereoMatrixInvV[0], unity_LightPosition[index]);
    return mul(UNITY_MATRIX_V, temp);
#else
    return unity_LightPosition[index];
#endif
}

static float4 _ht_LightPosition[8] =
{
    LightPositionRecalculation(0),
    LightPositionRecalculation(1),
    LightPositionRecalculation(2),
    LightPositionRecalculation(3),
    LightPositionRecalculation(4),
    LightPositionRecalculation(5),
    LightPositionRecalculation(6),
    LightPositionRecalculation(7)
};

static float4 SpotDirectionRecalculation(int index)
{
#if UNITY_SINGLE_PASS_STEREO
    float3 temp = mul((float3x3) unity_StereoMatrixInvV[0], unity_SpotDirection[index].xyz);
    temp = mul((float3x3) UNITY_MATRIX_V, temp);
    return float4(temp, unity_SpotDirection[index].w);
#else
    return unity_SpotDirection[index];
#endif
}

static float4 _ht_SpotDirection[8] =
{
    SpotDirectionRecalculation(0),
    SpotDirectionRecalculation(1),
    SpotDirectionRecalculation(2),
    SpotDirectionRecalculation(3),
    SpotDirectionRecalculation(4),
    SpotDirectionRecalculation(5),
    SpotDirectionRecalculation(6),
    SpotDirectionRecalculation(7)
};



half3 HT_ShadeVertexLightsFull(float3 position, float3 normal, half3 ambientColorAdjustment = (half3) 0, float diffuseAdjustment = 0.0)
{
    float3 viewpos = UnityObjectToViewPos(position);
    float3 worldN = normalize(mul((float3x3) UNITY_MATRIX_M, normal));
    float3 viewN = normalize(mul((float3x3) UNITY_MATRIX_V, worldN));
    
    half3 ambientColor = lerp(unity_AmbientSky.xyz, unity_AmbientGround.xyz, worldN.y < 0.0);
    ambientColor = lerp(unity_AmbientEquator.xyz, ambientColor, abs(worldN.y));
    half3 lightColor = ambientColor + ambientColorAdjustment;
    
    for (int i = 0; i < 8; i++)
    {
        float3 toLight = _ht_LightPosition[i].xyz - viewpos.xyz * _ht_LightPosition[i].w;
        float lengthSq = dot(toLight, toLight);
        lengthSq = max(lengthSq, 0.000001);
        toLight *= rsqrt(lengthSq);

        float atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z);
        float rho = max(0, dot(toLight, _ht_SpotDirection[i].xyz));
        float spotAtt = (rho - unity_LightAtten[i].x) * unity_LightAtten[i].y;
        atten *= saturate(spotAtt);

        float diff = saturate(dot(viewN, toLight) + diffuseAdjustment);
        lightColor += unity_LightColor[i].rgb * (diff * atten);
    }

    return lightColor;
}

#endif // HT_VERTEX_LIGHTING_INCLUDED
