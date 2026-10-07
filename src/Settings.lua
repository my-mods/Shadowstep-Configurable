local M = {}
local Store = require('SettingsStore')
M.schema = {
    {key='enabled',values={0,1},default=1},
    {key='horizontalMetres',min=1,max=50,default=18},
    {key='upMetres',min=1,max=50,default=18},
    {key='downMetres',min=1,max=50,default=18},
    {key='speed',min=1,max=50,default=15},
    {key='logLevel',values={0,1,2,3,4},default=2},
}
function M.start(directory, apply, report)
    local ids, defaults = {}, {}
    for _, field in ipairs(M.schema) do ids[field.key],defaults[field.key]=field.key,field.default end
    local live = require('UE4SSDawnwalkerSettings').new({
        modId='ShadowstepConfigurable',schema=M.schema,ids=ids,report=report,
    })
    live.attach(function(values) require('ModLog').setLevel(values.logLevel);apply(values) end)
    local function reload()
        local values,err=require('LogSettings').load(Store.path(directory),M.schema)
        if values then require('ModLog').setLevel(values.logLevel);live.seed(values);apply(values)
        else report('Settings: '..tostring(err)..'; previous values retained.') end
    end
    reload()
    live.start(function(id,callback) return require('ModLog').subscribe(directory,id,callback) end)
    return reload
end
return M
