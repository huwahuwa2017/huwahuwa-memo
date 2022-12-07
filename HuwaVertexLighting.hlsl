//Ver7 2022/12/07 10:32

#ifndef HUWA_VERTEX_LIGHTING_INCLUDED
#define HUWA_VERTEX_LIGHTING_INCLUDED

#include "UnityCG.cginc"

float4 HuwaLightPositionRecalculation(int index)
{
#if UNITY_SINGLE_PASS_STEREO
    float4 temp = mul(unity_StereoMatrixInvV[0], unity_LightPosition[index]);
    return mul(UNITY_MATRIX_V, temp);
#else
    return unity_LightPosition[index];
#endif
}

float4 HuwaSpotDirectionRecalculation(int index)
{
#if UNITY_SINGLE_PASS_STEREO
    float3 temp = mul((float3x3) unity_StereoMatrixInvV[0], unity_SpotDirection[index].xyz);
    temp = mul((float3x3) UNITY_MATRIX_V, temp);
    return float4(temp, unity_SpotDirection[index].w);
#else
    return unity_SpotDirection[index];
#endif
}

static float4 _HuwaLightPosition[8] =
{
    HuwaLightPositionRecalculation(0),
    HuwaLightPositionRecalculation(1),
    HuwaLightPositionRecalculation(2),
    HuwaLightPositionRecalculation(3),
    HuwaLightPositionRecalculation(4),
    HuwaLightPositionRecalculation(5),
    HuwaLightPositionRecalculation(6),
    HuwaLightPositionRecalculation(7)
};

static float4 _HuwaSpotDirection[8] =
{
    HuwaSpotDirectionRecalculation(0),
    HuwaSpotDirectionRecalculation(1),
    HuwaSpotDirectionRecalculation(2),
    HuwaSpotDirectionRecalculation(3),
    HuwaSpotDirectionRecalculation(4),
    HuwaSpotDirectionRecalculation(5),
    HuwaSpotDirectionRecalculation(6),
    HuwaSpotDirectionRecalculation(7)
};



half3 HuwaVertexLightingAmbientColor(float worldNormalY)
{
    half3 ambientSky = lerp(unity_AmbientEquator, unity_AmbientSky, worldNormalY);
    half3 ambientGround = lerp(unity_AmbientEquator, unity_AmbientGround, -worldNormalY);
    half3 ambientColor = lerp(ambientSky, ambientGround, worldNormalY < 0.0);
    return ambientColor;
}

half3 HuwaShadeVertexLightsFull(float3 position, float3 normal, half3 ambientColorAdjustment = (half3) 0, float diffuseAdjustment = 0.0)
{
    float3 viewPosition = UnityObjectToViewPos(position);
    float3 worldNormal = normalize(mul((float3x3) UNITY_MATRIX_M, normal));
    float3 viewNormal = normalize(mul((float3x3) UNITY_MATRIX_V, worldNormal));
    
    half3 lightColor = HuwaVertexLightingAmbientColor(worldNormal.y) + ambientColorAdjustment;
    
    for (int i = 0; i < 8; i++)
    {
        float3 toLight = _HuwaLightPosition[i].xyz - viewPosition.xyz * _HuwaLightPosition[i].w;
        float lengthSq = dot(toLight, toLight);
        lengthSq = max(lengthSq, 0.000001);
        toLight *= rsqrt(lengthSq);

        float atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z);
        float rho = max(0, dot(toLight, _HuwaSpotDirection[i].xyz));
        float spotAtt = (rho - unity_LightAtten[i].x) * unity_LightAtten[i].y;
        atten *= saturate(spotAtt);

        float diff = saturate(dot(viewNormal, toLight) + diffuseAdjustment);
        lightColor += unity_LightColor[i].rgb * (diff * atten);
    }

    return lightColor;
}

#endif // HUWA_VERTEX_LIGHTING_INCLUDED
