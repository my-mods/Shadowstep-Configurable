-- Shadowstep - Configurable. Independent reflected-property implementation.
local directory=assert(debug.getinfo(1,'S').source:match('^@(.+[\\/])'))
local settings={enabled=1,horizontalMetres=18,upMetres=18,downMetres=18,speed=15,debugLogging=0}
local warned,warningCount={},0
local function report(message)
    if warned[message] or warningCount>=32 then return end
    warned[message]=true;warningCount=warningCount+1
    print('[ShadowstepConfigurable] '..message..'\n')
end
for _,name in ipairs({'ExecuteInGameThread','ExecuteInGameThreadWithDelay','CancelDelayedAction','RegisterHook','FindFirstOf','StaticFindObject'}) do
    if type(_G[name])~='function' then report('Required UE4SS API missing: '..name);return end
end
local values=require('Values').new(report)
local descriptions=require('Descriptions').new(report)
local function valid(o) return o~=nil and o:IsValid()==true end
local function same(a,b) return valid(a) and valid(b) and a:GetAddress()==b:GetAddress() end
local engine,gameplay,playerClass,scope,worker,reloadSettings
local loading=false
local generation=0
local hooks={}
local wake
local function cancel()
    generation=generation+1
    if worker and worker.handle then CancelDelayedAction(worker.handle) end
    worker=nil
end
local function current()
    if loading or not scope or not valid(engine) then return false end
    local viewport=engine.GameViewport
    return valid(viewport) and same(viewport:GetWorld(),scope.world)
        and valid(scope.pc) and same(scope.pc:GetWorld(),scope.world)
        and same(scope.pc.Pawn,scope.pawn) and same(scope.pawn:GetWorld(),scope.world)
end
local function invalidate()
    cancel();scope=nil;values.discard()
end
local function discover(job)
    if not job.looked then
        job.looked=true
        if not valid(engine) then engine=FindFirstOf('Engine') end
        if not valid(gameplay) then gameplay=StaticFindObject('/Script/Engine.Default__GameplayStatics') end
        if not valid(playerClass) then playerClass=StaticFindObject('/Script/Dawnwalker.DawnwalkerPlayerCharacter') end
    end
    if not valid(engine) or not valid(gameplay) or not valid(playerClass) then return end
    local viewport=engine.GameViewport
    if not valid(viewport) then return end
    local world=viewport:GetWorld()
    if not valid(world) then return end
    local pc=gameplay:GetPlayerController(world,0)
    if not valid(pc) or pc:IsLocalController()~=true or not same(pc:GetWorld(),world) then return end
    local pawn=pc.Pawn
    if not valid(pawn) or not pawn:IsA(playerClass) or not same(pawn:GetWorld(),world) then return end
    if not scope or not same(scope.pawn,pawn) or not same(scope.world,world) then
        values.discard();scope={pc=pc,pawn=pawn,world=world}
    end
    return values.apply(pawn,settings,function() return generation==job.generation and current() end)
end
wake=function(reason)
    if loading or settings.enabled~=1 or worker then return end
    local job={attempts=0,generation=generation,elapsed=0}
    worker=job
    local function attempt()
        if worker~=job or generation~=job.generation then return end
        job.handle=nil;job.attempts=job.attempts+1
        local start=settings.debugLogging==1 and os.clock() or nil
        local ok,ready=pcall(discover,job)
        if start then job.elapsed=job.elapsed+os.clock()-start end
        if worker~=job or generation~=job.generation or loading then return end
        if not ok then worker=nil;report('Readiness stopped: '..tostring(ready));return end
        if ready or job.attempts>=20 then
            worker=nil
            if not ready then report('Readiness exhausted after 20 attempts; waiting for a load, player event or menu Apply.') end
            if settings.debugLogging==1 then
                print(string.format('[ShadowstepConfigurable] %s: %d attempt(s), %.3f ms total, ready=%s.\n',reason,job.attempts,job.elapsed*1000,tostring(ready)))
            end
        else job.handle=ExecuteInGameThreadWithDelay(250,attempt) end
    end
    job.handle=ExecuteInGameThreadWithDelay(50,attempt)
end
local function guarded(fn)
    return function(...)
        local ok,err=pcall(fn,...)
        if not ok then cancel();report('Operation stopped: '..tostring(err)) end
    end
end
local function apply(snapshot)
    local changed=false
    for key,value in pairs(snapshot) do
        if key~='debugLogging' and settings[key]~=value then changed=true end
        settings[key]=value
    end
    descriptions.configure(settings)
    if not changed and scope then return end
    if settings.enabled~=1 then
        cancel()
        if current() then values.restore(scope.pawn) else values.discard() end
        return
    end
    if changed then cancel() end
    if changed or not current() then wake('settings') end
end
local function hook(path,pre,post)
    local ok,a,b=pcall(RegisterHook,path,pre,post)
    if ok and a and b then hooks[path]={a,b}
    else report('Native lifecycle hook unavailable: '..path..': '..tostring(a)) end
end
ExecuteInGameThread(guarded(function()
    reloadSettings=require('Settings').start(directory,guarded(apply),report)
    descriptions.start()
    hook('/Script/Engine.PlayerController:ClientRestart',function() end,guarded(function(context)
        local pc=context:get()
        if valid(pc) and pc:IsLocalController()==true then cancel();wake('player restart') end
    end))
    local lastLoading
    hook('/Script/DogwoodCombat.CombatSubsystem:OnLoadingScreenStateChanged',function() end,guarded(function(_,state)
        local value=type(state)=='number' and state or state:get()
        if type(value)~='number' or value<0 or value>4 or value==lastLoading then return end
        lastLoading=value;loading=value~=0;invalidate()
        if not loading then reloadSettings();wake('save loaded') end
    end))
    for _,path in ipairs({'/Script/DogwoodUI.SaveWindowBase:RequestLoadSave','/Script/Persistency.SaveSystemBlueprintFunctionLibrary:LoadLastSave','/Script/Persistency.SaveSystemBlueprintFunctionLibrary:TryQuickload'}) do
        hook(path,guarded(cancel),function() end)
    end
    if type(NotifyOnNewObject)=='function' then
        local ok,err=pcall(NotifyOnNewObject,'/Script/Dawnwalker.DawnwalkerPlayerCharacter',function() wake('player constructed') end)
        if not ok then report('Player notification unavailable: '..tostring(err)) end
    end
    wake('startup')
end))
