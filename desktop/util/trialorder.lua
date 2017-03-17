local M={}
trialorder=M

local _=require "util.moses"
local math=math
local assert=assert
local print=print

setfenv(1,M)

function generate(options, bucketSize)
  local total=_.reduce(options,function(state,value)
    return state+value.n
  end,0)
  assert(total%bucketSize==0)

  local numBuckets=total/bucketSize
  for i=1, #options do
    options[i].numPerBucket=(options[i].n)/numBuckets
    options[i].accumulator=0
  end

  local function makeBucket()
    local bucket={}
    while true do
      for k=1,#options do
        local opt=options[k]
        local num=math.floor(opt.numPerBucket+opt.accumulator)
        if num+#bucket>bucketSize then
          num=bucketSize-#bucket
        end
        opt.accumulator=opt.numPerBucket-num
        for j=#bucket+1,#bucket+num do
          bucket[j]=opt.value
        end
        if #bucket==bucketSize then
          return bucket
        end
      end
    end
    assert(#bucket==bucketSize,#bucket.. " != ".. bucketSize)
    return bucket
  end

  local buckets={}
  for i=1, numBuckets do
    buckets[i]=_.shuffle(makeBucket())
  end
  return _(buckets):shuffle():flatten():value()
end

return M