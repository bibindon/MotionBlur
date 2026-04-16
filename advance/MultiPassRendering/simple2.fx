float g_blurScale = 1.0f;
float g_velocityDecodeScale = 24.0f;

texture texture1;
sampler colorPointSampler = sampler_state
{
    Texture = (texture1);
    MipFilter = NONE;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

sampler colorLinearSampler = sampler_state
{
    Texture = (texture1);
    MipFilter = NONE;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

texture texture2;
sampler velocitySampler = sampler_state
{
    Texture = (texture2);
    MipFilter = NONE;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

void VertexShader1(
    in float4 inPosition : POSITION,
    in float2 inTexCoord : TEXCOORD0,
    out float4 outPosition : POSITION,
    out float2 outTexCoord : TEXCOORD0)
{
    outPosition = inPosition;
    outTexCoord = inTexCoord;
}

void PixelShader1(
    in float2 inTexCoord : TEXCOORD0,
    out float4 outColor : COLOR)
{
    float2 encodedVelocity = tex2D(velocitySampler, inTexCoord).rg;
    float2 velocity = ((encodedVelocity - 0.5f) / g_velocityDecodeScale) * g_blurScale;
    float velocityLength = length(velocity);

    if (velocityLength < 0.0005f)
    {
        outColor = tex2D(colorPointSampler, inTexCoord);
        return;
    }

    float2 blurDirection = velocity / velocityLength;
    float blurRadius = min(velocityLength, 0.12f);
    float4 accumColor = 0.0f;
    float accumWeight = 0.0f;
    const int sampleCount = 21;
    const float sigma = 0.35f;

    for (int i = 0; i < sampleCount; ++i)
    {
        float t = (float(i) / float(sampleCount - 1)) * 2.0f - 1.0f;
        float weight = exp(-(t * t) / (2.0f * sigma * sigma));
        float2 sampleOffset = blurDirection * blurRadius * t;
        float2 sampleUv = saturate(inTexCoord - sampleOffset);
        accumColor += tex2D(colorLinearSampler, sampleUv) * weight;
        accumWeight += weight;
    }

    outColor = accumColor / max(accumWeight, 0.0001f);
}

technique Technique1
{
    pass Pass1
    {
        CullMode = NONE;
        VertexShader = compile vs_3_0 VertexShader1();
        PixelShader = compile ps_3_0 PixelShader1();
    }
}
