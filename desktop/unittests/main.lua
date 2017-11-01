require 'busted.runner'()


describe("remove outliers",function()
  local datatools=require "util.datatools"

  local list={1,2,3,4,5,6,11}
  it("compute quartiles",function()
    local q1,median,q3=datatools.getQuartiles(list)  
    assert.are.equals(q1,2) 
    assert.are.equals(median,4) 
    assert.are.equals(q3,6) 
  end)


  it("high outliers are removed",function()
    local list={1,2,3,4,5,6,13}
    assert.are.same({1,2,3,4,5,6},datatools.removeOutliers(list)) 
  end)

  it("low outliers are removed",function()
    local list={-5,2,3,4,5,6,8}
    assert.are.same({2,3,4,5,6,8},datatools.removeOutliers(list)) 
  end)

  it("list is not modified if there are no outliers",function()
    local list={1,2,3,4,5,6,8}
    assert.are.same({1,2,3,4,5,6,8},datatools.removeOutliers(list)) 
  end)
end)