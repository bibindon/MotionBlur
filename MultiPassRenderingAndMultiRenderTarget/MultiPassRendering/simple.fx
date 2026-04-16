float4x4 g_matWorldViewProj;
float4x4 g_matPrevWorldViewProj;

bool g_bUseTexture = true;

texture texture1;
sampler textureSampler = sampler_state
{
    Texture = (texture1);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

void VertexShader1(
    in float4 inPosition : POSITION,
    in float3 inNormal : NORMAL,
    in float2 inTexCoord0 : TEXCOORD0,
    out float4 outPosition : POSITION0,
    out float2 outTexCoord0 : TEXCOORD0,
    out float4 outCurrentClip : TEXCOORD1,
    out float4 outPrevClip : TEXCOORD2)
{
    float4 currentClip = mul(inPosition, g_matWorldViewProj);
    float4 prevClip = mul(inPosition, g_matPrevWorldViewProj);

    outPosition = currentClip;
    outTexCoord0 = inTexCoord0;
    outCurrentClip = currentClip;
    outPrevClip = prevClip;
}

void PixelShaderMRT(
    in float2 inTexCoord0 : TEXCOORD0,
    in float4 inCurrentClip : TEXCOORD1,
    in float4 inPrevClip : TEXCOORD2,
    out float4 outColor0 : COLOR0,
    out float4 outColor1 : COLOR1)
{
    float4 baseColor = float4(0.5, 0.5, 0.5, 1.0);
    if (g_bUseTexture)
    {
        baseColor = tex2D(textureSampler, inTexCoord0);
    }

    float2 currentNdc = inCurrentClip.xy / max(inCurrentClip.w, 0.0001f);
    float2 prevNdc = inPrevClip.xy / max(inPrevClip.w, 0.0001f);

    float2 currentUv = float2(currentNdc.x * 0.5f + 0.5f, -currentNdc.y * 0.5f + 0.5f);
    float2 prevUv = float2(prevNdc.x * 0.5f + 0.5f, -prevNdc.y * 0.5f + 0.5f);
    float2 velocityUv = currentUv - prevUv;

    outColor0 = baseColor;
    outColor1 = float4(saturate(velocityUv * 0.5f + 0.5f), 0.5f, 1.0f);
}

technique TechniqueMRT
{
    pass P0
    {
        CullMode = NONE;
        VertexShader = compile vs_3_0 VertexShader1();
        PixelShader = compile ps_3_0 PixelShaderMRT();
    }
}
