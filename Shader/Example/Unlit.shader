Shader "HuwaExample/Unlit"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            #include "UnityCG.cginc"

            struct I2V
            {
                float4 lPos : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct V2F
            {
                float4 cPos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            Texture2D _MainTex;
            SamplerState sampler_MainTex;

            V2F VertexShaderStage(I2V input)
            {
                V2F output = (V2F)0;
                output.cPos = UnityObjectToClipPos(input.lPos);
                output.uv = input.uv;
                return output;
            }

            half4 FragmentShaderStage(V2F input) : SV_Target
            {
                return _MainTex.Sample(sampler_MainTex, input.uv);
            }

            ENDCG
        }
    }
}
