function LoadScaleform (scaleform)
    local handle = RequestScaleformMovie(scaleform)

    if handle ~= 0 then
        while not HasScaleformMovieLoaded(handle) do
            Citizen.Wait(1)
        end
    end

    return handle
end

function CreateNamedRenderTargetForModel(name, model)
    local handle = 0
    if not IsNamedRendertargetRegistered(name) then
        RegisterNamedRendertarget(name, 0)
    end
    if not IsNamedRendertargetLinked(model) then
        LinkNamedRendertarget(model)
    end
    if IsNamedRendertargetRegistered(name) then
        handle = GetNamedRendertargetRenderId(name)
    end

    return handle
end

function CallScaleformMethod (scaleform, method, ...)
    local t
    local args = { ... }

    BeginScaleformMovieMethod(scaleform, method)

    for k, v in ipairs(args) do
        t = type(v)
        if t == 'string' then
            PushScaleformMovieMethodParameterString(v)
        elseif t == 'number' then
            if string.match(tostring(v), "%.") then
                PushScaleformMovieFunctionParameterFloat(v)
            else
                PushScaleformMovieFunctionParameterInt(v)
            end
        elseif t == 'boolean' then
            PushScaleformMovieMethodParameterBool(v)
        end
    end
    EndScaleformMovieMethod()
end