// v1 2025-04-08 01:59

Shader "Custom/Average"
{
    Properties
    {
        // Input from Blit
        [HideInInspector]
        _MainTex("Main Texture", 2D) = "white" {}
    }

    SubShader
    {
        Pass
        {
            ZWrite Off

            CGPROGRAM

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage
            
            #include "UnityCG.cginc"
            
            SamplerState _InlineSampler_Point_Clamp;
            Texture2D _MainTex;

            struct I2V
            {
                float4 lPos : POSITION;
            };

            struct V2F
            {
                float4 cPos : SV_POSITION;
            };

            V2F VertexShaderStage(I2V input)
            {
                V2F output = (V2F) 0;
                output.cPos = UnityObjectToClipPos(input.lPos);
                return output;
            }

            float4 FragmentShaderStage(V2F input) : SV_Target
            {
                return _MainTex.SampleLevel(_InlineSampler_Point_Clamp, float2(0.5, 0.5), 999.9);
            }

            ENDCG
        }
    }
}
