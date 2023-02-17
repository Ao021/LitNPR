Shader "Custom/Outlines"
{
    Properties
    {
        [Enum(depth,0, normals,1,opaques,2,all,3)] _Type("type",float) = 0
        [HDR]_Col("color",color) = (1,1,1,1)
        _Thick("thick",float) = 1
        _Lerp("Lerp",range(0,1)) = 1
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline"}
        
        Pass
        {
            
            Name "NdotV"
           Tags{"LightMode" = "Test1"}
            Blend one one
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal : Normal;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS: TEXCOORD2;
                float4 vertex : SV_POSITION;
            };


            
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_BlitPassTexture); SAMPLER(sampler_BlitPassTexture);
            float4 _MainTex_ST,_Col;
            float _Type,_Thick;


            
            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs input = GetVertexPositionInputs(v.vertex);
                o.positionWS = input.positionWS;
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                o.vertex = TransformWorldToHClip(o.positionWS);
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = 1;
                float3 NdotV = max( 0,
                                    dot(i.normalWS,normalize(_WorldSpaceCameraPos-i.positionWS)));
                col.rgb = _Col * step(0.5,pow(1-NdotV,_Thick));
                return col;
            }
            ENDHLSL
        }
        
        Pass
        {
            Name "Normals"
            cull front
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal : Normal;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS: TEXCOORD2;
                float4 vertex : SV_POSITION;
            };


            
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_BlitPassTexture); SAMPLER(sampler_BlitPassTexture);
            float4 _MainTex_ST,_Col;
            float _Type,_Thick,_Lerp;


            
            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs input = GetVertexPositionInputs(v.vertex);
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                float3 sphereNormal = normalize(input.positionWS - TransformObjectToWorld(0));
                o.positionWS = input.positionWS + _Thick* 0.001 * lerp(o.normalWS,sphereNormal,_Lerp);    //o.normalWS;
                o.vertex = TransformWorldToHClip(o.positionWS);
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = 1;
                return _Col;
            }
            ENDHLSL
        }
        
        Pass
        {
            Name "ClipNormals"
            cull front
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal : Normal;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS: TEXCOORD2;
                float4 vertex : SV_POSITION;
            };


            
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_BlitPassTexture); SAMPLER(sampler_BlitPassTexture);
            float4 _MainTex_ST,_Col;
            float _Type,_Thick,_Lerp;


            
            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs input = GetVertexPositionInputs(v.vertex);
                o.positionWS = input.positionWS;
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                float3 sphereNormal = normalize(input.positionWS - TransformObjectToWorld(0));
                //o.positionWS = input.positionWS + _Thick*sphereNormal;
                
                //o.positionWS = input.positionWS + _Thick* lerp(o.normalWS,sphereNormal,_Lerp);    //o.normalWS;
                o.vertex = TransformWorldToHClip(o.positionWS);
                o.vertex.xy += _Thick* TransformWorldToHClipDir(lerp(o.normalWS,sphereNormal,_Lerp),true).xy/_ScreenParams.xy * o.vertex.w*2;
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = 1;
                return _Col;
            }
            ENDHLSL
        }

        Pass
        {
            Name "Sobel"
            HLSLPROGRAM
            #pragma vertex vert
			#pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

            TEXTURE2D(_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);float4 _CameraDepthTexture_TexelSize;
            TEXTURE2D(_CameraNormalsTexture);SAMPLER(sampler_CameraNormalsTexture);float4 _CameraNormalsTexture_TexelSize;
            float _Thick,_Type;
            half4 _Col;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                float2 uv[9] : TEXCOORD0;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;
                output.uv[0] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(-1, -1) * _Thick;
                output.uv[1] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(0, -1) * _Thick;
                output.uv[2] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(1, -1) * _Thick;
                output.uv[3] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(-1, 0) * _Thick;
                output.uv[4] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(0, 0) * _Thick;
                output.uv[5] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(1, 0) * _Thick;
                output.uv[6] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(-1, 1) * _Thick;
                output.uv[7] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(0, 1) * _Thick;
                output.uv[8] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(1, 1) * _Thick;
                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                const half Gx[9] = {
                    -1,  0,  1,
                    -2,  0,  2,
                    -1,  0,  1
                };

                const half Gy[9] = {
                    -1, -2, -1,
                    0,  0,  0,
                    1,  2,  1
                };

                
                float edgeY = 0;
                float edgeX = 0;    
                float luminance = 0;

                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[4]);

                for (int i = 0; i < 9; i++) {
                    float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, input.uv[i]);
                    float normals = SAMPLE_DEPTH_TEXTURE(_CameraNormalsTexture, sampler_CameraNormalsTexture, input.uv[i]);
                    float opaque = SAMPLE_DEPTH_TEXTURE(_MainTex, sampler_MainTex, input.uv[i]);

                    if(_Type == 0)luminance = LinearEyeDepth(depth, _ZBufferParams) * 0.1;
                    if(_Type == 1)luminance = normals*0.5;
                    if(_Type == 2)luminance = opaque*0.3;
                    if(_Type == 3)luminance = max(max(LinearEyeDepth(depth, _ZBufferParams) * 0.1,normals*0.5), opaque*0.5);
                    edgeX += luminance * Gx[i];
                    edgeY += luminance * Gy[i];
                }
                
                float edge = (1 - abs(edgeX) - abs(edgeY));
                edge = saturate(edge);

                return lerp(_Col * color, color, edge);
            }

            ENDHLSL
        }
        


        Pass
        {
            Name "Blurs"
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_Blur);SAMPLER(sampler_Blur);
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.vertex= TransformObjectToHClip(input.positionOS);
                output.uv = input.uv;
                return output;
            }

            float _Thick; float4 _Col;
            float4 frag (Varyings input) : SV_Target
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                float2 uv = input.uv;
                float4 col = float4(0,0,0,0);
                col += 0.060 * SAMPLE_TEXTURE2D(_Blur, sampler_Blur, uv + float2(-1,-1)*_ScreenSize.zw*_Thick);
                col += 0.098 * SAMPLE_TEXTURE2D(_Blur, sampler_Blur, uv + float2(0,-1)*_ScreenSize.zw*_Thick);
                col += 0.060 * SAMPLE_TEXTURE2D(_Blur, sampler_Blur, uv + float2(1,-1)*_ScreenSize.zw*_Thick);
                col += 0.098 * SAMPLE_TEXTURE2D(_Blur, sampler_Blur, uv + float2(-1,0)*_ScreenSize.zw*_Thick);
                col += 0.162 * SAMPLE_TEXTURE2D(_Blur, sampler_Blur, uv);
                col += 0.098 * SAMPLE_TEXTURE2D(_Blur, sampler_Blur, uv + float2(1,0)*_ScreenSize.zw*_Thick);
                col += 0.060 * SAMPLE_TEXTURE2D(_Blur, sampler_Blur, uv + float2(1,-1)*_ScreenSize.zw*_Thick);
                col += 0.022 * SAMPLE_TEXTURE2D(_Blur, sampler_Blur, uv + float2(1,0)*_ScreenSize.zw*_Thick);
                col += 0.060 * SAMPLE_TEXTURE2D(_Blur, sampler_Blur, uv + float2(1,1)*_ScreenSize.zw*_Thick);
                float3 base = SAMPLE_TEXTURE2D(_Blur, sampler_Blur, uv);
                col = _Col*step(0.1,col.r-base.r);
                return tex+col;
            }
            ENDHLSL
        }
        
        
        
        Pass
        {
            Name "Blurs"
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_Texture);SAMPLER(sampler_Texture);
            TEXTURE2D(_Buffer2);SAMPLER(sampler_Buffer2);
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.vertex= TransformObjectToHClip(input.positionOS);
                output.uv = input.uv;
                return output;
            }

            float _Thick; float4 _Col;
            float4 frag (Varyings input) : SV_Target
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                half4 tex2 = SAMPLE_TEXTURE2D(_Buffer2, sampler_Buffer2, input.uv);
                half4 tex3 = SAMPLE_TEXTURE2D(_Texture, sampler_Texture, input.uv);
                if(step(_Thick*0.1,tex2.r+tex3.r)<0.5) tex.rgb = _Col;
                return tex;
            }
            ENDHLSL
        }
    }
}
