Shader "HuwaPortal/StencilDepthWrite"
{
    SubShader
    {
        Tags
        {
            "Queue" = "Overlay+500"
            "DisableBatching" = "False"
            "IgnoreProjector" = "True"
        }

        Pass
        {
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
            };

            uint _StencilA;

            V2F VertexShaderStage(I2V input)
            {
                V2F output = (V2F) 0;
                output.cPos = UnityObjectToClipPos(input.lPos);
                return output;
            }

            uint FragmentShaderStage(V2F input) : SV_Target
            {
                bool flag = (_StencilA > 255);
                clip(-flag);

                return _StencilA;
            }

            ENDCG
        }
    }
}
