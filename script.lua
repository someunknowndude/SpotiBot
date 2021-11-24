--_G.token = "token here"
if not _G.token then return printconsole("[SpotiBot] ERROR: no API token provided",255,0,0) end

local token = _G.token
local market = "US"
local http = game:GetService("HttpService")

local function chat(msg)
    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg,"All")
end

local function getmarkets()
    local req = syn.request({
        Url = "https://api.spotify.com/v1/markets",
        Method = "GET",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
            ["Authorization"] = "Bearer " .. token
        }
    })
    print(req.StatusCode)
    return http:JSONDecode(req.Body)["markets"]
end

local function changemarket(str)
    local caps = str:upper()
    local markets = getmarkets()
    
    if table.find(markets,caps) then
        market = caps
        chat("Changed market to " .. caps)
    else
        chat(caps .. " is not a valid market id.")
    end
end

local function searchsong(name)
    local subbed
    local search
    if name:find("spotify:track:") == true then
        search = name
    elseif name:find("https\:\/\/open\.spotify.com\/track\/") then
        local noSi = name:split("?")[1]
        subbed = noSi:gsub("https\:\/\/open\.spotify.com\/track\/","")
        search = subbed
    else
        search = http:UrlEncode(name)
    end
    local req = syn.request({
        Url = "https://api.spotify.com/v1/search?q=" .. search .. "&type=track&market=" .. market .. "&limit=1&offset=1",
        Method = "GET",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
            ["Authorization"] = "Bearer " .. token
        }
    })
    --return req.Body
    if subbed then
        return "spotify:track:" .. subbed
    end
    if name:find("spotify:track:") then 
        return name
    else
        if http:JSONDecode(req.Body).tracks.items[1] then
            return http:JSONDecode(req.Body).tracks.items[1].uri
        else
            chat("No song found.")
            return printconsole("[SpotiBot] ERROR: no track found with query: " .. search,255,0,0)
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
        addqueue(searched)
        startplaying()
    else
        chat("Invalid search.")
    end
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
        chat("Invalid volume, must be a percentage.")
    end
end

local function saycp()
    local req = syn.request({
        Url = "https://api.spotify.com/v1/me/player/currently-playing?market=" .. market,
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
    chat("Current commands: play <spotify:track: or query>, pause, resume, skip, volume, currentlyplaying/cp, togglepublic, ispublic, market")
end
local publiccmds = false

local function loadcmds(v)
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
                task.wait()
                chat("Allow usage for others: " .. tostring(publiccmds))
            end
            if msg == "#ispublic" then
                chat("Is currently public: " .. tostring(publiccmds))
            end
            if msg == "#rj" then
                game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
            end
            if msg:sub(1,#"#market ") == "#market " then
                local selected = msg:sub(#"#market  ",-1)
                changemarket(selected)
            end
        end
    end)
end

for i,v in pairs(game.Players:GetPlayers()) do
   loadcmds(v)
end
game.Players.PlayerAdded:Connect(loadcmds)
--skipsong()
chat("SpotiBot V0.8 by quirky anime boy started, type #cmds to begin.") 
