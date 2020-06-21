// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/shader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            uniform float4x4 _FrustumCornersES;
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_TexelSize;
            uniform float4x4 _CameraInvViewMatrix;
            uniform float3 _CameraWS;
            uniform float _1;
            uniform float _2;
            uniform float _3;
            uniform float _4;
            uniform float _5;
            uniform float _6;
            uniform float _7;
            uniform float _8;
            uniform float _9;
            uniform float _10;

            uniform float3 _LightDir;



            // Input to vertex shader
            struct appdata
            {
                // Remember, the z value here contains the index of _FrustumCornersES to use
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            float sdTorus(float3 p, float2 t)
            {
                float2 q = float2(length(p.xz) - t.x, p.y);
                return length(q) - t.y;
            }

            float sdSphere(float3 p, float3 s, float radius) {
                return length(p - s) - radius;
            }

            float sdSin(float3 p) {
                return 1 - sin(p);
            }


            float DEEE(float3 pos) {
                float Power = _1;
                float Iter = _2;
                float3 z = pos;
                float r = 0.0;
                for (int i = 0; i < Iter; i++) {
                    if (r > _3 * 100) break;

                    float a = z.z * r;
                    float b = atan2(z.y, z.x) * a;
                    z = float3(a, b, a * b);
                    z += pos;
                }
                return 0.5 * log(r) * r / 5;
            }

            float DEE(float3 pos) {
                float Power = _1;
                float Iter = _2;
                float3 z = pos;
                float dr = 1.0;
                float r = 0.0;
                for (int i = 0; i < Iter; i++) {
                    r = length(z);
                    if (r > _3 * 100) break;

                    // convert to polar coordinates
                    float theta = acos(z.z / r);
                    float phi = atan2(z.y, z.x);
                    dr = pow(r, Power - 1.0) * Power * dr + 1.0;

                    // scale and rotate the point
                    float zr = pow(r, Power);
                    theta = theta * Power;
                    phi = phi * Power;

                    // convert back to cartesian coordinates
                    z = zr * float3(pow(r,theta), pow(r,theta),pow(r,theta));
                    z += pos;
                }
                return 0.5 * log(r) * r / dr;
            }

            float DE(float3 pos) {
                float Power = _1;
                float Iter = _2;
                float3 z = pos;
                float dr = 1.0;
                float r = 0.0;
                for (int i = 0; i < Iter; i++) {
                    r = length(z);
                    if (r > _3 * 100) break;

                    // convert to polar coordinates
                    float theta = acos(z.z / r);
                    float phi = atan2(z.y, z.x);
                    dr = pow(r, Power - 1.0) * Power * dr + 1.0;

                    // scale and rotate the point
                    float zr = pow(r, Power);
                    theta = theta * Power;
                    phi = phi * Power;

                    // convert back to cartesian coordinates
                    z = zr * float3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
                    z += pos;
                }
                return 0.5 * log(r) * r / dr;
            }

            float sdOctahedron(float3 p,float3 l, float s)
            {
                p -= l;
                p = abs(p);
                return (p.x + p.y + p.z - s) * 0.57735027;
            }

            float3 mod(float3 p, float3 max) {
                float3 res = float3(0, 0, 0);
                res.x = fmod(p.x, max.x);
                res.y = fmod(p.y, max.y);
                res.z = fmod(p.z, max.z);
                return res;
            }

            struct octahedron {

                float3 l;
                float s;

                float getSD(float3 p) {
                    p -= l;
                    p = abs(p);
                    return (p.x + p.y + p.z - s) * 0.57735027;
                }
            };
            
            float sdBoxx(float3 p, float3 b) {
                float3 q = abs(p);
                q -= b;
                return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
            }

            float sdCross(float3 p)
            {
                float da = sdBoxx(p, float3(10000, 1, 1)); //
                float db = sdBoxx(float3(p.y, p.z, p.x), float3(1.0, 10000, 1.0));
                float dc = sdBoxx(float3(p.z, p.x, p.y), float3(1.0, 1.0, 10000));
                return min(da, min(db, dc));
            }

            float4 frac(float3 p)
            {
                float d = sdOctahedron(p, float3(0, 0, 0), 1);
                float c = sdCross(p * 3.0) / 3.0;
                d = max(d, -c);
                return float4(d, 1.0, 1.0, 1.0);
            }

            float infinitemirror(float3 p) {
                float d = sdBoxx(p, float3(_2,_2,_2));
                float3 res = float3(d, 1.0, 0.0);

                float s = 1.0;
                for (int m = 0; m < _6; m++)
                {
                    float3 a = mod(p * s, 2.0) - 1.0;
                    s *= _5;
                    float3 r = abs(1.0 - 3.0 * abs(a));

                    float da = max(r.x, r.y);
                    float db = max(r.y, r.z);
                    float dc = max(r.z, r.x);
                    float c = (min(da, min(db, dc)) - 1.0) / s;

                    if (c > d)
                    {
                        d = c;
                        res = float3(d, 0.2 * da * db * dc, (1.0 + float(m)) / 4.0);
                    }
                }

                return res;
            }

            float mirror(float3 p, octahedron o)
            {
                p.xz = abs(p.xz);
                return o.getSD(p);
            }

            float oxedron(float3 p) {
                octahedron o;
                o.l = float3(1, 0, 1);
                o.s = 1;
                return infinitemirror(p);
            }

            float map(float3 p) {
               p = mod(p, float3(_4, _4, _4));
               p.x += _4 / 2;
               p.y += _4 / 2;
               p.z += _4 / 2;
                //float dst = infinitemirror(p);
                float dst = oxedron(p);
                return dst;
                //return opSymXZ(p);
                //return DEE(p);
                //return sdSin(p);
                //return sdOctahedron(p,float3(0,0,0),1);
                //return 1000;
            }

            float3 calcNormal(in float3 pos)
            {
                // epsilon - used to approximate dx when taking the derivative
                const float2 eps = float2(0.001, 0.0);

                // The idea here is to find the "gradient" of the distance field at pos
                // Remember, the distance field is not boolean - even if you are inside an object
                // the number is negative, so this calculation still works.
                // Essentially you are approximating the derivative of the distance field at this point.
                float3 nor = float3(
                    map(pos + eps.xyy).x - map(pos - eps.xyy).x,
                    map(pos + eps.yxy).x - map(pos - eps.yxy).x,
                    map(pos + eps.yyx).x - map(pos - eps.yyx).x);
                return normalize(nor);
            }

            fixed4 raymarch(float3 ro, float3 rd) {
                fixed4 ret = fixed4(0, 0, 0, 0);

                const int maxstep = 64;
                float t = 0; // current distance traveled along ray
                for (int i = 0; i < maxstep; ++i) {
                    float3 p = ro + rd * t; // World space position of sample
                    float d = map(p);       // Sample of distance field (see map())


                    // If the sample <= 0, we have hit something (see map()).
                    if (d < 0.001) {
                        // Lambertian Lighting
                        float3 n = calcNormal(p);
                        ret = fixed4(dot(-_LightDir.xyz, n).rrr, 1);
                        //p = mod(p, _5);
                        //ret = fixed4(p.x, p.y, p.z, 1);
                        break;
                    }

                    // If the sample > 0, we haven't hit anything yet so we should march forward
                    // We step forward by distance d, because d is the minimum distance possible to intersect
                    // an object (see map()).
                    t += d;
                }
                return ret;
            }


            // Output of vertex shader / input to fragment shader
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 ray : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;

                // Index passed via custom blit function in RaymarchGeneric.cs
                half index = v.vertex.z;
                v.vertex.z = 0.1;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv.xy;

#if UNITY_UV_STARTS_AT_TOP
                if (_MainTex_TexelSize.y < 0)
                    o.uv.y = 1 - o.uv.y;
#endif

                // Get the eyespace view ray (normalized)
                o.ray = _FrustumCornersES[(int)index].xyz;

                // Transform the ray from eyespace to worldspace
                // Note: _CameraInvViewMatrix was provided by the script
                o.ray = mul(_CameraInvViewMatrix, o.ray);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // ray direction
                float3 rd = normalize(i.ray.xyz);
                // ray origin (camera position)
                float3 ro = _CameraWS;

                fixed3 col = tex2D(_MainTex,i.uv); // Color of the scene before this shader was run
                fixed4 add = raymarch(ro, rd);

                // Returns final color using alpha blending
                return fixed4(col * (1.0 - add.w) + add.xyz * add.w,1.0);
            }
            ENDCG
        }
    }
}
