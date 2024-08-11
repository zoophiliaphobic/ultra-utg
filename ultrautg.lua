local plr = game.Players.LocalPlayer
local cloneref = cloneref or function(v) return v end

local rs = cloneref(game:GetService("ReplicatedStorage"))
local us = cloneref(game:GetService("UserInputService"))
local debris = cloneref(game:GetService("Debris"))
local tweens = cloneref(game:GetService("TweenService"))
local tcs = cloneref(game:GetService("TextChatService"))
local rbxgeneral = tcs:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")

if not (plr:GetAttribute("btools") or plr:GetAttribute("VIP")) then
    rbxgeneral:SendAsync("i need btools")
    repeat task.wait(1) until plr:GetAttribute("btools")
end
rbxgeneral:SendAsync("ultrautg")

local currentmap = workspace:WaitForChild("CurrentMap")

local screengui = Instance.new("ScreenGui",cloneref(game:GetService("CoreGui")))
local mainframe = Instance.new("Frame")

local events = rs:WaitForChild("Events")
local createevents = events:WaitForChild("create")

local remote_createpart = createevents:WaitForChild("CreatePart")
local remote_adjustpart = createevents:WaitForChild("AdjustPart")

local allowreplication = true
local mypart = nil
local playerparts = {}

function createpart(cframe,size,color,cloned)
    return remote_createpart:InvokeServer(cframe,size,color,cloned)
end

function adjustpart(part,properties)
    return remote_adjustpart:InvokeServer(part,properties)
end

function getmap()
    return currentmap:FindFirstChildOfClass("Folder")
end

function quicktween(what,tweeninfo,properties)
    if typeof(tweeninfo) == "number" then
        tweeninfo = TweenInfo.new(tweeninfo,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0)
    end

    tweens:Create(what,tweeninfo,properties):Play()
end

local ACTIONS = {
    [1] = {
        name = "stunall",
        onreplicate = function(begin,user)
            if begin then
                if user ~= plr then
                    local char = plr.Character
                    local userchar = user.Character

                    if userchar and char then
                        local pos = char:GetPivot()

                        local stuntimer = 2
                        while stuntimer > 0 do
                            char.PrimaryPart.AssemblyLinearVelocity = Vector3.new()
                            char:PivotTo(pos)
                            stuntimer -= task.wait(0.1)
                        end

                    end
                end
            end
        end
    },
    [2] = {
        name = "shockwave",
        onreplicate = function(begin,user)
            if begin then
                local char = plr.Character
                local userchar = user.Character

                if userchar and char then
                    local prim = char.PrimaryPart

                    if prim then
                        local origin = userchar:GetPivot().Position
                        local wave = Instance.new("Part")
                        wave.Shape = Enum.PartType.Ball
                        wave.Position = origin
                        wave.Size = Vector3.new()
                        wave.Color = Color3.fromRGB(0,120,255)
                        wave.Material = Enum.Material.Neon
                        wave.Transparency = 0.7
                        wave.CanCollide = false
                        wave.Anchored = true

                        if user ~= plr then
                            local debounce = true
                            wave.Touched:Connect(function(hit)
                                if wave.Transparency < 0.94 then
                                    local hitchar = hit:FindFirstAncestorOfClass("Model")
                                
                                    if hitchar == char then
                                        debounce = false
                                        prim.AssemblyLinearVelocity = (prim.Position-origin).Unit*50

                                        task.wait(0.1)
                                        debounce = true
                                    end
                                end
                            end)
                        end
                        
                        wave.Parent = getmap()
                        quicktween(wave,0.66,{Transparency=1,Size=Vector3.new(45,45,45)})
                        debris:AddItem(wave,0.66)
                    end
                end
            end
        end
    }
}

function useridtopos(userid)
    local str = tostring(userid)
    local halflength = math.ceil(string.len(str)/2)

    local firstbit = string.sub(str,0,halflength)
    local lastbit = string.sub(str,halflength+1,string.len(str))
    local lastlength = string.len(lastbit)

    local leadingzeros = 0
    for i=0,lastlength do
        if string.sub(lastbit,i+1,i+1) == "0" then
            leadingzeros += 1
        else
            break
        end
    end
    
    lastbit = (leadingzeros > 0 and "0." or "")..string.rep("0",leadingzeros-1)..string.sub(lastbit,leadingzeros+1,lastlength)
    lastlength = string.len(lastbit)
    print(firstbit,lastbit)

    local endzero = string.sub(lastbit,lastlength,lastlength) == "0"

    if endzero then
        print("bad")
        --lastbit = lastbit.."1"
    end

    return Vector3.new(
        tonumber(firstbit),
        tonumber(lastbit),
        0
    )
end

function postouserid(pos)
    local xstr,ystr = tostring(math.floor(pos.X)),pos.Y
    local lenmax = string.len(xstr)
    local multimax = 10^(lenmax)
    ystr = math.floor((pos.Y+(0.1/multimax))*multimax)/multimax
    ystr = string.gsub(tostring(ystr),"%.","",1)

    return math.floor(tonumber(xstr..ystr))
end

-- we need this remove zeros function because having ending zeros in
-- a position will automatically remove them. since there isnt any
-- clean way to check for that, just remove the zeros and hope nobody
-- has a similar userid
function removezeros(num)
    local str = tostring(num)
    local length = string.len(str)

    for i=0,length do
        if string.sub(str,length,length) == "0" then
            str = string.sub(str,0,length-1)
            length = length-1
        else
            break
        end
    end

    return tonumber(str)
end

function getactionfromname(name)
    for i,v in pairs(ACTIONS) do
        if v.name == name then
            return v,i
        end
    end
end

function getplayerfrompart(part)
    return playerparts[part]
end

function getpartfromplayer(who)
    local index = 0

    for part,player in pairs(playerparts) do
        index += 1
        if player == who then
            return part,index
        end
    end
end

function playerpartchanged(part)
    local who = getplayerfrompart(part)
    local arg1 = part.Position.Z
    local actbl = ACTIONS[arg1]
    
    if arg1 ~= 0 then
        assert(actbl~=nil,"func '".. tostring(arg1) .."' does not exist yet sorry")
    
        local func = actbl.onreplicate
        print("part: ".. part.Name)
        print(actbl.name)

        if func then
            task.spawn(function()
                func(true,who)
            end)

            part.Changed:Once(function()
                if part.Position.Y ~= arg1 then
                    func(false,who)
                end
            end)
        end
    end
end

function addplayerpart(part)
    local userid = removezeros(postouserid(part.Position))
    local who = game.Players:GetPlayerByUserId(userid)
    
    if who then
        part.Name = who.Name.."'s replicator part"
        print("addpart: ".. userid,who,part)
        if who == plr then
            print("FOUND MY PART!")
            mypart = part
        end
        playerparts[part] = who

        part.Changed:Connect(function()
            playerpartchanged(part)
        end)
    end
end

function getplayerparts()
    for i,v in pairs(getmap():GetChildren()) do
        if v:IsA("BasePart") then
            addplayerpart(v)
        end
    end

    if not mypart then
        local userid = useridtopos(removezeros(plr.UserId))
        print("made new mypart ".. plr.UserId,userid)
        mypart = createpart(CFrame.new(Vector3.new(userid.X,userid.Y,0)),Vector3.new(2,2,2),Color3.fromRGB(255,255,255))
    end
end

function listenforparts()
    local map = getmap() or currentmap.ChildAdded:Wait()

    map.ChildAdded:Connect(function(v)
        if v:IsA("BasePart") then
            addplayerpart(v)
        end
    end)
end

function replicate(funcname1)
    if allowreplication then
        allowreplication = false

        local userid = useridtopos(removezeros(plr.UserId))
        adjustpart(mypart,{CFrame=CFrame.new(Vector3.new(userid.X,userid.Y,0))})

        local functbl1,arg1 = getactionfromname(funcname1)

        print("replicate: ".. arg1,funcname1)

        adjustpart(mypart,{CFrame=CFrame.new(Vector3.new(userid.X,userid.Y,(arg1 or 0)))})
        allowreplication = true
    end
end

currentmap.ChildAdded:Connect(function(v)
    listenforparts()
end)

game.Players.PlayerRemoving:Connect(function(who)
    local part,index = getpartfromplayer(who)

    if part and index then
        table.remove(playerparts,index)
    end
end)

listenforparts()
getplayerparts()

for i,v in pairs(ACTIONS) do
    local name = v.name
    local testbutton = Instance.new("TextButton",screengui)
    testbutton.Position = UDim2.new(0.04*(i-1),0,0.66,0)
    testbutton.Size = UDim2.new(0.04,0,0.06,0)
    testbutton.TextScaled = true
    testbutton.TextColor3 = Color3.new(0,0,0)
    testbutton.BackgroundColor3 = Color3.new(1,1,1)
    testbutton.Text = "[".. i .."] ".. name

    testbutton.MouseButton1Down:Connect(function()
        --testbutton:Destroy()
        replicate(name)
    end)

    us.InputBegan:Connect(function(key,pro)
        if not pro then
            if key.KeyCode.Value == 48+i then
                replicate(name)
            end
        end
    end)
end