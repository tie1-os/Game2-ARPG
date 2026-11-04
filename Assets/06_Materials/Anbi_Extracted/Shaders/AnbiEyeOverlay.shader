Shader "Anbi/URP Eye Overlay"
{
    Properties
    {
        _BaseMap("Face Texture", 2D) = "white" {}
        _EyeColorMap("Eye Color Table", 2D) = "white" {}
        _BaseColor("Tint", Color) = (1,1,1,1)
        _Opacity("Opacity", Range(0,1)) = 1
        _Brightness("Brightness", Range(0,3)) = 2
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Render Face", Float) = 2
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
        Pass
        {
            Name "EyeOverlay"
            Tags { "LightMode"="UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            Cull [_Cull]
            Offset -1, -1
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma target 3.5
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            TEXTURE2D(_EyeColorMap);
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half _Opacity;
                half _Brightness;
                half _Cull;
            CBUFFER_END
            struct Attributes { float4 positionOS:POSITION; float2 uv:TEXCOORD0; float4 color:COLOR; };
            struct Varyings { float4 positionCS:SV_POSITION; float2 uv:TEXCOORD0; half4 overlay:TEXCOORD1; };
            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                // The red vertex byte addresses a color/opacity entry in the original 16x16 table.
                uint index = (uint)round(saturate(input.color.r) * 255.0);
                int2 cell = int2(index % 16u, 15u - index / 16u);
                output.overlay = LOAD_TEXTURE2D(_EyeColorMap, cell);
                return output;
            }
            half4 Frag(Varyings input):SV_Target
            {
                half4 base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                return half4(base.rgb * input.overlay.rgb * _BaseColor.rgb * _Brightness,
                             saturate(base.a * input.overlay.a * _BaseColor.a * _Opacity));
            }
            ENDHLSL
        }
    }
}
