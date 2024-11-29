// HuwaTexelReadWrite OperationCheck

Shader "HuwaShader/HTRW_OperationCheck"
{
    SubShader
    {
        CGINCLUDE
        
        #pragma vertex VertexShaderStage
        #pragma fragment FragmentShaderStage

        #include "HuwaTexelReadWrite.hlsl"

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
            V2F output = (V2F)0;
            output.cPos = UnityObjectToClipPos(input.lPos);
            return output;
        }

        ENDCG

        Pass
        {
            CGPROGRAM

            float4 FragmentShaderStage(V2F input) : SV_Target
            {
                uint2 pos = uint2(input.cPos.xy);
                uint index = pos.x + pos.y * _ScreenParams.x;
                uint4 data = uint4(index, index + 123, index + 456, index + 789);

                return HTRW_R15BIT_TO_FP16(data);
            }

            ENDCG
        }

        GrabPass
        {
            "_GrabPass_R15bit"
        }
        
        Pass
        {
            CGPROGRAM

            float4 FragmentShaderStage(V2F input) : SV_Target
            {
                uint2 pos = uint2(input.cPos.xy);
                uint index = pos.x + pos.y * _ScreenParams.x;
                uint4 data = uint4(index, index + 123, index + 456, index + 789);

                return HTRW_R14BIT_TO_FP16(data);
            }

            ENDCG
        }

        GrabPass
        {
            "_GrabPass_R14bit"
        }

        Pass
        {
            CGPROGRAM

            float4 FragmentShaderStage(V2F input) : SV_Target
            {
                uint2 pos = uint2(input.cPos.xy);
                uint index = pos.x + pos.y * _ScreenParams.x;
                uint4 data = uint4(index, index + 123, index + 456, index + 789);

                return HTRW_R13BIT_TO_FP16(data);
            }

            ENDCG
        }

        GrabPass
        {
            "_GrabPass_R13bit"
        }

        Pass
        {
            CGPROGRAM
            
            Texture2D _GrabPass_R15bit;
            Texture2D _GrabPass_R14bit;
            Texture2D _GrabPass_R13bit;

            float4 FragmentShaderStage(V2F input) : SV_Target
            {
                uint2 pos = uint2(input.cPos.xy);
                uint index = pos.x + pos.y * _ScreenParams.x;
                uint4 data = uint4(index, index + 123, index + 456, index + 789);
                
                uint4 dataR15bit = HTRW_FP16_TO_R15BIT(_GrabPass_R15bit[uint2(input.cPos.xy)]);
                uint4 dataR14bit = HTRW_FP16_TO_R14BIT(_GrabPass_R14bit[uint2(input.cPos.xy)]);
                uint4 dataR13bit = HTRW_FP16_TO_R13BIT(_GrabPass_R13bit[uint2(input.cPos.xy)]);

                bool3 flags = false;
                flags.x = all(dataR15bit == (data & 0x00007FFF));
                flags.y = all(dataR14bit == (data & 0x00003FFF));
                flags.z = all(dataR13bit == (data & 0x00001FFF));
                return float4(flags, 1.0);
            }

            ENDCG
        }
    }
}
