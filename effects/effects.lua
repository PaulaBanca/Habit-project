local M={}
effects=M

local graphics=graphics

setfenv(1,M)

local kernel = {}
kernel.category = "filter"
kernel.name = "pulse"

kernel.vertexData =
{
    {
        name = "param1",
        default = 1, 
        min = 0,
        max = 1,
        index = 0,  -- This corresponds to "CoronaVertexUserData.x"
    },
    {
        name = "param2",
        default = 1, 
        min = 0,
        max = 1,
        index = 1,  -- This corresponds to "CoronaVertexUserData.x"
    },
}

-- Shader code uses time environment variable CoronaTotalTime
kernel.isTimeDependent = true
kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 center = vec2(0.5,0.5);
  P_UV float speed = 0.035;
  P_UV float invAr = CoronaVertexUserData.y / CoronaVertexUserData.x;
  P_UV vec2 uv = texCoord.xy / CoronaVertexUserData.xy;
  P_UV float x = (center.x-uv.x);
  P_UV float y = (center.y-uv.y) *invAr;
  P_UV float r = -(x*x + y*y);
  P_UV float z = 1.0 + 0.5*sin((r+CoronaTotalTime*speed)/0.013);
  P_COLOR vec4 texCol=texture2D( CoronaSampler0, texCoord );
  texCol*= z;
  return CoronaColorScale( texCol );
}
]]

graphics.defineEffect(kernel)


local kernel = {}
kernel.category = "generator"
kernel.name = "pattern"


-- Shader code uses time environment variable CoronaTotalTime
kernel.isTimeDependent = true
kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  return CoronaColorScale(vec4(sin(CoronaTotalTime+texCoord.x*100.0),0,1.0,1.0));
}
]]

graphics.defineEffect(kernel)


local kernel = {}
kernel.category = "generator"
kernel.name = "stripes"


-- Shader code uses time environment variable CoronaTotalTime
kernel.isTimeDependent = true
kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_COLOR float t=abs(sin((texCoord.x+texCoord.y)*100.0));
  P_COLOR vec4 ret = vec4(t, texCoord.y, 
              t, t);
  return CoronaColorScale(ret);    
}
]]

graphics.defineEffect(kernel)
return M