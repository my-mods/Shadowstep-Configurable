-- Own individual scalar writes; never retain borrowed attribute structs.
local M={}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function equal(a,b) return finite(a) and finite(b) and math.abs(a-b)<0.001 end
function M.new(report)
    local entries={}
    local function get(e)
        if e.member then return e.object[e.field][e.member] end
        return e.object[e.field]
    end
    local function put(e,value)
        if e.member then e.object[e.field][e.member]=value else e.object[e.field]=value end
    end
    local function set(object,field,member,value,canWrite)
        local key=tostring(object:GetAddress())..':'..field..':'..(member or '')
        local e=entries[key] or {object=object,field=field,member=member}
        local have=get(e)
        assert(finite(have),'Missing numeric property '..field..'.'..(member or ''))
        if not entries[key] or not equal(have,e.last) then e.original=have end
        entries[key]=e
        -- Record intended ownership before a setter which might write then throw.
        assert(canWrite(),'Player context changed during application')
        if not equal(have,value) then e.last=value;put(e,value) else e.last=have end
        assert(equal(get(e),value),'Write verification failed: '..field)
    end
    local function safe(label,fn)
        local ok,err=pcall(fn)
        if not ok then report(label..': '..tostring(err)) end
        return ok
    end
    return {
        apply=function(pawn,settings,canWrite)
            local attr,component=pawn.CharacterAttributeSet,pawn.ShadowstepComponent
            local ready=true
            for _,spec in ipairs({{'ShadowstepHorizontalRange','horizontalMetres'},
                {'ShadowstepVerticalRangeUp','upMetres'},{'ShadowstepVerticalRangeDown','downMetres'}}) do
                local ok=safe(spec[1],function()
                    assert(attr and attr:IsValid(),'Player CharacterAttributeSet unavailable')
                    assert(attr:GetOuter():GetAddress()==pawn:GetAddress(),'Attribute set belongs to another player')
                    -- Validate both members before changing either one.
                    local current,base=attr[spec[1]].CurrentValue,attr[spec[1]].BaseValue
                    assert(finite(current) and finite(base),'Expected GameplayAttributeData')
                    assert(current>0 and base>0,'Range attributes not initialized')
                    set(attr,spec[1],'BaseValue',settings[spec[2]]*100,canWrite)
                    set(attr,spec[1],'CurrentValue',settings[spec[2]]*100,canWrite)
                end)
                ready=ok and ready
            end
            local ok=safe('ShadowstepVelocityMps',function()
                assert(component and component:IsValid(),'Shadowstep component unavailable')
                assert(component:GetOwner():GetAddress()==pawn:GetAddress(),'Component belongs to another player')
                local speed=component.ShadowstepVelocityMps
                assert(finite(speed) and speed>0,'Speed property not initialized')
                set(component,'ShadowstepVelocityMps',nil,settings.speed,canWrite)
            end)
            return ok and ready
        end,
        restore=function(pawn)
            local complete=true
            for key,e in pairs(entries) do
                local ok=safe('Restore '..e.field,function()
                    local owner=e.member and pawn.CharacterAttributeSet or pawn.ShadowstepComponent
                    if owner and owner:IsValid() and e.object:IsValid()
                        and owner:GetAddress()==e.object:GetAddress() and equal(get(e),e.last) then
                        put(e,e.original)
                        assert(equal(get(e),e.original),'Restoration verification failed')
                    end
                end)
                if ok then entries[key]=nil else complete=false end
            end
            return complete
        end,
        discard=function() entries={} end,
    }
end
return M
