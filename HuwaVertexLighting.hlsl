//Ver12 2022/12/23 12:39

#ifndef HUWA_VERTEX_LIGHTING_INCLUDED
#define HUWA_VERTEX_LIGHTING_INCLUDED

#include "UnityCG.cginc"

float4 HVL_LightPositionRecalculation(int index)
{
#if UNITY_SINGLE_PASS_STEREO
    float4 temp = mul(unity_StereoMatrixInvV[0], unity_LightPosition[index]);
    return mul(UNITY_MATRIX_V, temp);
#else
    return unity_LightPosition[index];
#endif
}

float4 HVL_SpotDirectionRecalculation(int index)
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
    HVL_LightPositionRecalculation(0),
    HVL_LightPositionRecalculation(1),
    HVL_LightPositionRecalculation(2),
    HVL_LightPositionRecalculation(3),
    HVL_LightPositionRecalculation(4),
    HVL_LightPositionRecalculation(5),
    HVL_LightPositionRecalculation(6),
    HVL_LightPositionRecalculation(7)
};

static float4 _HuwaSpotDirection[8] =
{
    HVL_SpotDirectionRecalculation(0),
    HVL_SpotDirectionRecalculation(1),
    HVL_SpotDirectionRecalculation(2),
    HVL_SpotDirectionRecalculation(3),
    HVL_SpotDirectionRecalculation(4),
    HVL_SpotDirectionRecalculation(5),
    HVL_SpotDirectionRecalculation(6),
    HVL_SpotDirectionRecalculation(7)
};

half3 HVL_AmbientColor(float worldNormalY)
{
    half3 ambientSky = lerp(unity_AmbientEquator, unity_AmbientSky, worldNormalY);
    half3 ambientGround = lerp(unity_AmbientEquator, unity_AmbientGround, -worldNormalY);
    half3 ambientColor = lerp(ambientSky, ambientGround, worldNormalY < 0.0);
    return ambientColor;
}

half3 HVL_ShadeVertexLightsFull(float3 position, float3 normal, half3 ambientColorAdjustment = 0.0, float diffuseAdjustment = 0.0)
{
    float3 viewPosition = UnityObjectToViewPos(position);
    float3 worldNormal = UnityObjectToWorldNormal(normal);
    float3 viewNormal = normalize(mul((float3x3) UNITY_MATRIX_V, worldNormal));
    
    half3 lightColor = HVL_AmbientColor(worldNormal.y) + ambientColorAdjustment;
    
    for (int i = 0; i < 8; i++)
    {
        float3 toLight = _HuwaLightPosition[i].xyz - viewPosition.xyz * _HuwaLightPosition[i].w;
        float lengthSq = dot(toLight, toLight);
        lengthSq += lengthSq < 0.0;
        toLight *= rsqrt(lengthSq);

        float atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z);
        float rho = max(0.0, dot(toLight, _HuwaSpotDirection[i].xyz));
        float spotAtt = (rho - unity_LightAtten[i].x) * unity_LightAtten[i].y;
        atten *= saturate(spotAtt);

        float diff = saturate(dot(viewNormal, toLight) + diffuseAdjustment);
        lightColor += unity_LightColor[i].rgb * (diff * atten);
    }

    return lightColor;
}

void HVL_ShadeVertexLightsFull(in float3 position, in float3 normal, in half3 ambientColorAdjustment, in float diffuseAdjustment, in int specularPower, out half3 totalLightColor, out half3 totalSpecular)
{
    float3 viewPosition = UnityObjectToViewPos(position);
    float3 viewDir = normalize(viewPosition);
    float3 worldNormal = normalize(mul((float3x3) UNITY_MATRIX_M, normal));
    float3 viewNormal = normalize(mul((float3x3) UNITY_MATRIX_V, worldNormal));
    
    totalLightColor = HVL_AmbientColor(worldNormal.y) + ambientColorAdjustment;
    totalSpecular = 0.0;
    
    for (int i = 0; i < 8; i++)
    {
        float3 toLight = _HuwaLightPosition[i].xyz - viewPosition.xyz * _HuwaLightPosition[i].w;
        float lengthSq = dot(toLight, toLight);
        lengthSq += lengthSq < 0.0;
        toLight *= rsqrt(lengthSq);
        
        float atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z);
        float rho = max(0.0, dot(toLight, _HuwaSpotDirection[i].xyz));
        float spotAtt = (rho - unity_LightAtten[i].x) * unity_LightAtten[i].y;
        atten *= saturate(spotAtt);
        
        float diff = saturate(dot(viewNormal, toLight) + diffuseAdjustment);
        half3 lightColor = unity_LightColor[i].rgb * (diff * atten);
        float specular = max(0.0, dot(normalize(toLight - viewDir), viewNormal));
        
        [unroll]
        for (int i = 0; i < specularPower; ++i)
        {
            specular *= specular;
        }
        
        totalLightColor += lightColor;
        totalSpecular += lightColor * specular;
    }
}

#endif // HUWA_VERTEX_LIGHTING_INCLUDED
