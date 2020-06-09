local LootLCTooltip = CreateFrame("Frame", "LootLC", GameTooltip)

local linkTimer = CreateFrame("Frame")

local comms = CreateFrame("Frame")
local resetVoteButton = CreateFrame("Frame", "LCResetVoteButton")

local PeoplWhoVotedFrame = CreateFrame("Frame", "PeoplWhoVotedFrame")

local whoResponderTimer = CreateFrame("Frame", "whoResponderTimer")
whoResponderTimer:Hide()
whoResponderTimer:SetScript("OnShow", function()
    this.startTime = math.floor(GetTime());
end)

local LootLC = CreateFrame("Frame")
LootLC:Hide()

function print(a)
    DEFAULT_CHAT_FRAME:AddMessage(a)
end

local addonVer = "1.1.0"

linkTimer:Hide()
linkTimer:SetScript("OnShow", function()
    this.startTime = math.floor(GetTime());
end)


local roster = {};

function resetRoster()
    roster = {
        ["Smultron"] = false,
        ["Ilmane"] = false,
        ["Tyrelys"] = false,
        ["Babagiega"] = false,
        ["Faralynn"] = false,
        ["Momo"] = false,
        ["Trepp"] = false,
        ["Chlo"] = false,
        ["Er"] = false,
        ["Chlothar"] = false,
        ["Aurelian"] = false,
        --        ["Cosmort"] = false, --dev
        --        ["Xerrbear"] = false --dev
    }
end

local classColors = {
    ["warrior"] = { r = 0.78, g = 0.61, b = 0.43, c = "|cffc79c6e" },
    ["mage"] = { r = 0.41, g = 0.8, b = 0.94, c = "|cff69ccf0" },
    ["rogue"] = { r = 1, g = 0.96, b = 0.41, c = "|cfffff569" },
    ["druid"] = { r = 1, g = 0.49, b = 0.04, c = "|cffff7d0a" },
    ["hunter"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cffabd473" },
    ["shaman"] = { r = 0.14, g = 0.35, b = 1.0, c = "|cff0070de" },
    ["priest"] = { r = 1, g = 1, b = 1, c = "|cffffffff" },
    ["warlock"] = { r = 0.58, g = 0.51, b = 0.79, c = "|cff9482c9" },
    ["paladin"] = { r = 0.96, g = 0.55, b = 0.73, c = "|cfff58cba" },
}

function getColor(p)
    if p == "Smultron" then return classColors["warrior"].c end
    if p == "Ilmane" then return classColors["shaman"].c end
    if p == "Tyrelys" then return classColors["rogue"].c end
    if p == "Babagiega" then return classColors["warlock"].c end
    if p == "Faralynn" then return classColors["druid"].c end
    if p == "Momo" or p == "Trepp" then return classColors["mage"].c end
    if p == "Chlo" then return classColors["hunter"].c end
    if p == "Er" then return classColors["priest"].c end
    if p == "Chlothar" or p == "Aurelian" then return classColors["paladin"].c end
    if p == "Cosmort" then return classColors["warlock"].c end
    if p == "Xerrbear" then return classColors["druid"].c end
    return ""
end

function getRGBColor(p)
    if p == "Smultron" then return classColors["warrior"] end
    if p == "Ilmane" then return classColors["shaman"] end
    if p == "Tyrelys" then return classColors["rogue"] end
    if p == "Babagiega" then return classColors["warlock"] end
    if p == "Faralynn" then return classColors["druid"] end
    if p == "Momo" or p == "Trepp" then return classColors["mage"] end
    if p == "Chlo" then return classColors["hunter"] end
    if p == "Er" then return classColors["priest"] end
    if p == "Chlothar" or p == "Aurelian" then return classColors["paladin"] end
    if p == "Cosmort" then return classColors["warlock"] end
    if p == "Xerrbear" then return classColors["druid"] end
    return classColors["priest"]
end

LootLC:SetScript("OnShow", function()
    this.startTime = math.floor(GetTime());
    this.timePassed = 0
    this.timeToVote = 30
end)

LootLCTooltip:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
LootLCTooltip:RegisterEvent("CHAT_MSG_RAID")
LootLCTooltip:RegisterEvent("CHAT_MSG_RAID_LEADER")
comms:RegisterEvent("CHAT_MSG_ADDON")

local secondsToRoll = 5
local T = 1 --start
local C = secondsToRoll --count to

local timerChannel = "RAID_WARNING"
local lcItem = ""
local linksOpen = false

PeoplWhoVotedFrame.voters = {}

LootLC.waitingForVotes = false
LootLC.totalVotes = 0
LootLC.timeLeft = 0

SLASH_LC1 = "/lc"
SlashCmdList["LC"] = function(cmd)
    if (cmd) then
        if (cmd == 'show') then
            LootLC.waitingForVotes = false
            getglobal("LootLCWindow"):Show()
        end
        if (cmd == 'who') then
            print("Listing people with the addon (* = can vote):")
            resetRoster()
            local canVote = false
            for i = 0, GetNumRaidMembers() do
                if (GetRaidRosterInfo(i)) then
                    local n, r = GetRaidRosterInfo(i);
                    if (n == UnitName('player') and (r == 1 or r == 2)) then
                        canVote = true
                    end
                end
            end
            if (canVote) then
                print("[LC] - *" .. UnitName('player') .. " (ver. " .. addonVer .. ")")
            else
                print("[LC] - " .. UnitName('player') .. " (ver. " .. addonVer .. ")")
            end
            if (roster[UnitName('player')] ~= nil) then
                roster[UnitName('player')] = true
            end
            lcWho()
        end
    end
end

LootLC:SetScript("OnUpdate", function()

    if (not this.waitingForVotes) then
        return
    end

    if (math.floor(GetTime()) == math.floor(this.startTime) + 1) then
        if (this.timePassed >= this.timeToVote) then
            if (LootLC.myVote == "") then
                getglobal("LCCloseButton"):Disable()
            else
                getglobal("LCCloseButton"):Enable()
            end

            local voters = ""
            local i = 0
            for n, k in next, PeoplWhoVotedFrame.voters do
                i = i + 1
                if (k) then
                    voters = voters .. getColor(n) .. n .. " "
                end
                if i > 4 then voters = voters .. "\n" end
            end
            getglobal('PeopleWhoVotedNames'):SetText(voters)
        else

            if (LootLC.myVote == "") then
                getglobal("LCCloseButton"):Disable()
            else
                getglobal("LCCloseButton"):Enable()
            end

            this.timePassed = this.timePassed + 1
            this.startTime = math.floor(GetTime())
            LootLC.timeLeft = this.timeToVote - this.timePassed
            LootLC:UpdatePleaseVote()
        end
    end
end)

LootLCTooltip:SetScript("OnEvent", function()

    if (event) then
        if ((event == 'CHAT_MSG_RAID' or event == 'CHAT_MSG_RAID_LEADER') and linksOpen) then
            LootLC:CheckLinks(arg1, arg2)
        end
        if (event == 'CHAT_MSG_RAID' or event == 'CHAT_MSG_RAID_LEADER') then
            if (IsRaidLeader()) then
                resetVoteButton:Show()
            else
                resetVoteButton:Hide()
            end
        end
    end

    local score, r, g, b = LootLCTooltip:ScanUnit("mouseover")
end)

function LootLC:CheckLinks(message, author)
    if (not string.find(message, 'LC:', 1)) then
        if (string.find(message, "[", 1, true)) then
            -- item
            local exists = false
            for name, votes in next, LootLC.votes do
                if (name == author) then
                    exists = true
                end
            end

            if (not exists) then
                LootLC.votes[author] = 0
            end
        else
            -- random shit chat in raid
        end
    end
end

LootLCTooltip:SetScript("OnHide", function()
    GameTooltip.itemLink = nil
end)

function LootLCTooltip:ScanUnit(target)
    if not UnitIsPlayer(target) then return nil end
    return 0, 0, 0, 0
end

local LootResHookSetBagItem = GameTooltip.SetBagItem
function GameTooltip.SetBagItem(self, container, slot)
    GameTooltip.itemLink = GetContainerItemLink(container, slot)
    _, GameTooltip.itemCount = GetContainerItemInfo(container, slot)
    return LootResHookSetBagItem(self, container, slot)
end

local LootResHookSetLootItem = GameTooltip.SetLootItem
function GameTooltip.SetLootItem(self, slot)
    GameTooltip.itemLink = GetLootSlotLink(slot)
    LootResHookSetLootItem(self, slot)
end

whoResponderTimer:SetScript("OnUpdate", function()
    -- wait for 5 seconds before outputting who responded to who command
    if (math.floor(GetTime()) == math.floor(this.startTime) + 5) then
        local missingAddonList = ""
        for player, response in next, roster do
            if (not response) then
                missingAddonList = missingAddonList .. " " .. player
            end
        end
        print("People without addon: " .. missingAddonList)
        this:Hide()
    end
end)

linkTimer:SetScript("OnUpdate", function()
    if (math.floor(GetTime()) == math.floor(this.startTime) + 1) then
        if (T ~= secondsToRoll + 1) then
            SendChatMessage("LC: " .. (C - T + 1) .. "", "RAID")
        end
        linkTimer:Hide()
        if (T < C + 1) then
            T = T + 1
            linkTimer:Show()
        elseif (T == secondsToRoll + 1) then
            SendChatMessage("LC: Closed", timerChannel)
            linkTimer:Hide()
            T = 1
            linksOpen = false

            local j = 0
            for n, v in next, LootLC.votes do
                j = j + 1
            end

            if (j > 0) then
                LootLC:AddPlayers()
                getglobal("LootLCWindow"):SetHeight(200 + j * 40)
            else
                DEFAULT_CHAT_FRAME:AddMessage("LC: Nobody wants it")
            end

        else
            --
        end
    else
        --
    end
end)

function BWLLoot()

    if (not UnitInRaid('player')) then
        DEFAULT_CHAT_FRAME:AddMessage("LC: You are not in a raid.")
        return
    end

    if (not IsRaidLeader()) then
        DEFAULT_CHAT_FRAME:AddMessage("LC: You're not Raid Leader.")
        return
    end

    if GameTooltip.itemLink then

        LootLC:SendReset()

        local _, _, itemLink = string.find(GameTooltip.itemLink, "(item:%d+:%d+:%d+:%d+)");
        local itemName, _, itemRarity, _, _, _, _, itemSlot, _ = GetItemInfo(itemLink)

        local r, g, b = GetItemQualityColor(itemRarity)

        linkTimer:Hide()

        T = 1 --start
        C = secondsToRoll --count to / to link

        SendChatMessage(" " .. GameTooltip.itemLink .. " LINK (" .. secondsToRoll .. " Seconds)", timerChannel);
        getglobal("itemLinkButton"):SetText(GameTooltip.itemLink)
        itemLinkButton:SetScript("OnClick", function(self)
            SetItemRef(itemLink)
        end)

        lcItem = itemLink .. "~" .. GameTooltip.itemLink

        linkTimer:Show()
        linksOpen = true
    else
        DEFAULT_CHAT_FRAME:AddMessage("LC: GameTooltip.itemLink = nil")
    end
end

--closeVoteWindowButton:SetScript("OnClick", function(self)
--    LootLCWindow:Hide()
--end)
--
function ResetVoteButton_OnClick()
    LootLC:SendReset()
end

--if (IsRaidLeader()) then
--    resetVoteButton:Show()
--end

--getglobal("LootLCWindow"):Hide()

LootLC.playerFrames = {}
LootLC.votes = {}
LootLC.myVote = ""

function LootLC:AddPlayers()

    local i = 0;
    local names = ""
    for name, votes in next, LootLC.votes do
        i = i + 1
        if (not LootLC.playerFrames[i]) then
            LootLC.playerFrames[i] = CreateFrame("Frame", "PlayerWantsFrame" .. i, getglobal("LootLCWindow"), "PlayerWantsFrameTemplate")
        end

        LootLC.playerFrames[i]:SetPoint("TOP", getglobal("VotedItemFrame"), "TOP", 0, -10 - (45 * i))

        getglobal("PlayerWantsFrame" .. i .. "Name"):SetText(name);

        local cc = classColors["priest"]

        for i = 0, GetNumRaidMembers() do
            if (GetRaidRosterInfo(i)) then
                local n, r, s, l, c = GetRaidRosterInfo(i);
                if (n == name) then
                    if classColors[string.lower(c)] then
                        cc = classColors[string.lower(c)]
                    end
                    break
                end
            end
        end

        -- todo
        getglobal("PlayerWantsFrame" .. i .. "VoteButton"):SetID(i)
        getglobal("PlayerWantsFrame" .. i .. "VoteButton"):SetScript("OnClick", function(self, button, down)
            this.nameFromTextex = string.split(getglobal("PlayerWantsFrame" .. i .. "Name"):GetText(), " ")
            this.nameFromText = this.nameFromTextex[1]
            LootLC:Vote(this.nameFromText)
        end)
        --        getglobal("PlayerWantsFrame" .. i):Show()

        names = names .. " " .. name
    end

    if (IsRaidLeader() and names ~= "") then
        names = trim(names)
        SendAddonMessage("TWLC", "item~" .. lcItem, "RAID")
        SendAddonMessage("TWLC", "players:" .. names, "RAID")
    end


    for i = 0, GetNumRaidMembers() do
        if (GetRaidRosterInfo(i)) then
            local n, r = GetRaidRosterInfo(i);
            if (n == UnitName('player') and (r == 1 or r == 2)) then
                LootLC.waitingForVotes = true
                getglobal("LootLCWindow"):Show()
                LootLC:Show() -- start voting timer
            end
        end
    end
end

function LootLC:Vote(voteName)
    local i = 0
    for name, votes in next, LootLC.votes do
        i = i + 1
        if (name == voteName) then
            if (LootLC.myVote == "") then
                LootLC.votes[name] = LootLC.votes[name] + 1
                LootLC.myVote = voteName
                SendAddonMessage("TWLC", "myVote:+:" .. voteName, "RAID")
            else
                LootLC.votes[name] = LootLC.votes[name] - 1
                SendAddonMessage("TWLC", "myVote:-:" .. voteName, "RAID")
                LootLC.myVote = ""
            end
        else
            -- lock all others
            getglobal("LCCloseButton"):Enable()
            getglobal("PlayerWantsFrame" .. i .. "VoteButton"):Disable()
        end
    end

    if (LootLC.myVote == "") then
        -- unlockall
        getglobal("LCCloseButton"):Disable()
        local j = 0
        for name, votes in next, LootLC.votes do
            j = j + 1
            getglobal("PlayerWantsFrame" .. j .. "VoteButton"):Enable()
        end
    end

    LootLC:UpdateView()
end

function LootLC:UpdateView()
    local i = 0
    LootLC.totalVotes = 0
    for name, votes in next, LootLC.votes do
        i = i + 1
        LootLC.totalVotes = LootLC.totalVotes + votes
        getglobal("PlayerWantsFrame" .. i .. "Votes"):SetText(votes)
        LootLC:UpdatePleaseVote()
    end
end

function LootLC:UpdatePleaseVote()
    getglobal("VotingOpenTimerText"):SetText("Please vote (" .. LootLC.totalVotes .. "/11) - (" .. LootLC.timeLeft .. "s)")
end

function LootLC:SendReset()
    LootLC:ResetVars()
    SendAddonMessage("TWLC", "command:reset", "RAID")
end

function LootLC:ResetVars()
    local i = 0
    for i = 0, GetNumRaidMembers() do
        if (GetRaidRosterInfo(i)) then
            local n, r = GetRaidRosterInfo(i);
            if (n == UnitName('player') and (r == 1 or r == 2)) then
                DEFAULT_CHAT_FRAME:AddMessage("LC: Voting reset.")
            end
        end
    end
    i = 0
    for name, votes in next, LootLC.votes do
        i = i + 1
        LootLC.playerFrames[i]:Hide()
    end
    getglobal("LootLCWindow"):Hide()
    LootLC.playerFrames = {}
    LootLC.votes = {}
    LootLC.myVote = ""
    getglobal("LootLCWindow"):SetHeight(100)

    getglobal("PeopleWhoVotedNames"):SetText('Waiting for votes...')
    PeoplWhoVotedFrame.voters = {}
    PeoplWhoVotedFrame.waitingForVotes = false
end

-- comms

comms:SetScript("OnEvent", function()
    if (event) then
        if (event == 'CHAT_MSG_ADDON') then

            if (IsRaidLeader()) then
                resetVoteButton:Show()
            else
                resetVoteButton:Hide()
            end

            if (arg1 == "TWLC" and arg4 ~= UnitName("player")) then
                comms:recSync(arg1, arg2, arg3, arg4)
            end
            -- vote counter
            if (arg1 == "TWLC") then
                if (string.find(arg2, 'myVote:', 1)) then
                    local vote = string.split(arg2, ':')
                    -- myVote:+:Tyrelys
                    if (vote[2] == '+') then
                        PeoplWhoVotedFrame.voters[arg4] = true
                    else
                        PeoplWhoVotedFrame.voters[arg4] = false
                    end
                    local numberOfVoters = 0
                    for n, k in next, PeoplWhoVotedFrame.voters do
                        if (k) then
                            numberOfVoters = numberOfVoters + 1
                        end
                    end
                    LootLC:UpdatePleaseVote()
                end
            end
        end
    end
end)


function comms:recSync(p, t, c, s) -- prefix, text, channel, sender
    if (string.find(t, 'item~', 1)) then
        local i = string.split(t, "~")
        itemLinkButton:SetText(i[3])
        itemLinkButton:SetScript("OnClick", function(self)
            SetItemRef(i[2])
        end)
    end
    if (string.find(t, 'withAddon:', 1)) then
        local i = string.split(t, ":")
        if (i[2] == UnitName('player')) then --i[2] = who requested the who
            if (roster[i[3]] ~= nil) then
                roster[i[3]] = true --i[3] = responder's name
            end
            if (i[4]) then
                print("[LC] - " .. i[3] .. " (ver. " .. i[4] .. ")")
            else
                print("[LC] - " .. i[3] .. " (ver. unknown)")
            end
        end
    end
    if (string.find(t, 'command:', 1)) then
        local com = string.split(t, ":")
        if (com[2] == "reset") then
            LootLC:ResetVars()
        end
        if (com[2] == "who") then
            local i = 0
            local canVote = false
            for i = 0, GetNumRaidMembers() do
                if (GetRaidRosterInfo(i)) then
                    local n, r = GetRaidRosterInfo(i);
                    if (n == UnitName('player') and (r == 1 or r == 2)) then
                        canVote = true
                    end
                end
            end
            if (canVote) then
                SendAddonMessage("TWLC", "withAddon:" .. s .. ":*" .. UnitName('player') .. ":" .. addonVer, "RAID")
            else
                SendAddonMessage("TWLC", "withAddon:" .. s .. ":" .. UnitName('player') .. ":" .. addonVer, "RAID")
            end
        end
    end
    if (string.find(t, 'players:', 1)) then
        local wdp = string.split(t, ":")
        local players = string.split(wdp[2], " ")
        local k = 0
        for index, player in players do
            k = k + 1
            LootLC.votes[player] = 0
        end
        getglobal("LootLCWindow"):SetHeight(150 + k * 24)
        LootLC:AddPlayers()
    end
    if (string.find(t, 'myVote:', 1)) then
        local vote = string.split(t, ':')
        local i = 0
        for name, votes in next, LootLC.votes do
            if (name == vote[3]) then
                if (vote[2] == '+') then
                    LootLC.votes[name] = LootLC.votes[name] + 1
                else
                    LootLC.votes[name] = LootLC.votes[name] - 1
                end
            end
        end

        LootLC:UpdateView()
    end
end

function lcWho()
    SendAddonMessage("TWLC", "command:who", "RAID")
    whoResponderTimer:Show()
end

-- utils

function trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function string:split(delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(self, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(self, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(self, delimiter, from)
    end
    table.insert(result, string.sub(self, from))
    return result
end
