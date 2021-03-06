Shader "Unlit Master"
{
    Properties
    {
        Vector1_A447B9B6("Scroll Speed", Float) = 0.3
        Color_B7377AD5("color 1", Color) = (0, 0, 0, 0)
        Color_257B8E43("color 2", Color) = (0, 0, 0, 0)
        Vector1_D41015F0("Cloud Cover", Float) = 0.1
        Vector1_663379B8("Additional Falloff", Float) = 0
        Vector1_BD222040("Density", Float) = 0.3
    }
    SubShader
    {
        Tags
    {
        "RenderPipeline"="UniversalPipeline"
        "RenderType"="Transparent"
        "Queue"="Transparent+0"
    }

        Pass
    {
        Name "Pass"
        Tags 
        { 
            // LightMode: <None>
        }
       
        // Render State
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        Cull Back
        ZTest LEqual
        ZWrite On
        // ColorMask: <None>
        

        HLSLPROGRAM
        #pragma vertex vert
        #pragma fragment frag

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        // Pragmas
        #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0
    #pragma multi_compile_fog
    #pragma multi_compile_instancing

        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
    #pragma multi_compile _ DIRLIGHTMAP_COMBINED
    #pragma shader_feature _ _SAMPLE_GI
        // GraphKeywords: <None>
        
        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS 
        #define FEATURES_GRAPH_VERTEX
        #define SHADERPASS_UNLIT
    #define REQUIRE_DEPTH_TEXTURE

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"

        // --------------------------------------------------
        // Graph

        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
    float Vector1_A447B9B6;
    float4 Color_B7377AD5;
    float4 Color_257B8E43;
    float Vector1_D41015F0;
    float Vector1_663379B8;
    float Vector1_BD222040;
    CBUFFER_END

        // Graph Functions
        
    void Unity_Multiply_float(float A, float B, out float Out)
    {
        Out = A * B;
    }

    void Unity_Add_float2(float2 A, float2 B, out float2 Out)
    {
        Out = A + B;
    }


    float2 Unity_GradientNoise_Dir_float(float2 p)
    {
        // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
        p = p % 289;
        float x = (34 * p.x + 1) * p.x % 289 + p.y;
        x = (34 * x + 1) * x % 289;
        x = frac(x / 41) * 2 - 1;
        return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
    }

    void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
    { 
        float2 p = UV * Scale;
        float2 ip = floor(p);
        float2 fp = frac(p);
        float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
        float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
        float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
        float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
        fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
        Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
    }


    inline float Unity_SimpleNoise_RandomValue_float (float2 uv)
    {
        return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
    }

    inline float Unity_SimpleNnoise_Interpolate_float (float a, float b, float t)
    {
        return (1.0-t)*a + (t*b);
    }


    inline float Unity_SimpleNoise_ValueNoise_float (float2 uv)
    {
        float2 i = floor(uv);
        float2 f = frac(uv);
        f = f * f * (3.0 - 2.0 * f);

        uv = abs(frac(uv) - 0.5);
        float2 c0 = i + float2(0.0, 0.0);
        float2 c1 = i + float2(1.0, 0.0);
        float2 c2 = i + float2(0.0, 1.0);
        float2 c3 = i + float2(1.0, 1.0);
        float r0 = Unity_SimpleNoise_RandomValue_float(c0);
        float r1 = Unity_SimpleNoise_RandomValue_float(c1);
        float r2 = Unity_SimpleNoise_RandomValue_float(c2);
        float r3 = Unity_SimpleNoise_RandomValue_float(c3);

        float bottomOfGrid = Unity_SimpleNnoise_Interpolate_float(r0, r1, f.x);
        float topOfGrid = Unity_SimpleNnoise_Interpolate_float(r2, r3, f.x);
        float t = Unity_SimpleNnoise_Interpolate_float(bottomOfGrid, topOfGrid, f.y);
        return t;
    }
    void Unity_SimpleNoise_float(float2 UV, float Scale, out float Out)
    {
        float t = 0.0;

        float freq = pow(2.0, float(0));
        float amp = pow(0.5, float(3-0));
        t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

        freq = pow(2.0, float(1));
        amp = pow(0.5, float(3-1));
        t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

        freq = pow(2.0, float(2));
        amp = pow(0.5, float(3-2));
        t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

        Out = t;
    }

    void Unity_Add_float(float A, float B, out float Out)
    {
        Out = A + B;
    }

    void Unity_Subtract_float(float A, float B, out float Out)
    {
        Out = A - B;
    }

    void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
    {
        Out = A * B;
    }

    void Unity_Add_float3(float3 A, float3 B, out float3 Out)
    {
        Out = A + B;
    }

    void Unity_Saturate_float(float In, out float Out)
    {
        Out = saturate(In);
    }

    void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
    {
        Out = lerp(A, B, T);
    }

    void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
    {
        Out = smoothstep(Edge1, Edge2, In);
    }

    void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
    {
        Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
    }

        // Graph Vertex
        struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 WorldSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 WorldSpaceTangent;
        float3 ObjectSpaceBiTangent;
        float3 WorldSpaceBiTangent;
        float3 WorldSpacePosition;
        float3 TimeParameters;
    };

    struct VertexDescription
    {
        float3 VertexPosition;
        float3 VertexNormal;
        float3 VertexTangent;
    };

    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
    {
        VertexDescription description = (VertexDescription)0;
        float _Split_F309CB61_R_1 = IN.WorldSpacePosition[0];
        float _Split_F309CB61_G_2 = IN.WorldSpacePosition[1];
        float _Split_F309CB61_B_3 = IN.WorldSpacePosition[2];
        float _Split_F309CB61_A_4 = 0;
        float2 _Vector2_8B7C924E_Out_0 = float2(_Split_F309CB61_R_1, _Split_F309CB61_B_3);
        float _Property_D2C3A804_Out_0 = Vector1_A447B9B6;
        float _Multiply_9F85CD85_Out_2;
        Unity_Multiply_float(IN.TimeParameters.x, _Property_D2C3A804_Out_0, _Multiply_9F85CD85_Out_2);
        float _Multiply_DCF89CB0_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 0.5, _Multiply_DCF89CB0_Out_2);
        float2 _Add_9687392E_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_DCF89CB0_Out_2.xx), _Add_9687392E_Out_2);
        float _GradientNoise_F2890215_Out_2;
        Unity_GradientNoise_float(_Add_9687392E_Out_2, 0.1, _GradientNoise_F2890215_Out_2);
        float _Multiply_CF00AA9B_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 1, _Multiply_CF00AA9B_Out_2);
        float2 _Add_48217401_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_CF00AA9B_Out_2.xx), _Add_48217401_Out_2);
        float _SimpleNoise_53936C34_Out_2;
        Unity_SimpleNoise_float(_Add_48217401_Out_2, 1, _SimpleNoise_53936C34_Out_2);
        float _Add_D5BAEB31_Out_2;
        Unity_Add_float(_GradientNoise_F2890215_Out_2, _SimpleNoise_53936C34_Out_2, _Add_D5BAEB31_Out_2);
        float _Multiply_780EB22D_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 1.5, _Multiply_780EB22D_Out_2);
        float2 _Add_F29A1A2E_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_780EB22D_Out_2.xx), _Add_F29A1A2E_Out_2);
        float _SimpleNoise_8F785206_Out_2;
        Unity_SimpleNoise_float(_Add_F29A1A2E_Out_2, 0.5, _SimpleNoise_8F785206_Out_2);
        float _Multiply_E6C7E894_Out_2;
        Unity_Multiply_float(_Add_D5BAEB31_Out_2, _SimpleNoise_8F785206_Out_2, _Multiply_E6C7E894_Out_2);
        float _Subtract_CB320CF0_Out_2;
        Unity_Subtract_float(_Multiply_E6C7E894_Out_2, 0.5, _Subtract_CB320CF0_Out_2);
        float3 _Vector3_B2690115_Out_0 = float3(0, _Subtract_CB320CF0_Out_2, 0);
        float3 _Multiply_41CE0BCD_Out_2;
        Unity_Multiply_float(_Vector3_B2690115_Out_0, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                 length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                 length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_41CE0BCD_Out_2);
        float3 _Add_70153B10_Out_2;
        Unity_Add_float3(IN.WorldSpacePosition, _Multiply_41CE0BCD_Out_2, _Add_70153B10_Out_2);
        float3 _Transform_CB8C38CD_Out_1 = TransformWorldToObject(_Add_70153B10_Out_2.xyz);
        description.VertexPosition = _Transform_CB8C38CD_Out_1;
        description.VertexNormal = IN.ObjectSpaceNormal;
        description.VertexTangent = IN.ObjectSpaceTangent;
        return description;
    }
        
        // Graph Pixel
        struct SurfaceDescriptionInputs
    {
        float3 WorldSpacePosition;
        float4 ScreenPosition;
        float3 TimeParameters;
    };

    struct SurfaceDescription
    {
        float3 Color;
        float Alpha;
        float AlphaClipThreshold;
    };

    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
    {
        SurfaceDescription surface = (SurfaceDescription)0;
        float4 _Property_BF1DD5C4_Out_0 = Color_257B8E43;
        float4 _Property_733B8F03_Out_0 = Color_B7377AD5;
        float _Split_F309CB61_R_1 = IN.WorldSpacePosition[0];
        float _Split_F309CB61_G_2 = IN.WorldSpacePosition[1];
        float _Split_F309CB61_B_3 = IN.WorldSpacePosition[2];
        float _Split_F309CB61_A_4 = 0;
        float2 _Vector2_8B7C924E_Out_0 = float2(_Split_F309CB61_R_1, _Split_F309CB61_B_3);
        float _Property_D2C3A804_Out_0 = Vector1_A447B9B6;
        float _Multiply_9F85CD85_Out_2;
        Unity_Multiply_float(IN.TimeParameters.x, _Property_D2C3A804_Out_0, _Multiply_9F85CD85_Out_2);
        float _Multiply_DCF89CB0_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 0.5, _Multiply_DCF89CB0_Out_2);
        float2 _Add_9687392E_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_DCF89CB0_Out_2.xx), _Add_9687392E_Out_2);
        float _GradientNoise_F2890215_Out_2;
        Unity_GradientNoise_float(_Add_9687392E_Out_2, 0.1, _GradientNoise_F2890215_Out_2);
        float _Multiply_CF00AA9B_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 1, _Multiply_CF00AA9B_Out_2);
        float2 _Add_48217401_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_CF00AA9B_Out_2.xx), _Add_48217401_Out_2);
        float _SimpleNoise_53936C34_Out_2;
        Unity_SimpleNoise_float(_Add_48217401_Out_2, 1, _SimpleNoise_53936C34_Out_2);
        float _Add_D5BAEB31_Out_2;
        Unity_Add_float(_GradientNoise_F2890215_Out_2, _SimpleNoise_53936C34_Out_2, _Add_D5BAEB31_Out_2);
        float _Multiply_780EB22D_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 1.5, _Multiply_780EB22D_Out_2);
        float2 _Add_F29A1A2E_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_780EB22D_Out_2.xx), _Add_F29A1A2E_Out_2);
        float _SimpleNoise_8F785206_Out_2;
        Unity_SimpleNoise_float(_Add_F29A1A2E_Out_2, 0.5, _SimpleNoise_8F785206_Out_2);
        float _Multiply_E6C7E894_Out_2;
        Unity_Multiply_float(_Add_D5BAEB31_Out_2, _SimpleNoise_8F785206_Out_2, _Multiply_E6C7E894_Out_2);
        float _Saturate_E6B69F07_Out_1;
        Unity_Saturate_float(_Multiply_E6C7E894_Out_2, _Saturate_E6B69F07_Out_1);
        float4 _Lerp_A18C8176_Out_3;
        Unity_Lerp_float4(_Property_BF1DD5C4_Out_0, _Property_733B8F03_Out_0, (_Saturate_E6B69F07_Out_1.xxxx), _Lerp_A18C8176_Out_3);
        float _Property_EE1F0905_Out_0 = Vector1_D41015F0;
        float _Multiply_C348A1CC_Out_2;
        Unity_Multiply_float(_Property_EE1F0905_Out_0, 2, _Multiply_C348A1CC_Out_2);
        float _Property_76F232BE_Out_0 = Vector1_663379B8;
        float _Add_AA270530_Out_2;
        Unity_Add_float(_Multiply_C348A1CC_Out_2, _Property_76F232BE_Out_0, _Add_AA270530_Out_2);
        float _Smoothstep_E26AA1D8_Out_3;
        Unity_Smoothstep_float(_Property_EE1F0905_Out_0, _Add_AA270530_Out_2, _Multiply_E6C7E894_Out_2, _Smoothstep_E26AA1D8_Out_3);
        float _SceneDepth_5723FF7D_Out_1;
        Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_5723FF7D_Out_1);
        float4 _ScreenPosition_CCFCEAB1_Out_0 = IN.ScreenPosition;
        float _Split_26A4C201_R_1 = _ScreenPosition_CCFCEAB1_Out_0[0];
        float _Split_26A4C201_G_2 = _ScreenPosition_CCFCEAB1_Out_0[1];
        float _Split_26A4C201_B_3 = _ScreenPosition_CCFCEAB1_Out_0[2];
        float _Split_26A4C201_A_4 = _ScreenPosition_CCFCEAB1_Out_0[3];
        float _Subtract_1D97E587_Out_2;
        Unity_Subtract_float(_SceneDepth_5723FF7D_Out_1, _Split_26A4C201_A_4, _Subtract_1D97E587_Out_2);
        float _Property_EB3C5674_Out_0 = Vector1_BD222040;
        float _Multiply_10CF598E_Out_2;
        Unity_Multiply_float(_Subtract_1D97E587_Out_2, _Property_EB3C5674_Out_0, _Multiply_10CF598E_Out_2);
        float _Saturate_68F41048_Out_1;
        Unity_Saturate_float(_Multiply_10CF598E_Out_2, _Saturate_68F41048_Out_1);
        float _Multiply_911FF28B_Out_2;
        Unity_Multiply_float(_Smoothstep_E26AA1D8_Out_3, _Saturate_68F41048_Out_1, _Multiply_911FF28B_Out_2);
        surface.Color = (_Lerp_A18C8176_Out_3.xyz);
        surface.Alpha = _Multiply_911FF28B_Out_2;
        surface.AlphaClipThreshold = 0;
        return surface;
    }

        // --------------------------------------------------
        // Structs and Packing

        // Generated Type: Attributes
            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif
            };

        // Generated Type: Varyings
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Generated Type: PackedVaryings
            struct PackedVaryings
            {
                float4 positionCS : SV_POSITION;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                float3 interp00 : TEXCOORD0;
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Packed Type: Varyings
            PackedVaryings PackVaryings(Varyings input)
            {
                PackedVaryings output = (PackedVaryings)0;
                output.positionCS = input.positionCS;
                output.interp00.xyz = input.positionWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }
            
            // Unpacked Type: Varyings
            Varyings UnpackVaryings(PackedVaryings input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = input.positionCS;
                output.positionWS = input.interp00.xyz;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }

        // --------------------------------------------------
        // Build Graph Inputs

        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
    {
        VertexDescriptionInputs output;
        ZERO_INITIALIZE(VertexDescriptionInputs, output);

        output.ObjectSpaceNormal =           input.normalOS;
        output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
        output.ObjectSpaceTangent =          input.tangentOS;
        output.WorldSpaceTangent =           TransformObjectToWorldDir(input.tangentOS.xyz);
        output.ObjectSpaceBiTangent =        normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f) * GetOddNegativeScale());
        output.WorldSpaceBiTangent =         TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
        output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
        output.TimeParameters =              _TimeParameters.xyz;

        return output;
    }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
    {
        SurfaceDescriptionInputs output;
        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





        output.WorldSpacePosition =          input.positionWS;
        output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
    #else
    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
    #endif
    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

        return output;
    }

        // --------------------------------------------------
        // Main

        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/UnlitPass.hlsl"

        ENDHLSL
    }

        Pass
    {
        Name "ShadowCaster"
        Tags 
        { 
            "LightMode" = "ShadowCaster"
        }
       
        // Render State
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        Cull Back
        ZTest LEqual
        ZWrite On
        // ColorMask: <None>
        

        HLSLPROGRAM
        #pragma vertex vert
        #pragma fragment frag

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        // Pragmas
        #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0
    #pragma multi_compile_instancing

        // Keywords
        #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        // GraphKeywords: <None>
        
        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS 
        #define FEATURES_GRAPH_VERTEX
        #define SHADERPASS_SHADOWCASTER
    #define REQUIRE_DEPTH_TEXTURE

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"

        // --------------------------------------------------
        // Graph

        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
    float Vector1_A447B9B6;
    float4 Color_B7377AD5;
    float4 Color_257B8E43;
    float Vector1_D41015F0;
    float Vector1_663379B8;
    float Vector1_BD222040;
    CBUFFER_END

        // Graph Functions
        
    void Unity_Multiply_float(float A, float B, out float Out)
    {
        Out = A * B;
    }

    void Unity_Add_float2(float2 A, float2 B, out float2 Out)
    {
        Out = A + B;
    }


    float2 Unity_GradientNoise_Dir_float(float2 p)
    {
        // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
        p = p % 289;
        float x = (34 * p.x + 1) * p.x % 289 + p.y;
        x = (34 * x + 1) * x % 289;
        x = frac(x / 41) * 2 - 1;
        return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
    }

    void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
    { 
        float2 p = UV * Scale;
        float2 ip = floor(p);
        float2 fp = frac(p);
        float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
        float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
        float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
        float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
        fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
        Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
    }


    inline float Unity_SimpleNoise_RandomValue_float (float2 uv)
    {
        return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
    }

    inline float Unity_SimpleNnoise_Interpolate_float (float a, float b, float t)
    {
        return (1.0-t)*a + (t*b);
    }


    inline float Unity_SimpleNoise_ValueNoise_float (float2 uv)
    {
        float2 i = floor(uv);
        float2 f = frac(uv);
        f = f * f * (3.0 - 2.0 * f);

        uv = abs(frac(uv) - 0.5);
        float2 c0 = i + float2(0.0, 0.0);
        float2 c1 = i + float2(1.0, 0.0);
        float2 c2 = i + float2(0.0, 1.0);
        float2 c3 = i + float2(1.0, 1.0);
        float r0 = Unity_SimpleNoise_RandomValue_float(c0);
        float r1 = Unity_SimpleNoise_RandomValue_float(c1);
        float r2 = Unity_SimpleNoise_RandomValue_float(c2);
        float r3 = Unity_SimpleNoise_RandomValue_float(c3);

        float bottomOfGrid = Unity_SimpleNnoise_Interpolate_float(r0, r1, f.x);
        float topOfGrid = Unity_SimpleNnoise_Interpolate_float(r2, r3, f.x);
        float t = Unity_SimpleNnoise_Interpolate_float(bottomOfGrid, topOfGrid, f.y);
        return t;
    }
    void Unity_SimpleNoise_float(float2 UV, float Scale, out float Out)
    {
        float t = 0.0;

        float freq = pow(2.0, float(0));
        float amp = pow(0.5, float(3-0));
        t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

        freq = pow(2.0, float(1));
        amp = pow(0.5, float(3-1));
        t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

        freq = pow(2.0, float(2));
        amp = pow(0.5, float(3-2));
        t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

        Out = t;
    }

    void Unity_Add_float(float A, float B, out float Out)
    {
        Out = A + B;
    }

    void Unity_Subtract_float(float A, float B, out float Out)
    {
        Out = A - B;
    }

    void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
    {
        Out = A * B;
    }

    void Unity_Add_float3(float3 A, float3 B, out float3 Out)
    {
        Out = A + B;
    }

    void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
    {
        Out = smoothstep(Edge1, Edge2, In);
    }

    void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
    {
        Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
    }

    void Unity_Saturate_float(float In, out float Out)
    {
        Out = saturate(In);
    }

        // Graph Vertex
        struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 WorldSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 WorldSpaceTangent;
        float3 ObjectSpaceBiTangent;
        float3 WorldSpaceBiTangent;
        float3 WorldSpacePosition;
        float3 TimeParameters;
    };

    struct VertexDescription
    {
        float3 VertexPosition;
        float3 VertexNormal;
        float3 VertexTangent;
    };

    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
    {
        VertexDescription description = (VertexDescription)0;
        float _Split_F309CB61_R_1 = IN.WorldSpacePosition[0];
        float _Split_F309CB61_G_2 = IN.WorldSpacePosition[1];
        float _Split_F309CB61_B_3 = IN.WorldSpacePosition[2];
        float _Split_F309CB61_A_4 = 0;
        float2 _Vector2_8B7C924E_Out_0 = float2(_Split_F309CB61_R_1, _Split_F309CB61_B_3);
        float _Property_D2C3A804_Out_0 = Vector1_A447B9B6;
        float _Multiply_9F85CD85_Out_2;
        Unity_Multiply_float(IN.TimeParameters.x, _Property_D2C3A804_Out_0, _Multiply_9F85CD85_Out_2);
        float _Multiply_DCF89CB0_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 0.5, _Multiply_DCF89CB0_Out_2);
        float2 _Add_9687392E_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_DCF89CB0_Out_2.xx), _Add_9687392E_Out_2);
        float _GradientNoise_F2890215_Out_2;
        Unity_GradientNoise_float(_Add_9687392E_Out_2, 0.1, _GradientNoise_F2890215_Out_2);
        float _Multiply_CF00AA9B_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 1, _Multiply_CF00AA9B_Out_2);
        float2 _Add_48217401_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_CF00AA9B_Out_2.xx), _Add_48217401_Out_2);
        float _SimpleNoise_53936C34_Out_2;
        Unity_SimpleNoise_float(_Add_48217401_Out_2, 1, _SimpleNoise_53936C34_Out_2);
        float _Add_D5BAEB31_Out_2;
        Unity_Add_float(_GradientNoise_F2890215_Out_2, _SimpleNoise_53936C34_Out_2, _Add_D5BAEB31_Out_2);
        float _Multiply_780EB22D_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 1.5, _Multiply_780EB22D_Out_2);
        float2 _Add_F29A1A2E_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_780EB22D_Out_2.xx), _Add_F29A1A2E_Out_2);
        float _SimpleNoise_8F785206_Out_2;
        Unity_SimpleNoise_float(_Add_F29A1A2E_Out_2, 0.5, _SimpleNoise_8F785206_Out_2);
        float _Multiply_E6C7E894_Out_2;
        Unity_Multiply_float(_Add_D5BAEB31_Out_2, _SimpleNoise_8F785206_Out_2, _Multiply_E6C7E894_Out_2);
        float _Subtract_CB320CF0_Out_2;
        Unity_Subtract_float(_Multiply_E6C7E894_Out_2, 0.5, _Subtract_CB320CF0_Out_2);
        float3 _Vector3_B2690115_Out_0 = float3(0, _Subtract_CB320CF0_Out_2, 0);
        float3 _Multiply_41CE0BCD_Out_2;
        Unity_Multiply_float(_Vector3_B2690115_Out_0, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                 length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                 length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_41CE0BCD_Out_2);
        float3 _Add_70153B10_Out_2;
        Unity_Add_float3(IN.WorldSpacePosition, _Multiply_41CE0BCD_Out_2, _Add_70153B10_Out_2);
        float3 _Transform_CB8C38CD_Out_1 = TransformWorldToObject(_Add_70153B10_Out_2.xyz);
        description.VertexPosition = _Transform_CB8C38CD_Out_1;
        description.VertexNormal = IN.ObjectSpaceNormal;
        description.VertexTangent = IN.ObjectSpaceTangent;
        return description;
    }
        
        // Graph Pixel
        struct SurfaceDescriptionInputs
    {
        float3 WorldSpacePosition;
        float4 ScreenPosition;
        float3 TimeParameters;
    };

    struct SurfaceDescription
    {
        float Alpha;
        float AlphaClipThreshold;
    };

    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
    {
        SurfaceDescription surface = (SurfaceDescription)0;
        float _Property_EE1F0905_Out_0 = Vector1_D41015F0;
        float _Multiply_C348A1CC_Out_2;
        Unity_Multiply_float(_Property_EE1F0905_Out_0, 2, _Multiply_C348A1CC_Out_2);
        float _Property_76F232BE_Out_0 = Vector1_663379B8;
        float _Add_AA270530_Out_2;
        Unity_Add_float(_Multiply_C348A1CC_Out_2, _Property_76F232BE_Out_0, _Add_AA270530_Out_2);
        float _Split_F309CB61_R_1 = IN.WorldSpacePosition[0];
        float _Split_F309CB61_G_2 = IN.WorldSpacePosition[1];
        float _Split_F309CB61_B_3 = IN.WorldSpacePosition[2];
        float _Split_F309CB61_A_4 = 0;
        float2 _Vector2_8B7C924E_Out_0 = float2(_Split_F309CB61_R_1, _Split_F309CB61_B_3);
        float _Property_D2C3A804_Out_0 = Vector1_A447B9B6;
        float _Multiply_9F85CD85_Out_2;
        Unity_Multiply_float(IN.TimeParameters.x, _Property_D2C3A804_Out_0, _Multiply_9F85CD85_Out_2);
        float _Multiply_DCF89CB0_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 0.5, _Multiply_DCF89CB0_Out_2);
        float2 _Add_9687392E_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_DCF89CB0_Out_2.xx), _Add_9687392E_Out_2);
        float _GradientNoise_F2890215_Out_2;
        Unity_GradientNoise_float(_Add_9687392E_Out_2, 0.1, _GradientNoise_F2890215_Out_2);
        float _Multiply_CF00AA9B_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 1, _Multiply_CF00AA9B_Out_2);
        float2 _Add_48217401_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_CF00AA9B_Out_2.xx), _Add_48217401_Out_2);
        float _SimpleNoise_53936C34_Out_2;
        Unity_SimpleNoise_float(_Add_48217401_Out_2, 1, _SimpleNoise_53936C34_Out_2);
        float _Add_D5BAEB31_Out_2;
        Unity_Add_float(_GradientNoise_F2890215_Out_2, _SimpleNoise_53936C34_Out_2, _Add_D5BAEB31_Out_2);
        float _Multiply_780EB22D_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 1.5, _Multiply_780EB22D_Out_2);
        float2 _Add_F29A1A2E_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_780EB22D_Out_2.xx), _Add_F29A1A2E_Out_2);
        float _SimpleNoise_8F785206_Out_2;
        Unity_SimpleNoise_float(_Add_F29A1A2E_Out_2, 0.5, _SimpleNoise_8F785206_Out_2);
        float _Multiply_E6C7E894_Out_2;
        Unity_Multiply_float(_Add_D5BAEB31_Out_2, _SimpleNoise_8F785206_Out_2, _Multiply_E6C7E894_Out_2);
        float _Smoothstep_E26AA1D8_Out_3;
        Unity_Smoothstep_float(_Property_EE1F0905_Out_0, _Add_AA270530_Out_2, _Multiply_E6C7E894_Out_2, _Smoothstep_E26AA1D8_Out_3);
        float _SceneDepth_5723FF7D_Out_1;
        Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_5723FF7D_Out_1);
        float4 _ScreenPosition_CCFCEAB1_Out_0 = IN.ScreenPosition;
        float _Split_26A4C201_R_1 = _ScreenPosition_CCFCEAB1_Out_0[0];
        float _Split_26A4C201_G_2 = _ScreenPosition_CCFCEAB1_Out_0[1];
        float _Split_26A4C201_B_3 = _ScreenPosition_CCFCEAB1_Out_0[2];
        float _Split_26A4C201_A_4 = _ScreenPosition_CCFCEAB1_Out_0[3];
        float _Subtract_1D97E587_Out_2;
        Unity_Subtract_float(_SceneDepth_5723FF7D_Out_1, _Split_26A4C201_A_4, _Subtract_1D97E587_Out_2);
        float _Property_EB3C5674_Out_0 = Vector1_BD222040;
        float _Multiply_10CF598E_Out_2;
        Unity_Multiply_float(_Subtract_1D97E587_Out_2, _Property_EB3C5674_Out_0, _Multiply_10CF598E_Out_2);
        float _Saturate_68F41048_Out_1;
        Unity_Saturate_float(_Multiply_10CF598E_Out_2, _Saturate_68F41048_Out_1);
        float _Multiply_911FF28B_Out_2;
        Unity_Multiply_float(_Smoothstep_E26AA1D8_Out_3, _Saturate_68F41048_Out_1, _Multiply_911FF28B_Out_2);
        surface.Alpha = _Multiply_911FF28B_Out_2;
        surface.AlphaClipThreshold = 0;
        return surface;
    }

        // --------------------------------------------------
        // Structs and Packing

        // Generated Type: Attributes
            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif
            };

        // Generated Type: Varyings
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Generated Type: PackedVaryings
            struct PackedVaryings
            {
                float4 positionCS : SV_POSITION;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                float3 interp00 : TEXCOORD0;
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Packed Type: Varyings
            PackedVaryings PackVaryings(Varyings input)
            {
                PackedVaryings output = (PackedVaryings)0;
                output.positionCS = input.positionCS;
                output.interp00.xyz = input.positionWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }
            
            // Unpacked Type: Varyings
            Varyings UnpackVaryings(PackedVaryings input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = input.positionCS;
                output.positionWS = input.interp00.xyz;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }

        // --------------------------------------------------
        // Build Graph Inputs

        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
    {
        VertexDescriptionInputs output;
        ZERO_INITIALIZE(VertexDescriptionInputs, output);

        output.ObjectSpaceNormal =           input.normalOS;
        output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
        output.ObjectSpaceTangent =          input.tangentOS;
        output.WorldSpaceTangent =           TransformObjectToWorldDir(input.tangentOS.xyz);
        output.ObjectSpaceBiTangent =        normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f) * GetOddNegativeScale());
        output.WorldSpaceBiTangent =         TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
        output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
        output.TimeParameters =              _TimeParameters.xyz;

        return output;
    }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
    {
        SurfaceDescriptionInputs output;
        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





        output.WorldSpacePosition =          input.positionWS;
        output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
    #else
    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
    #endif
    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

        return output;
    }

        // --------------------------------------------------
        // Main

        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

        ENDHLSL
    }

        Pass
    {
        Name "DepthOnly"
        Tags 
        { 
            "LightMode" = "DepthOnly"
        }
       
        // Render State
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        Cull Back
        ZTest LEqual
        ZWrite On
        ColorMask 0
        

        HLSLPROGRAM
        #pragma vertex vert
        #pragma fragment frag

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        // Pragmas
        #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0
    #pragma multi_compile_instancing

        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS 
        #define FEATURES_GRAPH_VERTEX
        #define SHADERPASS_DEPTHONLY
    #define REQUIRE_DEPTH_TEXTURE

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"

        // --------------------------------------------------
        // Graph

        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
    float Vector1_A447B9B6;
    float4 Color_B7377AD5;
    float4 Color_257B8E43;
    float Vector1_D41015F0;
    float Vector1_663379B8;
    float Vector1_BD222040;
    CBUFFER_END

        // Graph Functions
        
    void Unity_Multiply_float(float A, float B, out float Out)
    {
        Out = A * B;
    }

    void Unity_Add_float2(float2 A, float2 B, out float2 Out)
    {
        Out = A + B;
    }


    float2 Unity_GradientNoise_Dir_float(float2 p)
    {
        // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
        p = p % 289;
        float x = (34 * p.x + 1) * p.x % 289 + p.y;
        x = (34 * x + 1) * x % 289;
        x = frac(x / 41) * 2 - 1;
        return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
    }

    void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
    { 
        float2 p = UV * Scale;
        float2 ip = floor(p);
        float2 fp = frac(p);
        float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
        float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
        float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
        float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
        fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
        Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
    }


    inline float Unity_SimpleNoise_RandomValue_float (float2 uv)
    {
        return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
    }

    inline float Unity_SimpleNnoise_Interpolate_float (float a, float b, float t)
    {
        return (1.0-t)*a + (t*b);
    }


    inline float Unity_SimpleNoise_ValueNoise_float (float2 uv)
    {
        float2 i = floor(uv);
        float2 f = frac(uv);
        f = f * f * (3.0 - 2.0 * f);

        uv = abs(frac(uv) - 0.5);
        float2 c0 = i + float2(0.0, 0.0);
        float2 c1 = i + float2(1.0, 0.0);
        float2 c2 = i + float2(0.0, 1.0);
        float2 c3 = i + float2(1.0, 1.0);
        float r0 = Unity_SimpleNoise_RandomValue_float(c0);
        float r1 = Unity_SimpleNoise_RandomValue_float(c1);
        float r2 = Unity_SimpleNoise_RandomValue_float(c2);
        float r3 = Unity_SimpleNoise_RandomValue_float(c3);

        float bottomOfGrid = Unity_SimpleNnoise_Interpolate_float(r0, r1, f.x);
        float topOfGrid = Unity_SimpleNnoise_Interpolate_float(r2, r3, f.x);
        float t = Unity_SimpleNnoise_Interpolate_float(bottomOfGrid, topOfGrid, f.y);
        return t;
    }
    void Unity_SimpleNoise_float(float2 UV, float Scale, out float Out)
    {
        float t = 0.0;

        float freq = pow(2.0, float(0));
        float amp = pow(0.5, float(3-0));
        t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

        freq = pow(2.0, float(1));
        amp = pow(0.5, float(3-1));
        t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

        freq = pow(2.0, float(2));
        amp = pow(0.5, float(3-2));
        t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

        Out = t;
    }

    void Unity_Add_float(float A, float B, out float Out)
    {
        Out = A + B;
    }

    void Unity_Subtract_float(float A, float B, out float Out)
    {
        Out = A - B;
    }

    void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
    {
        Out = A * B;
    }

    void Unity_Add_float3(float3 A, float3 B, out float3 Out)
    {
        Out = A + B;
    }

    void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
    {
        Out = smoothstep(Edge1, Edge2, In);
    }

    void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
    {
        Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
    }

    void Unity_Saturate_float(float In, out float Out)
    {
        Out = saturate(In);
    }

        // Graph Vertex
        struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 WorldSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 WorldSpaceTangent;
        float3 ObjectSpaceBiTangent;
        float3 WorldSpaceBiTangent;
        float3 WorldSpacePosition;
        float3 TimeParameters;
    };

    struct VertexDescription
    {
        float3 VertexPosition;
        float3 VertexNormal;
        float3 VertexTangent;
    };

    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
    {
        VertexDescription description = (VertexDescription)0;
        float _Split_F309CB61_R_1 = IN.WorldSpacePosition[0];
        float _Split_F309CB61_G_2 = IN.WorldSpacePosition[1];
        float _Split_F309CB61_B_3 = IN.WorldSpacePosition[2];
        float _Split_F309CB61_A_4 = 0;
        float2 _Vector2_8B7C924E_Out_0 = float2(_Split_F309CB61_R_1, _Split_F309CB61_B_3);
        float _Property_D2C3A804_Out_0 = Vector1_A447B9B6;
        float _Multiply_9F85CD85_Out_2;
        Unity_Multiply_float(IN.TimeParameters.x, _Property_D2C3A804_Out_0, _Multiply_9F85CD85_Out_2);
        float _Multiply_DCF89CB0_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 0.5, _Multiply_DCF89CB0_Out_2);
        float2 _Add_9687392E_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_DCF89CB0_Out_2.xx), _Add_9687392E_Out_2);
        float _GradientNoise_F2890215_Out_2;
        Unity_GradientNoise_float(_Add_9687392E_Out_2, 0.1, _GradientNoise_F2890215_Out_2);
        float _Multiply_CF00AA9B_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 1, _Multiply_CF00AA9B_Out_2);
        float2 _Add_48217401_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_CF00AA9B_Out_2.xx), _Add_48217401_Out_2);
        float _SimpleNoise_53936C34_Out_2;
        Unity_SimpleNoise_float(_Add_48217401_Out_2, 1, _SimpleNoise_53936C34_Out_2);
        float _Add_D5BAEB31_Out_2;
        Unity_Add_float(_GradientNoise_F2890215_Out_2, _SimpleNoise_53936C34_Out_2, _Add_D5BAEB31_Out_2);
        float _Multiply_780EB22D_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 1.5, _Multiply_780EB22D_Out_2);
        float2 _Add_F29A1A2E_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_780EB22D_Out_2.xx), _Add_F29A1A2E_Out_2);
        float _SimpleNoise_8F785206_Out_2;
        Unity_SimpleNoise_float(_Add_F29A1A2E_Out_2, 0.5, _SimpleNoise_8F785206_Out_2);
        float _Multiply_E6C7E894_Out_2;
        Unity_Multiply_float(_Add_D5BAEB31_Out_2, _SimpleNoise_8F785206_Out_2, _Multiply_E6C7E894_Out_2);
        float _Subtract_CB320CF0_Out_2;
        Unity_Subtract_float(_Multiply_E6C7E894_Out_2, 0.5, _Subtract_CB320CF0_Out_2);
        float3 _Vector3_B2690115_Out_0 = float3(0, _Subtract_CB320CF0_Out_2, 0);
        float3 _Multiply_41CE0BCD_Out_2;
        Unity_Multiply_float(_Vector3_B2690115_Out_0, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                 length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                 length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_41CE0BCD_Out_2);
        float3 _Add_70153B10_Out_2;
        Unity_Add_float3(IN.WorldSpacePosition, _Multiply_41CE0BCD_Out_2, _Add_70153B10_Out_2);
        float3 _Transform_CB8C38CD_Out_1 = TransformWorldToObject(_Add_70153B10_Out_2.xyz);
        description.VertexPosition = _Transform_CB8C38CD_Out_1;
        description.VertexNormal = IN.ObjectSpaceNormal;
        description.VertexTangent = IN.ObjectSpaceTangent;
        return description;
    }
        
        // Graph Pixel
        struct SurfaceDescriptionInputs
    {
        float3 WorldSpacePosition;
        float4 ScreenPosition;
        float3 TimeParameters;
    };

    struct SurfaceDescription
    {
        float Alpha;
        float AlphaClipThreshold;
    };

    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
    {
        SurfaceDescription surface = (SurfaceDescription)0;
        float _Property_EE1F0905_Out_0 = Vector1_D41015F0;
        float _Multiply_C348A1CC_Out_2;
        Unity_Multiply_float(_Property_EE1F0905_Out_0, 2, _Multiply_C348A1CC_Out_2);
        float _Property_76F232BE_Out_0 = Vector1_663379B8;
        float _Add_AA270530_Out_2;
        Unity_Add_float(_Multiply_C348A1CC_Out_2, _Property_76F232BE_Out_0, _Add_AA270530_Out_2);
        float _Split_F309CB61_R_1 = IN.WorldSpacePosition[0];
        float _Split_F309CB61_G_2 = IN.WorldSpacePosition[1];
        float _Split_F309CB61_B_3 = IN.WorldSpacePosition[2];
        float _Split_F309CB61_A_4 = 0;
        float2 _Vector2_8B7C924E_Out_0 = float2(_Split_F309CB61_R_1, _Split_F309CB61_B_3);
        float _Property_D2C3A804_Out_0 = Vector1_A447B9B6;
        float _Multiply_9F85CD85_Out_2;
        Unity_Multiply_float(IN.TimeParameters.x, _Property_D2C3A804_Out_0, _Multiply_9F85CD85_Out_2);
        float _Multiply_DCF89CB0_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 0.5, _Multiply_DCF89CB0_Out_2);
        float2 _Add_9687392E_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_DCF89CB0_Out_2.xx), _Add_9687392E_Out_2);
        float _GradientNoise_F2890215_Out_2;
        Unity_GradientNoise_float(_Add_9687392E_Out_2, 0.1, _GradientNoise_F2890215_Out_2);
        float _Multiply_CF00AA9B_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 1, _Multiply_CF00AA9B_Out_2);
        float2 _Add_48217401_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_CF00AA9B_Out_2.xx), _Add_48217401_Out_2);
        float _SimpleNoise_53936C34_Out_2;
        Unity_SimpleNoise_float(_Add_48217401_Out_2, 1, _SimpleNoise_53936C34_Out_2);
        float _Add_D5BAEB31_Out_2;
        Unity_Add_float(_GradientNoise_F2890215_Out_2, _SimpleNoise_53936C34_Out_2, _Add_D5BAEB31_Out_2);
        float _Multiply_780EB22D_Out_2;
        Unity_Multiply_float(_Multiply_9F85CD85_Out_2, 1.5, _Multiply_780EB22D_Out_2);
        float2 _Add_F29A1A2E_Out_2;
        Unity_Add_float2(_Vector2_8B7C924E_Out_0, (_Multiply_780EB22D_Out_2.xx), _Add_F29A1A2E_Out_2);
        float _SimpleNoise_8F785206_Out_2;
        Unity_SimpleNoise_float(_Add_F29A1A2E_Out_2, 0.5, _SimpleNoise_8F785206_Out_2);
        float _Multiply_E6C7E894_Out_2;
        Unity_Multiply_float(_Add_D5BAEB31_Out_2, _SimpleNoise_8F785206_Out_2, _Multiply_E6C7E894_Out_2);
        float _Smoothstep_E26AA1D8_Out_3;
        Unity_Smoothstep_float(_Property_EE1F0905_Out_0, _Add_AA270530_Out_2, _Multiply_E6C7E894_Out_2, _Smoothstep_E26AA1D8_Out_3);
        float _SceneDepth_5723FF7D_Out_1;
        Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_5723FF7D_Out_1);
        float4 _ScreenPosition_CCFCEAB1_Out_0 = IN.ScreenPosition;
        float _Split_26A4C201_R_1 = _ScreenPosition_CCFCEAB1_Out_0[0];
        float _Split_26A4C201_G_2 = _ScreenPosition_CCFCEAB1_Out_0[1];
        float _Split_26A4C201_B_3 = _ScreenPosition_CCFCEAB1_Out_0[2];
        float _Split_26A4C201_A_4 = _ScreenPosition_CCFCEAB1_Out_0[3];
        float _Subtract_1D97E587_Out_2;
        Unity_Subtract_float(_SceneDepth_5723FF7D_Out_1, _Split_26A4C201_A_4, _Subtract_1D97E587_Out_2);
        float _Property_EB3C5674_Out_0 = Vector1_BD222040;
        float _Multiply_10CF598E_Out_2;
        Unity_Multiply_float(_Subtract_1D97E587_Out_2, _Property_EB3C5674_Out_0, _Multiply_10CF598E_Out_2);
        float _Saturate_68F41048_Out_1;
        Unity_Saturate_float(_Multiply_10CF598E_Out_2, _Saturate_68F41048_Out_1);
        float _Multiply_911FF28B_Out_2;
        Unity_Multiply_float(_Smoothstep_E26AA1D8_Out_3, _Saturate_68F41048_Out_1, _Multiply_911FF28B_Out_2);
        surface.Alpha = _Multiply_911FF28B_Out_2;
        surface.AlphaClipThreshold = 0;
        return surface;
    }

        // --------------------------------------------------
        // Structs and Packing

        // Generated Type: Attributes
            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif
            };

        // Generated Type: Varyings
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Generated Type: PackedVaryings
            struct PackedVaryings
            {
                float4 positionCS : SV_POSITION;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                float3 interp00 : TEXCOORD0;
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Packed Type: Varyings
            PackedVaryings PackVaryings(Varyings input)
            {
                PackedVaryings output = (PackedVaryings)0;
                output.positionCS = input.positionCS;
                output.interp00.xyz = input.positionWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }
            
            // Unpacked Type: Varyings
            Varyings UnpackVaryings(PackedVaryings input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = input.positionCS;
                output.positionWS = input.interp00.xyz;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }

        // --------------------------------------------------
        // Build Graph Inputs

        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
    {
        VertexDescriptionInputs output;
        ZERO_INITIALIZE(VertexDescriptionInputs, output);

        output.ObjectSpaceNormal =           input.normalOS;
        output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
        output.ObjectSpaceTangent =          input.tangentOS;
        output.WorldSpaceTangent =           TransformObjectToWorldDir(input.tangentOS.xyz);
        output.ObjectSpaceBiTangent =        normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f) * GetOddNegativeScale());
        output.WorldSpaceBiTangent =         TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
        output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
        output.TimeParameters =              _TimeParameters.xyz;

        return output;
    }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
    {
        SurfaceDescriptionInputs output;
        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





        output.WorldSpacePosition =          input.positionWS;
        output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
    #else
    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
    #endif
    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

        return output;
    }

        // --------------------------------------------------
        // Main

        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

        ENDHLSL
    }

    }
    FallBack "Hidden/Shader Graph/FallbackError"
}
