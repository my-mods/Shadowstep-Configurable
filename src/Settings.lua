local M = {}
local Store = require('SettingsStore')
M.schema = {
    {key='enabled',values={0,1},default=1},
    {key='horizontalMetres',min=1,max=50,default=18},
    {key='upMetres',min=1,max=50,default=18},
    {key='downMetres',min=1,max=50,default=18},
    {key='speed',min=1,max=50,default=15},
    {key='debugLogging',values={0,1},default=0},
}
function M.start(directory, apply, report)
    local ids, defaults = {}, {}
    for _, field in ipairs(M.schema) do ids[field.key],defaults[field.key]=field.key,field.default end
    local live = require('UE4SSDawnwalkerSettings').new({
        modId='ShadowstepConfigurable',schema=M.schema,ids=ids,report=report,
    })
    live.attach(apply)
    local function reload()
        local values,err=Store.load(directory,M.schema,function() return defaults end)
        if values then live.seed(values);apply(values)
        else report('Settings: '..tostring(err)..'; previous values retained.') end
    end
    reload()
    live.start(function(id,callback) return require('dmm_api').subscribe(id,callback) end)
    return reload
end
return M
