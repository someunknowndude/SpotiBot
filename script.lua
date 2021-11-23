local token = "enter your api token here, expires after a couple of hours"



local http = game:GetService("HttpService")

local function searchsong(name) -- have to make a custom search because spotify's api never finds the right song
    local search
    if name:find("spotify:track:") == true then
        search = name
    else
        search = http:UrlEncode(name)
    end
    local req = syn.request({
        Url = "https://api.spotify.com/v1/search?q=" .. search .. "&type=track&market=DE&limit=1&offset=1",
        Method = "GET",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
            ["Authorization"] = "Bearer " .. token
        }
    })
    --return req.Body
    if name:find("spotify:track:") then 
        return name
    else
        if http:JSONDecode(req.Body).tracks.items[1] then
            return http:JSONDecode(req.Body).tracks.items[1].uri
        else
            return nil
        end
    end
end

local function addqueue(trackurl)
    print(trackurl)
    local req = syn.request({
        Url = "https://api.spotify.com/v1/me/player/queue?uri=" .. trackurl,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
            ["Authorization"] = "Bearer " .. token
        }
    })
    return req.StatusCode
end

local function startplaying()
    local req = syn.request({
        Url = "https://api.spotify.com/v1/me/player",
        Method = "GET",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
            ["Authorization"] = "Bearer " .. token
        }
    })
    
    syn.request({
        Url = "https://api.spotify.com/v1/me/player/play",
        Method = "PUT",
        Data = {
            position_ms = req.progress_ms
        },
        Headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
            ["Authorization"] = "Bearer " .. token
        }
    })
end

local function pause()
    syn.request({
        Url = "https://api.spotify.com/v1/me/player/pause",
        Method = "PUT",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
            ["Authorization"] = "Bearer " .. token
        }
    })
end

--for i,v in pairs(searchsong(search)) do
    --print(v)
--end

local function initqueue(search)
    print(search)
    local searched = searchsong(search)
    if searched then
        print(searched)
        setclipboard(searched)
        addqueue(searched)
        startplaying()
    else
        print("invalid search")
    end
end

local function chat(msg)
    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg,"All")
end

local function skipsong()
    print("skipping")
    local req = syn.request({
        Url = "https://api.spotify.com/v1/me/player/next",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
            ["Authorization"] = "Bearer " .. token
        },
        Body = {
        }
    })
end

local function setvolume(vol)
    local volume = tonumber(vol)
    local nr = NumberRange.new(0,100)
    if volume >= nr.Min and volume <= nr.Max then
        print(volume)
        local req = syn.request({
            Url = "https://api.spotify.com/v1/me/player/volume?volume_percent=" .. vol,
            Method = "PUT",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json",
                ["Authorization"] = "Bearer " .. token
            }
        })
    print(req.Body)
    else
        print("invalid volume")
    end
end

local function saycp()
    local req = syn.request({
        Url = "https://api.spotify.com/v1/me/player/currently-playing?market=DE",
        Method = "GET",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
            ["Authorization"] = "Bearer " .. token
        }
    })

    local data = http:JSONDecode(req.Body)
    local trackname = data["item"].name
    local author = data["item"]["album"]["artists"][1].name
    
    chat("Currently playing: " .. trackname .. " by " .. author)
end

local function saycmds()
    wait()
    chat("Current commands: play <spotify:track: or query>, pause, resume, skip, volume, currentlyplaying/cp, togglepublic, ispublic")
end
local publiccmds = false

local function loadcmds(v) -- father forgive me for i have sinned
    v.Chatted:Connect(function(msg)
        if msg == "#skip" then
            if v == game.Players.LocalPlayer or publiccmds == true then
                skipsong()
            end
        elseif msg == "#pause" then
            if v == game.Players.LocalPlayer or publiccmds == true then
                pause()
            end
        elseif msg == "#resume" then
            if v == game.Players.LocalPlayer or publiccmds == true then
                startplaying()
            end
        elseif msg:sub(1,#"#play ") == "#play " then
            if v == game.Players.LocalPlayer or publiccmds == true then
                initqueue(msg:sub(#"#play  ",-1))
            end
        elseif msg:sub(1,#"#currentlyplaying") == "#currentlyplaying" or msg:sub(1,#"#cp") == "#cp" then
            if v == game.Players.LocalPlayer or publiccmds == true then
                saycp()
            end
        elseif msg:sub(1,#"#volume ") == "#volume " then
            if v == game.Players.LocalPlayer or publiccmds == true then
                setvolume(msg:sub(#"#volume  ",-1))
            end
        elseif msg:sub(1,#"#commands") == "#commands" or msg:sub(1,#"#cmds") == "#cmds" then
            if v == game.Players.LocalPlayer or publiccmds == true then
                saycmds()
            end
        end
        if v == game.Players.LocalPlayer then
            if msg == "#togglepublic" then
                publiccmds = not publiccmds
                print("allow usage for others: " .. tostring(publiccmds))
            end
            if msg == "#ispublic" then
                print("is currently public: " .. tostring(publiccmds))
            end
            if msg == "#rj" then
                game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
            end
        end
    end)
end

for i,v in pairs(game.Players:GetPlayers()) do
   loadcmds(v)
end
game.Players.PlayerAdded:Connect(loadcmds)
chat("SpotiBot V0.8 by quirky anime boy started, type #cmds to begin.") -- remove if youre cringe
