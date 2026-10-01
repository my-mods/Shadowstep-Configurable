-- Native description results only. No widget scanning or asset text mutation.
local M={}
local target='TraitAsset /Game/_Dawnwalker/Player/CharacterDevelopment/Traits/DataAssets/DA_Trait_Vampire_Shadowstep.DA_Trait_Vampire_Shadowstep'
local prefix='/Script/DogwoodCharacterDevelopment.TraitAsset:'
local function number(n) return string.format('%.6g',n) end
-- Match the source format around argument zero instead of guessing a localized
-- decimal separator. Leave the game's other formatted arguments untouched.
function M.replaceRange(source,result,value)
    if type(source)~='string' or type(result)~='string' then return end
    local first,last=source:find('{0}',1,true)
    if not first or source:find('{0}',last+1,true) then return end
    local before,after=source:sub(1,first-1),source:sub(last+1)
    if before:find('{',1,true) then return end
    local nextArgument=after:find('{',1,true)
    local anchor=nextArgument and after:sub(1,nextArgument-1) or after
    if #anchor==0 or result:sub(1,#before)~=before then return end
    local ending=result:find(anchor,#before+1,true)
    if not ending or ending==#before+1 then return end
    return before..number(value)..result:sub(ending)
end
function M.new(report)
    local enabled=false
    local horizontal=18
    local suffix=''
    local hooks={}
    local function owns(context)
        local object=context:get()
        return object and object:IsValid() and object:GetFullName()==target
    end
    local function install(name,signature,callback)
        local path=prefix..name
        local ok,err=pcall(function()
            local fn=StaticFindObject(path)
            assert(fn and fn:IsValid(),'Native description function unavailable')
            local index=0
            fn:ForEachProperty(function(p)
                index=index+1
                local expected=signature[index]
                assert(expected and p:GetFName():ToString()==expected[1]
                    and p:GetFullName():match('^(%S+)')==expected[2],'Description signature changed')
            end)
            assert(index==#signature,'Description signature incomplete')
            local a,b=RegisterHook(path,function() end,function(...)
                if not enabled then return end
                local success,text=pcall(callback,...)
                if not success then report('Description '..name..': '..tostring(text));return end
                return text
            end)
            assert(a and b,'Description hook registration failed')
            hooks[path]={a,b}
        end)
        if not ok then report('Description '..name..' unavailable: '..tostring(err)) end
    end
    return {
        configure=function(settings)
            enabled=settings.enabled==1
            horizontal=settings.horizontalMetres
            -- Owned plain text, rebuilt only on configuration events.
            suffix=string.format('\n\nConfigured Shadowstep\nHorizontal: %s m | Up: %s m | Down: %s m\nTravel speed: %s m/s',
                number(horizontal),number(settings.upMetres),number(settings.downMetres),number(settings.speed))
        end,
        start=function()
            -- UE4SS exposes FText as userdata with __call. Probe the operation
            -- on this game-thread callback instead of requiring a Lua function.
            local ok,err=pcall(function()
                assert(FText(''):ToString()=='','FText round-trip failed')
            end)
            if not ok then report('Description feature unavailable: FText construction failed: '..tostring(err));return end
            install('GetSkillDescription',{{'ReturnValue','TextProperty'}},function(context,result)
                if not owns(context) then return end
                return FText(result:get():ToString()..suffix)
            end)
            install('GetLevelDescription',{{'SourceDescription','TextProperty'},{'Level','IntProperty'},{'ReturnValue','TextProperty'}},function(context,result,source)
                if not owns(context) then return end
                local text=M.replaceRange(source:get():ToString(),result:get():ToString(),horizontal)
                if not text then report('Shadow Dweller range text has an unsupported format; original level description retained.');return end
                return FText(text)
            end)
        end,
    }
end
return M
