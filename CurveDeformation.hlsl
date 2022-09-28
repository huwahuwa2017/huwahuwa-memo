#include "UnityCG.cginc"

struct VertexData
{
    float4 pos : POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD;
};

struct FragmentData
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD;
    half3 lightColor : COLOR;
};

uniform sampler2D _MainTex;
uniform float _Length;
uniform float _AttractDistance;
uniform int _Division;
uniform float _ColorIntensity;
uniform half4 _AmbientColor;

float3 ScaleComponentExtraction(float4x4 targetMatrix)
{
    float x = length(targetMatrix._11_21_31);
    float y = length(targetMatrix._12_22_32);
    float z = length(targetMatrix._13_23_33);
    
    return float3(x, y, z);
}

float3x3 RotationComponentExtraction(float4x4 targetMatrix)
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

float3x3 LookRotation(float3 fv, float3 uv)
{
    float3 rv = normalize(cross(uv, fv));
    fv = normalize(fv);
    uv = cross(fv, rv);

    return float3x3
    (
        rv.x, uv.x, fv.x,
        rv.y, uv.y, fv.y,
        rv.z, uv.z, fv.z
    );
}

float4x4 ScaleExclusion(float4x4 targetMatrix)
{
    float3 rv = normalize(targetMatrix._11_21_31);
    float3 uv = normalize(targetMatrix._12_22_32);
    float3 fv = normalize(targetMatrix._13_23_33);
    
    targetMatrix._11_21_31 = rv;
    targetMatrix._12_22_32 = uv;
    targetMatrix._13_23_33 = fv;

    return targetMatrix;
}

float3 HT_ShadeVertexLightsFull(float4 vertex, float3 normal)
{
    float3 viewpos = UnityObjectToViewPos(vertex.xyz);
    float3 viewN = normalize(mul((float3x3) UNITY_MATRIX_IT_MV, normal));
    float3 lightColor = _AmbientColor; //UNITY_LIGHTMODEL_AMBIENT.xyz;

    for (int i = 0; i < 8; i++)
    {
        float3 toLight = unity_LightPosition[i].xyz - viewpos.xyz * unity_LightPosition[i].w;
        float lengthSq = dot(toLight, toLight);
        lengthSq = max(lengthSq, 0.000001);
        toLight *= rsqrt(lengthSq);

        float atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z);
        float rho = max(0, dot(toLight, unity_SpotDirection[i].xyz));
        float spotAtt = (rho - unity_LightAtten[i].x) * unity_LightAtten[i].y;
        atten *= saturate(spotAtt);

        float diff = max(0, dot(viewN, toLight));
        lightColor += unity_LightColor[i].rgb * (diff * atten);
    }

    return lightColor;
}

FragmentData Vert(VertexData data)
{
    if (data.pos.z <= 0.0)
    {
        half3 lightColor = HT_ShadeVertexLightsFull(data.pos, data.normal);
    
        FragmentData output = (FragmentData) 0;
        output.pos = UnityObjectToClipPos(data.pos);
        output.uv = data.uv;
        output.lightColor = lerp(lightColor, half3(1.0, 1.0, 1.0), _ColorIntensity);
        return output;
    }
    
    float3 localScale = ScaleComponentExtraction(unity_ObjectToWorld);
    float3 vertex_LPLRWS = data.pos.xyz * localScale;
    float length_WS = _Length * localScale.z;
    float attractDistance_WS = _AttractDistance * localScale.z;
    
    float3 modelOrigin_V = UnityObjectToViewPos(float3(0.0, 0.0, 0.0));
    
    int index_S = -1;
    float sqrMagnitude_S = attractDistance_WS * attractDistance_WS;
    float3 relativePosition_S = (float3) 0;

    int index_T = -1;
    float sqrMagnitude_T = sqrMagnitude_S;
    float3 relativePosition_T = (float3) 0;

    bool contraction = false;

    for (int i = 0; i < 8; ++i)
    {
        half4 tempLightColor = unity_LightColor[i];

        bool frag_R = tempLightColor.r == 0.0;
        bool frag_G = tempLightColor.g == 0.0;
        bool frag_B = tempLightColor.b == 0.0;

        float3 tempLightViewPos = unity_LightPosition[i].xyz;
        float3 tempRP = tempLightViewPos - modelOrigin_V;
        float tempSM = dot(tempRP, tempRP);

        bool flag_S = (tempSM < sqrMagnitude_S) & (tempLightColor.r != 0.0) & (tempLightColor.r < 0.02) & frag_G & frag_B;
        bool flag_T = (tempSM < sqrMagnitude_T) & (tempLightColor.g != 0.0) & (tempLightColor.g < 0.02) & frag_B & frag_R;
        bool flag_C = (tempSM < sqrMagnitude_T) & (tempLightColor.b != 0.0) & (tempLightColor.b < 0.02) & frag_R & frag_G;

        bool isSpotLight = unity_LightAtten[i].x != -1.0;

        bool overwrite_S = flag_S & isSpotLight;
        bool overwrite_T = (flag_T | flag_C) & isSpotLight;

        index_S = lerp(index_S, i, overwrite_S);
        sqrMagnitude_S = lerp(sqrMagnitude_S, tempSM, overwrite_S);
        relativePosition_S = lerp(relativePosition_S, tempRP, overwrite_S);

        index_T = lerp(index_T, i, overwrite_T);
        sqrMagnitude_T = lerp(sqrMagnitude_T, tempSM, overwrite_T);
        relativePosition_T = lerp(relativePosition_T, tempRP, overwrite_T);
        contraction = lerp(contraction, flag_C, overwrite_T);
    }
    
    float3x3 V2L_Rotation = mul(RotationComponentExtraction(unity_WorldToObject), RotationComponentExtraction(unity_MatrixInvV));
    
    float3 temp0 = mul(V2L_Rotation, unity_SpotDirection[index_S].xyz);
    float3 spotLightLocalPos_S = -temp0 * length_WS;
    float3 spotLightLocalDir_S = float3(0.0, 0.0, 0.0);
    float halfdistance_S = length_WS * 0.5;

    float3 spotLightLocalPos_T = mul(V2L_Rotation, relativePosition_T);
    float3 spotLightLocalDir_T = mul(V2L_Rotation, unity_SpotDirection[index_T].xyz);
    float distance_T = sqrt(sqrMagnitude_T);
    float halfdistance_T = distance_T * 0.5;

    float temp6 = attractDistance_WS - length_WS;
    float temp5 = clamp(attractDistance_WS - distance_T, 0.0, temp6) / temp6;

    float3 localLightPos = lerp(spotLightLocalPos_S, spotLightLocalPos_T, temp5);
    float3 localSpotLightDir = lerp(spotLightLocalDir_S, spotLightLocalDir_T, temp5);
    float halfdistance = lerp(halfdistance_S, halfdistance_T, temp5);
    
    float3 v0 = float3(0.0, 0.0, 0.0);
    float3 v1 = float3(0.0, 0.0, halfdistance);
    float3 v2 = localLightPos - localSpotLightDir * halfdistance;
    float3 v3 = localLightPos;
    
    float3 newResult = (float3) 0;
    float3 preResult = (float3) 0;
    float3 fv = float3(0.0, 0.0, 1.0);
    float3 uv = float3(0.0, 1.0, 0.0);
    float curveDistance = 0.0;
    float preCurveDistance = 0.0;
    float lpz = vertex_LPLRWS.z;

    for (int count = 1; count <= _Division; ++count)
    {
        float time = (float) count / (float) _Division;

        preResult = newResult;
        newResult = v0 + (v1 - v0) * (time * 3.0) + (v2 + v0 - v1 * 2.0) * (time * time * 3.0) + (v3 - v0 + (v1 - v2) * 3.0) * (time * time * time);

        fv = newResult - preResult;
        float3 rv = cross(uv, fv);
        uv = normalize(cross(fv, rv));

        preCurveDistance = curveDistance;
        curveDistance += length(fv);
        if (curveDistance > lpz)
            break;
    }

    float3x3 lookRotation = LookRotation(fv, uv);

    lpz = lerp(lpz, curveDistance, (curveDistance < lpz) & contraction);
    newResult = preResult + mul(lookRotation, float3(vertex_LPLRWS.xy, lpz - preCurveDistance));
    float4 newVertex_LPLRWS = float4(newResult, 1.0);
    
    float3 newNormal_L = mul(lookRotation, data.normal).xyz;
    half3 lightColor = HT_ShadeVertexLightsFull(newVertex_LPLRWS, newNormal_L);
    
    FragmentData output = (FragmentData) 0;
    output.pos = mul(UNITY_MATRIX_VP, mul(ScaleExclusion(unity_ObjectToWorld), newVertex_LPLRWS));
    output.uv = data.uv;
    output.lightColor = lerp(lightColor, half3(1.0, 1.0, 1.0), _ColorIntensity);
    return output;
}

half3 Frag(FragmentData data) : SV_Target
{
    return tex2D(_MainTex, data.uv).rgb * data.lightColor;
}
