-- glsl shaders
-- #version 120

-- format is { COMMON_HEADER, VERTEX_SHADER, FRAGMENT_SHADER, TEXTURE_NAME }

-- implicit parameters:
-- attribute vec4 Position; (vertex position)
-- uniform mat4 Transform; (transformation matrix)
-- uniform sampler2D ShaderTex; (texture sampler for specified texture_name);
-- uniform vec2 ShaderTexRes; (widthxheight of texture_name)
-- uniform vec2 Resolution; (widthxheight of window in pixels)
-- uniform float ToPixels; (pixel_size / world_size, converts world sizes into (zoom invariant) pixels sizes)

{
   -- spaceship hulls
   ShaderIridescent = {
      "varying vec4 DestinationColor;"
      ,
      "attribute vec4 SourceColor0; //ship color 0
      attribute vec4 SourceColor1;	//ship color 1
      attribute float TimeA;
	  
	  // include this so I can use snoise, usually used to draw wormhole
	  #include 'noise3D.glsl'
	  
      void main(void) {
          gl_Position = Transform * Position;
		  
          float val = 0.5 + 0.75 * sin(Time + (TimeA)) * sin(2 * (Time + (TimeA))) -
			0.3 * snoise( vec3(0, 0.5 * TimeA, Time) ); 
			//+ 0.2*sin(0.5* (10*Time + (TimeA)));			//changed by me
		
		  float valTwo = 0.5 + sin(0.5 * (Time + (TimeA)));
			float l0 = length(SourceColor0.rgb);
            float l1 = length(SourceColor1.rgb);
			float intensity0 = 0.025 * l0;
			float intensity1 = 0.025 * l1;
			
			float destRed = mix(SourceColor0.r + (intensity0 * sin(Time * 5 + TimeA)), SourceColor1.r + (intensity1 * sin(Time * 4 + TimeA)), val);
			float destGreen = mix(SourceColor0.g + (intensity0 * sin(Time * 6 + TimeA)), SourceColor1.g + (intensity1 * sin(Time * 3 + TimeA)), val);
			float destBlue = mix(SourceColor0.b + (intensity0 * sin(Time* 5.5 + TimeA)), SourceColor1.b + (intensity1 * sin(Time * 3.5 + TimeA)), val);
			float destAlph = mix(SourceColor0.a, SourceColor1.a, val);
			
			//vec4 extraColor = vec4(0.1 * snoise(vec3(sin(0.1 * Time), 0, 2*Time)), 0.1 * snoise(vec3(cos(0.2 * Time), 0, 1.9*Time)), 0.1 * snoise(vec3(sin(0.15 * Time), 0, 2.5*Time)), 1);
			
		  DestinationColor = mix(vec4(vec3(-0.05), 0) + vec4(destRed, destGreen, destBlue, destAlph), vec4(vec3(0.04), 0) + vec4(destRed, destGreen, destBlue, destAlph), valTwo);
			
		  //DestinationColor = mix(vec4(0.1) + mix(SourceColor0, SourceColor1, val), vec4(-0.1) + mix(SourceColor0, SourceColor1, val), valTwo) + 46 * snoise(vec3(0, 0.1 * TimeA, 2*Time)); // changed by me
			
		
          //DestinationColor = mix(SourceColor0, SourceColor1, val);
      }"
      ,
      "void main(void) {
            gl_FragColor = DestinationColor;
      }"
   },

   -- draws projectiles, shields, lasers, etc
   ShaderColorLuma = {
      "varying vec4 DestinationColor;"
        ,
        "attribute vec4 SourceColor;
        attribute float Luma;
        void main(void) {
            //DestinationColor = Luma * SourceColor;
			float l0 = length(SourceColor.rgb);
			float intensity0 = 0.07 * l0;			//changed by me
			
			DestinationColor = vec4(SourceColor.r - (intensity0 * sin(Time * 5)),
									SourceColor.g - (intensity0 * sin(Time * 6)),
									SourceColor.b - (intensity0 * sin(Time * 5.5)),
									SourceColor.a);
			DestinationColor *= Luma;
            gl_Position = Transform * Position;
        }"
        ,
        "void main(void) {
            gl_FragColor = DestinationColor;
        }" 
   },

   -- draws stars
   ShaderLameStars = {
      "varying vec4 DestinationColor;"
      ,
      "attribute vec4 SourceColor;
       attribute float Size;
       uniform   float ToPixels;
       uniform float EyeZ;
       void main(void) {
           DestinationColor = SourceColor;
           gl_PointSize = Size * ToPixels * 0.5;
           gl_Position = Transform * Position;
       }"
      ,
      "#include 'noise3D.glsl'
	  void main(void) {
           vec2 coord = 2.0 * (gl_PointCoord - 0.5);
           float val = (length(coord) + abs(coord.x) + abs(coord.y)) / 2.0;
           float alpha = min(1.0 - val, 1.0);
           if (alpha <= 0.0)
               discard;
		//allegedly causes the twinkle
           gl_FragColor = (1+snoise(vec3(coord.x*10, coord.y*10, Time))) * DestinationColor * vec4(vec3(2), alpha * 1.3);
       }"
   },

   -- draws stars
   ShaderStars = {
      "varying vec4 DestinationColor;"
      ,
      "attribute vec4 SourceColor;
       attribute float Size;
       uniform   float ToPixels;
       uniform float EyeZ;
       void main(void) {
           DestinationColor = SourceColor;
           gl_PointSize = Size * ToPixels * 0.5;
           gl_Position = Transform * Position;
       }"
      ,
      "#include 'noise3D.glsl'
	  void main(void) {
           vec2 coord = 2.0 * (gl_PointCoord - 0.5);
           float val = (length(coord) + abs(coord.x) + abs(coord.y)) / 2.0;
           float alpha = min(1.0 - val, 1.0);
           if (alpha <= 0.0)
               discard;
		//allegedly causes the twinkle
           gl_FragColor = DestinationColor * vec4(vec3(2), alpha * 1.3);
       }"
   },

   -- draws the wormhole
   ShaderWormhole = {
      "varying vec4 DestColor0;
       varying vec4 DestColor1;
       varying vec2 DestTex;
       float length2(vec2 x) { return dot(x, x); }"

      ,
      "attribute vec2 TexCoord;
      
      void main(void) {
          DestColor0 = vec4(0.2, 0.3, 0.8, 0);
          DestColor1 = mix(vec4(0, 0.9, 0.7, 1.1), vec4(DestColor0.xyz, 1.0), length2(TexCoord));
          DestTex = TexCoord;
          gl_Position = Transform * Position;
      }"
      ,
      "
      #include 'noise3D.glsl'

      vec2 rotate(vec2 v, float a) {
          vec2 r = vec2(cos(a), sin(a));
          return vec2(r.x * v.x - r.y * v.y, r.y * v.x + r.x * v.y);
      }

      void main(void) {
          float r = length2(DestTex);
          float val = snoise(vec3(rotate(DestTex, Time + 5 * r), Time/3 + 2*r) * 2);
          float aval = snoise(vec3(rotate(DestTex, Time + 3 * r), Time/10) * 1);
          float alpha = 1. + 1. * aval;           
          alpha *= max(0, 1 - r) * 3 * r;
          vec4 color = mix(DestColor0, DestColor1, 0.8 + 0.5 * val);
          gl_FragColor = vec4(alpha * color.a * color.xyz, 0.0);
      }"
   }

   ShaderBlackhole = {
      "varying vec2 uv;"
      ,
      "attribute vec2 TexCoord;
      void main(void) {
          uv = TexCoord;
          gl_Position = Transform * Position;
      }",
      "#include 'blackhole.glsl'

      void main(void) {
          gl_FragColor = frag(uv);
      }",
      "textures/Starsinthesky.jpg"
      -- "C4s3q7KVUAAvVgu.jpg"
   }

   -- draws resource packets (R)
   ShaderResource = {
      "varying vec4 DestColor0;
       varying vec4 DestColor1;
       varying vec2 DestPos;
       varying float DestRad;"
      ,
      "attribute vec4 SourceColor0;
      attribute vec4 SourceColor1;
      attribute float Radius;
      uniform float ToPixels;
      void main(void) {
          DestColor0 = SourceColor0;
          DestColor1 = SourceColor1;
          DestPos = Position.xy / 100;
          DestRad = sqrt(Radius);
          gl_Position = Transform * Position;
          gl_PointSize = 2 * ToPixels * Radius;
      }"
      ,
      "
      #include 'noise2D.glsl'

      float length2(vec2 x) { return dot(x, x); }
      vec2 rotate(vec2 v, float a) {
          vec2 r = vec2(cos(a), sin(a));
          return vec2(r.x * v.x - r.y * v.y, r.y * v.x + r.x * v.y);
      }

      void main(void) {
            vec2 coord = gl_PointCoord.xy - 0.5;
            float len2c = length2(coord);
            float post = DestPos.x + DestPos.y + Time;
            float thresh = 1.0 - (4.0 * len2c);
            if (thresh <= 0)
                discard;
            vec2 pos = 0.1 * (DestPos + vec2(0, -Time/2) + DestRad * rotate(coord, len2c * 7 + (DestRad * DestRad / 10) + mod(Time/5, 2 * M_PI)));
            float val = 0.5 * snoise(pos * 1.5) + 0.25 * snoise(pos * 3);
            gl_FragColor.a = (1.0 + 0.5 * sin(5 * val)) * thresh;
            gl_FragColor.xyz = gl_FragColor.a * mix(DestColor0.xyz, DestColor1.xyz, 0.5 + 0.5 * sin(10 * val));
      }"
   },

   -- used for nice gradient backgrounds
   ShaderColorDither = {
      "varying vec4 DestinationColor;"
      ,
      "attribute vec4 SourceColor;
      void main(void) {
          DestinationColor = SourceColor;
          gl_Position = Transform * Position;
      }"
      ,
      "uniform sampler2D dithertex;
      void main(void) {
            float ditherv = texture2D(dithertex, gl_FragCoord.xy / 8.0).r / 64.0 - (1.0 / 128.0);
            gl_FragColor = DestinationColor + vec4(ditherv);
      }"
   },

   -- passthrough texture shader - used in many places for drawing render targets
   ShaderTexture = {
      "varying vec2 DestTexCoord;
       varying vec4 DestColor;\n"
      ,
      "attribute vec2 SourceTexCoord;
      uniform vec4 SourceColor;
      void main(void) {
          DestTexCoord = SourceTexCoord;
          DestColor    = SourceColor;
          gl_Position  = Transform * Position;
      }"
      ,
      "uniform sampler2D texture1;
       void main(void) {
           vec2 texCoord = DestTexCoord;
           gl_FragColor = DestColor * texture2D(texture1, texCoord);
       }"
   }

   ShaderTextureWarp = {
      "varying vec2 DestTexCoord;
       varying vec4 DestColor;"
      ,
      "attribute vec2 SourceTexCoord;
      uniform vec4 SourceColor;
      void main(void) {
          DestTexCoord = SourceTexCoord;
          DestColor    = SourceColor;
          gl_Position  = Transform * Position;
      }"
      ,
      "uniform sampler2D texture1;
       uniform sampler2D warpTex;
       uniform vec2      camWorldPos;
       uniform vec2      camWorldSize;
      #include 'noise2D.glsl'
      void main(void) {
         vec2 texCoord = DestTexCoord;
          //vec2 roll = (texCoord - vec2(0.5));
          //texCoord += 3.0 * vec2(roll.y, -roll.x) * max(0.0, (0.5 - length(roll)));
          float warpv = length(texture2D(warpTex, texCoord).rgb);
          if (warpv > 0.0)
              texCoord += 100.0 * warpv * snoise(camWorldPos + 0.1 * Time + 0.01 * texCoord * camWorldSize) /
                          max(camWorldSize.x, camWorldSize.y);
          gl_FragColor = DestColor * texture2D(texture1, texCoord);
      }"
   }

   -- HDR postprocessing. makes really bright areas (i.e. with a lot of particles) more white to make them look brighter
   ShaderTonemap = {
      "varying vec2 DestTexCoord;"
      ,
      "attribute vec2 SourceTexCoord;
      void main(void) {
          DestTexCoord = SourceTexCoord;
          gl_Position  = Transform * Position;
      }"
      ,
      "uniform sampler2D texture1;
      uniform sampler2D dithertex;
      float magnus_ramped(float m_color) {
          return 0.4 * (log(m_color + 0.3679) + 1);
      }
      void main(void) {
          vec2 texCoord = DestTexCoord;
          vec4 color = texture2D(texture1, texCoord);
          if (color.rgb != vec3(0.0))
          {
              color.rgb = vec3(magnus_ramped(color.r), 
                                magnus_ramped(color.g), 
                                magnus_ramped(color.b)
                                );

              //float mx = max(color.r, max(color.g, color.b));
              //if (mx > 1.0) {
                  //color.rgb += 1.0 * vec3(mx - 1.0);
                  //color.rgb += 0.9 * vec3(log(mx));
              //}

      #if DITHER
              float ditherv = texture2D(dithertex, gl_FragCoord.xy / 8.0).r / 128.0 - (1.0 / 128.0);
              color += vec4(ditherv);
      #endif
          }
          // apparently Intel (R) HD Graphics 3000 does not clamp automatically
          gl_FragColor = clamp(color, vec4(0), vec4(1));
          //gl_FragColor = color;
      }"
   },

   ShaderHsv = {
      "varying vec4 DestHSVA;"
      ,
      "attribute vec4 ColorHSVA;
       void main(void) {
           DestHSVA = ColorHSVA;
           gl_Position = Transform * Position;
       }"
      ,

      "
       #include 'hsv_rgb.glsl'
       void main(void) {
           gl_FragColor = vec4(hsv2rgb(DestHSVA.rgb), DestHSVA.a);
      }"
   },


   ShaderTextureHSV = {
      "varying vec2 DestTexCoord;
       varying vec4 DestColor;"
      ,
      "attribute vec2 SourceTexCoord;
       uniform vec4 SourceColor;
       void main(void) {
           DestTexCoord = SourceTexCoord;
           DestColor    = SourceColor;
           gl_Position  = Transform * Position;
       }"
      ,
      "uniform sampler2D texture1;
       #include 'hsv_rgb.glsl'

       void main(void) {
           vec4 tcolor = texture2D(texture1, DestTexCoord);
           gl_FragColor = vec4(hsv2rgb(DestColor.rgb * rgb2hsv(tcolor.rgb)), 
                              DestColor.a * tcolor.a);
       }"
   },

   -- draws dynamic glowey halos around spaceships
   -- FIXME optimize this for 1 point?
   -- NOTE: the lengthSqr distance compare, with scale * scale, has precision issues
   -- NOTE: when scale is very small!
   ShaderWorley = {
      ""
      ,
      "void main(void) {
          gl_Position = Transform * Position;
      }"
      ,
      "uniform vec2  points[POINTS];
      uniform vec3  color;
      uniform float scale;
      uniform sampler2D dither;
      void main(void) {
          float minv = 100000000000000.0;
          for (int i=0; i<POINTS; i++)
          {
               vec2 d = points[i] - gl_FragCoord.xy;
      
      //         float v = length(d);
      //         float v = distance(points[i],  gl_FragCoord.xy);
                 float v = d.x * d.x + d.y * d.y;
      //         float v = sqrt(d.x*d.x + d.x*d.y + d.y* d.y);
      //           float v = abs(d.x) + abs(d.y);
               minv = min(minv, v);
          }
      //    float myv = minv * scale;
          float myv = sqrt(minv) * scale;
      //    float myv = minv * scale * scale;
          if (myv > 1.0) {
              discard;
          }
          float alpha = 1.0 - myv;
          gl_FragColor = vec4(alpha * color.rgb, alpha);
      #if DITHER
          //alpha += texture2D(dither, gl_FragCoord.xy / 8.0).r / 4.0 - (1.0 / 128.0);
          gl_FragColor += vec4(texture2D(dither, gl_FragCoord.xy / 8.0).r / 16.0 - (1.0 / 64.0));
      #endif
          
      }",
   }

   -- used for particles (GL_POINTS) (not in effect)
   ShaderParticlePointsd = {
      "varying vec4 DestinationColor;
		varying float DestElapsed;
       varying float Sides;
       #if USE_TRIS
       varying vec2 Coord;
       #endif"
      ,
      "attribute vec3  Offset;
       attribute float StartTime;
       attribute float EndTime;
       attribute vec3  Velocity;
       attribute vec4  Color;
       uniform   float CurrentTime;
       uniform   float ToPixels;
	   #include 'noise3D.glsl'
       void main(void) {
		float deltaT = CurrentTime - StartTime;
		DestElapsed = deltaT;
		float v = deltaT / (EndTime - StartTime);
       #if !USE_TRIS
			
           float size = ToPixels * max(0, 0.05 + Offset.x * min(3, 5 - v)/2.4);
           gl_PointSize = size;
           if (CurrentTime >= EndTime || size < 0.25)
       #else
           if (CurrentTime >= EndTime)
       #endif
           {
               gl_Position = vec4(0.0, 0.0, -99999999.0, 1);
               return;
           }
           
           vec3  velocity = pow(0.8, deltaT) * (Velocity / 2);
           vec3  position = Position.xyz + deltaT * velocity;
          
           DestinationColor = (1.0 - v) * (Color);           
       #if USE_TRIS
           Coord = Offset.xy;
           if (Offset.y >= 10) {
               Coord.y -= 10;
               Sides = 1.0;
            } else {
               Sides = 0.0;
           }
           position.xy += (Coord.xy - 0.5) * (2.0 * Offset.z);
       #else
           Sides = Offset.y;
       #endif
           gl_Position = Transform * vec4(position, 1);
       }"
      , -- // -/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
      "
       float length2(vec2 x) { return dot(x, x); }
	   #include 'noise3D.glsl'
       void main(void) {
       #if USE_TRIS
           float val = 1.0 - 4.0 * length2(Coord - 0.5);
       #else
           float val = 1.0 - 4.0 * length2(gl_PointCoord - 0.5);
       #endif
           if (val <= 0.0)
               discard;
           if (Sides > 0.0) {
               gl_FragColor = DestinationColor;
           } else {
               gl_FragColor = DestinationColor * val * val;
           }
       }"
   }
	-- in effect
	ShaderParticlePoints = {
      "varying vec4 DestinationColor;
		varying float DestLifetime;
		varying float DestElapsed;
		//varying float poqueX;
		//varying float poqueY;
       varying float Sides;
       #if USE_TRIS
       varying vec2 Coord;
       #endif"
      ,
      "attribute vec3  Offset;
       attribute float StartTime;
       attribute float EndTime;
       attribute vec3  Velocity;
       attribute vec4  Color;
       uniform   float CurrentTime;
       uniform   float ToPixels;
	   #include 'noise3D.glsl'
       void main(void) {
		//poqueX = Position.x;
		//poqueY = Position.y;
		DestLifetime = EndTime - StartTime;
		float deltaT = CurrentTime - StartTime;
		DestElapsed = deltaT;
		float v = deltaT / (EndTime - StartTime);
       #if !USE_TRIS
			
           float size = ToPixels * 2 * max(0, Offset.x * min(3, pow(2,-v)));			
		   // changed from min(3, 5-v) max(0, 0.05 + Offset.x * min(3, v)/2.4) |||| max(0, Offset.x * min(3, (v/2-1) * (v/2-1))); ||||| max(0, Offset.x * min(3, 0.1 * (v+p) *((v-6+p) * (v-6 + p))));
           gl_PointSize = size;
           if (CurrentTime >= EndTime || size < 0.25)
       #else
           if (CurrentTime >= EndTime)
       #endif
           {
               gl_Position = vec4(0.0, 0.0, -99999999.0, 1);
               return;
           }
           
           vec3  velocity = pow(0.8, deltaT) * (Velocity / 2);
           vec3  position = Position.xyz + deltaT * velocity;
          
           DestinationColor = (1.0 - v) * (Color * 0.9);           
       #if USE_TRIS
           Coord = Offset.xy;
           if (Offset.y >= 10) {
               Coord.y -= 10;
               Sides = 1.0;
            } else {
               Sides = 0.0;
           }
           position.xy += (Coord.xy - 0.5) * (2.0 * Offset.z);
       #else
           Sides = Offset.y;
       #endif
           gl_Position = Transform * vec4(position, 1);
       }"
      , -- // -/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
      "
       float length2(vec2 x) { return dot(x, x); }
	   #include 'noise3D.glsl'
       void main(void) {
       #if USE_TRIS
           float val = 1.0 - 4.0 * length2(Coord - 0.5);
       #else
           float val = 1.0 - 4.0 * length2(gl_PointCoord - 0.5);
       #endif
           if (val <= 0.0)
               discard;
           if (Sides > 0.0) {
               gl_FragColor = DestinationColor;
           } else {
               gl_FragColor = DestinationColor * val * val;				/*snoise(vec3(0, poqueX, poqueY))*/
           }
       }"
   }
	
   -- full screen blurs. 
   ShaderBlur = {
      "varying vec2 DestTexCoord;"
      ,
      "attribute vec2 SourceTexCoord;
       void main(void) {
           DestTexCoord = SourceTexCoord;
           gl_Position  = Transform * Position;
       }"
      ,
      -- BLUR expands to the sum of a number of texture2d calls depending on the blur radius
      "uniform sampler2D source;
       uniform vec2 offsets[BLUR_SIZE];
       void main() {
           gl_FragColor = BLUR(source, DestTexCoord, offsets);
       }"
   }
}
