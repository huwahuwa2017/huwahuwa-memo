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
    float3 lRay : TEXCOORD0;
    float3 lCameraPos : TEXCOORD1;
};

struct F2O
{
    float3 color : SV_Target;
    float depth : SV_Depth;
};

fixed4 _LightColor0;

V2F VertexShaderStage(I2V input)
{
    // �J�����̈ʒu(���[���h���W�n)�����[�J�����W�n�ɕϊ�
    float3 localCameraPos = mul(UNITY_MATRIX_I_M, float4(_WorldSpaceCameraPos, 1.0)).xyz;
    
    // ���[�J�����W�n��Ray���v�Z
    float3 lRay = input.lPos.xyz - localCameraPos;
    
    V2F output = (V2F) 0;
    output.lCameraPos = localCameraPos;
    output.lRay = lRay;
    output.cPos = UnityObjectToClipPos(input.lPos);
    return output;
}

F2O FragmentShaderStage(V2F input)
{
    // ���ƃx�N�g���̌�_�����߂�
    // https://tjkendev.github.io/procon-library/python/geometry/circle_line_cross_point.html
    
    // ���a
    float r = 0.4;
    
    float3 cp = input.lCameraPos;
    float3 ray = input.lRay;
    
    // 2���������̉��̌�����a,b,c��p��
    float a = dot(ray, ray);
    float b = dot(ray, cp) * 2.0;
    float c = dot(cp, cp) - r * r;
    
    // 2���������̉��̌����̕������̒�
    float d = b * b - 4.0 * a * c;
    
    // d�̕��������v�Z����O�ɁAd��0��菬���������m�F����
    // 0��菬�����ꍇ�s�N�Z����j������
    clip(d);
    d = sqrt(d);
    d = min(-b + d, -b - d);
    
    // d��0��菬���������m�F����
    // 0��菬�����ꍇ�s�N�Z����j������
    clip(d);
    
    // Ray�Ƌ��̂��Փ˂�����W(���[�J�����W�n)
    float3 lPos = cp + ray * (d / (a + a));
    // �@��(���[���h���W�n)
    float3 wNormal = UnityObjectToWorldNormal(lPos);
    // lPos�����[���h���W�n�ɕϊ�
    float3 wPos = mul(UNITY_MATRIX_M, float4(lPos, 1.0)).xyz;
    
    // �P���ȃ��C�e�B���O�̌v�Z
    half3 ambient = ShadeSH9(half4(wNormal, 1.0));
    half diffuse = max(0.0, dot(wNormal, _WorldSpaceLightPos0.xyz));
    float3 color = _LightColor0.rgb * diffuse + ambient;
    
    // Z�[�x�̌v�Z
    float depth = LinearEyeDepth(dot(wPos - _WorldSpaceCameraPos, -UNITY_MATRIX_I_V._m02_m12_m22));
    
    F2O output = (F2O) 0;
    output.color = color;
    output.depth = depth;
    return output;
}
