Shader "HuwaExample/CubeMapView"
{
    Properties
    {
        [NoScaleOffset]
        _CubeMap("CubeMap", Cube) = "black" {}

        _Rotation("Rotation", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent+500"
        }

        Pass
        {
            Cull Off
            ZTest Always
            ZWrite Off

            CGPROGRAM

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            #include "UnityCG.cginc"

            struct I2V
            {
                float4 lPos : POSITION;
            };

            struct V2F
            {
                float4 cPos : SV_POSITION;
                float3 direction : TEXCOORD0;
            };

            SamplerState sampler_CubeMap;
            TextureCube _CubeMap;

            float _Rotation;

            V2F VertexShaderStage(I2V input)
            {
                float4 lPos = input.lPos;

                float3 direction = mul(UNITY_MATRIX_M, lPos).xyz - _WorldSpaceCameraPos;

                float angle = _Rotation * UNITY_TWO_PI;
                float2x2 rot = float2x2(cos(angle), sin(angle), -sin(angle), cos(angle));
                direction.xz = mul(rot, direction.xz);

                V2F output = (V2F)0;
                output.cPos = UnityObjectToClipPos(lPos);
                output.direction = direction;
                return output;
            }

            half4 FragmentShaderStage(V2F input) : SV_Target
            {
                return _CubeMap.SampleLevel(sampler_CubeMap, input.direction, 0.0);
            }

            ENDCG
        }
    }
}
