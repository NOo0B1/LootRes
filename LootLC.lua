local LootLC = CreateFrame("Frame", "LootLC", GameTooltip)
local linkTimer = CreateFrame("Frame")
local VoteButtonFrame = CreateFrame("Frame", "VoteButtonFrame", UIParent)
local TitleFrame = CreateFrame("Frame", "VoteButtonFrame", VoteButtonFrame)
local comms = CreateFrame("Frame")
local resetVoteButton = CreateFrame("button", "resetVoteButton", VoteButtonFrame, "UIPanelButtonTemplate")

local itemLinkButton = CreateFrame("button", "itemLinkButton", VoteButtonFrame, "UIPanelButtonTemplate")

local closeVoteWindowButton = CreateFrame("button", "CloseWindowButton", VoteButtonFrame, "UIPanelButtonTemplate")
local voterListFrame = CreateFrame("Frame", "voterListFrame", VoteButtonFrame)

function print(a)
    DEFAULT_CHAT_FRAME:AddMessage(a)
end

local addonVer = "1.0.8c"

linkTimer:Hide()
linkTimer:SetScript("OnShow", function()
    this.startTime = math.floor(GetTime());
end)


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

VoteButtonFrame:SetScript("OnShow", function()
    this.startTime = math.floor(GetTime());
    this.timePassed = 0
    this.timeToVote = 30
end)

LootLC:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
LootLC:RegisterEvent("CHAT_MSG_RAID")
LootLC:RegisterEvent("CHAT_MSG_RAID_LEADER")
comms:RegisterEvent("CHAT_MSG_ADDON")

local secondsToRoll = 10
local T = 1 --start
local C = secondsToRoll --count to

local timerChannel = "RAID_WARNING"
local lcItem = ""
local linksOpen = false

voterListFrame.voters = {}

VoteButtonFrame.waitingForVotes = false

SLASH_LC1 = "/lc"
SlashCmdList["LC"] = function(cmd)
    if (cmd) then
        if (cmd == 'show') then
            VoteButtonFrame.waitingForVotes = false
            VoteButtonFrame:Show()
        end
        if (cmd == 'who') then
            print("Listing people with the addon (* = can vote):")
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
            lcWho()
        end
    end
end

VoteButtonFrame:SetScript("OnUpdate", function()

    if (not this.waitingForVotes) then
        return
    end

    if (math.floor(GetTime()) == math.floor(this.startTime) + 1) then
        if (this.timePassed >= this.timeToVote) then
            closeVoteWindowButton:Enable()
            closeVoteWindowButton:SetText("Close")

            local voters = ""
            local i = 0
            for n, k in next, voterListFrame.voters do
                i = i + 1
                if (k) then
                    voters = voters .. getColor(n) .. n .. " "
                end
                if i > 4 then voters = voters .. "\n" end
            end
            voterListFrame.text:SetText(voters)
        else
            closeVoteWindowButton:Disable()
            this.timePassed = this.timePassed + 1
            this.startTime = math.floor(GetTime())
            closeVoteWindowButton:SetText("Please Vote (" .. this.timeToVote - this.timePassed .. ")")
        end
    end
end)

LootLC:SetScript("OnEvent", function()

    if (event) then
        if ((event == 'CHAT_MSG_RAID' or event == 'CHAT_MSG_RAID_LEADER') and linksOpen) then
            VoteButtonFrame:CheckLinks(arg1, arg2)
        end
        if (event == 'CHAT_MSG_RAID' or event == 'CHAT_MSG_RAID_LEADER') then
            if (IsRaidLeader()) then
                resetVoteButton:Show()
            else
                resetVoteButton:Hide()
            end
        end
    end

    local score, r, g, b = LootLC:ScanUnit("mouseover")
end)

function VoteButtonFrame:CheckLinks(message, author)
    if (not string.find(message, 'LC:', 1)) then
        if (string.find(message, "[", 1, true)) then
            -- item
            local exists = false
            for name, votes in next, VoteButtonFrame.votes do
                if (name == author) then
                    exists = true
                end
            end

            if (not exists) then
                VoteButtonFrame.votes[author] = 0
            end
        else
            -- random shit chat in raid
        end
    end
end

LootLC:SetScript("OnHide", function()
    GameTooltip.itemLink = nil
end)

function LootLC:ScanUnit(target)
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
            for n, v in next, VoteButtonFrame.votes do
                j = j + 1
            end

            if (j > 0) then
                VoteButtonFrame:AddPlayers()
                VoteButtonFrame:SetHeight(150 + j * 24)
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

        VoteButtonFrame:SendReset()

        local _, _, itemLink = string.find(GameTooltip.itemLink, "(item:%d+:%d+:%d+:%d+)");
        local itemName, _, itemRarity, _, _, _, _, itemSlot, _ = GetItemInfo(itemLink)

        local r, g, b = GetItemQualityColor(itemRarity)

        linkTimer:Hide()

        T = 1 --start
        C = secondsToRoll --count to / to link

        SendChatMessage(" " .. GameTooltip.itemLink .. " LINK (" .. secondsToRoll .. " Seconds)", timerChannel);
        itemLinkButton:SetText(GameTooltip.itemLink)
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

itemLinkButton:SetHeight(24)
itemLinkButton:SetWidth(256)
itemLinkButton:SetPoint("TOP", VoteButtonFrame, "TOP", 0, -5)
itemLinkButton:SetText("[item will be here]")
itemLinkButton:SetNormalTexture("")
itemLinkButton:SetPushedTexture("")
itemLinkButton:SetHighlightTexture("")
itemLinkButton:SetBackdropBorderColor(1, 1, 1)
itemLinkButton:Show()


voterListFrame:SetWidth(256)
voterListFrame:SetHeight(20)
voterListFrame:SetMovable(false)
voterListFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    tile = true,
    tileSize = 16,
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})

voterListFrame:SetBackdropBorderColor(.5, .5, .5)
voterListFrame:SetBackdropColor(0, 0, 0)
voterListFrame:ClearAllPoints()
voterListFrame:EnableMouse(true)

voterListFrame.text = voterListFrame:CreateFontString(nil, "ARTWORK")
voterListFrame.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
voterListFrame.text:SetPoint("TOP", VoteButtonFrame, "TOP", 0, -27)
voterListFrame.text:SetText('Voters: ')

TitleFrame:SetWidth(256)
TitleFrame:SetHeight(25)
TitleFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    tile = true,
    tileSize = 16,
    --    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    --    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})


TitleFrame.text = TitleFrame:CreateFontString(nil, "ARTWORK")
TitleFrame.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
TitleFrame.text:SetPoint("TOP", TitleFrame, "TOP", 0, -5)
TitleFrame.text:SetText('Turtle WoW BWL Loot Council Vote Addon')
TitleFrame:SetBackdropBorderColor(.5, .5, .5)
TitleFrame:SetBackdropColor(0, 0, 0)
TitleFrame:SetPoint("TOP", VoteButtonFrame, "TOP", 0, 18)
TitleFrame:EnableMouse(true)
TitleFrame:RegisterForDrag("LeftButton")
TitleFrame:SetScript("OnDragStart", function() VoteButtonFrame:StartMoving() end)
TitleFrame:SetScript("OnDragStop", function()
    VoteButtonFrame:StopMovingOrSizing()
end)


VoteButtonFrame:SetWidth(256)
VoteButtonFrame:SetHeight(150)
VoteButtonFrame:SetMovable(true)

VoteButtonFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    tile = true,
    tileSize = 16,
    --    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    --    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})

VoteButtonFrame:SetBackdropBorderColor(.5, .5, .5)
VoteButtonFrame:SetBackdropColor(0, 0, 0)
VoteButtonFrame:ClearAllPoints()
VoteButtonFrame:EnableMouse(true)
VoteButtonFrame:RegisterForDrag("LeftButton")
VoteButtonFrame:SetMovable(true)
VoteButtonFrame:SetScript("OnDragStart", function() this:StartMoving() end)
VoteButtonFrame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
end)

closeVoteWindowButton:SetHeight(24)
closeVoteWindowButton:SetWidth(100)
closeVoteWindowButton:SetPoint("BOTTOMLEFT", VoteButtonFrame, "BOTTOMLEFT", 5, 5)
closeVoteWindowButton:SetText("Close")
closeVoteWindowButton:SetScript("OnClick", function(self)
    VoteButtonFrame:Hide()
end)
closeVoteWindowButton:Show()

resetVoteButton:Hide()
resetVoteButton:SetHeight(24)
resetVoteButton:SetWidth(80)
resetVoteButton:SetPoint("BOTTOMRIGHT", VoteButtonFrame, "BOTTOMRIGHT", -5, 5)
resetVoteButton:SetText("Reset Votes")
resetVoteButton:SetScript("OnClick", function(self)
    VoteButtonFrame:SendReset()
end)
if (IsRaidLeader()) then
    resetVoteButton:Show()
end

VoteButtonFrame:SetPoint("CENTER", 0, 0)
VoteButtonFrame:Hide()

VoteButtonFrame.playerFrames = {}
VoteButtonFrame.votes = {}
VoteButtonFrame.myVote = ""

function VoteButtonFrame:AddPlayers()

    local i = 0;
    local names = ""
    for name, votes in next, VoteButtonFrame.votes do
        i = i + 1
        if (not VoteButtonFrame.playerFrames[i]) then
            VoteButtonFrame.playerFrames[i] = CreateFrame("button", "playerNameButton" .. i, VoteButtonFrame, "UIPanelButtonTemplate")
        end

        VoteButtonFrame.playerFrames[i]:SetHeight(24)
        VoteButtonFrame.playerFrames[i]:SetWidth(100)
        VoteButtonFrame.playerFrames[i]:SetPoint("TOP", VoteButtonFrame, "TOP", 0, -35 - (25 * i))
        VoteButtonFrame.playerFrames[i]:SetText(name .. " (" .. votes .. ")")

        local cc = classColors["priest"]

        for i = 0, GetNumRaidMembers() do
            if (GetRaidRosterInfo(i)) then
                local n, r, s, l, c = GetRaidRosterInfo(i);
                if (n == name) then
                    cc = classColors[string.lower(c)]
                    break
                end
            end
        end

        VoteButtonFrame.playerFrames[i]:SetTextColor(cc.r, cc.g, cc.b);

        VoteButtonFrame.playerFrames[i]:SetID(i)
        VoteButtonFrame.playerFrames[i]:SetScript("OnClick", function(self, button, down)
            this.nameFromTextex = string.split(this:GetText(), " ")
            this.nameFromText = this.nameFromTextex[1]
            VoteButtonFrame:Vote(this.nameFromText)
        end)
        VoteButtonFrame.playerFrames[i]:Show()

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
                VoteButtonFrame.waitingForVotes = true
                VoteButtonFrame:Show()
            end
        end
    end
end

function VoteButtonFrame:Vote(voteName)
    local i = 0
    for name, votes in next, VoteButtonFrame.votes do
        i = i + 1
        if (name == voteName) then
            if (VoteButtonFrame.myVote == "") then
                VoteButtonFrame.votes[name] = VoteButtonFrame.votes[name] + 1
                VoteButtonFrame.myVote = voteName
                SendAddonMessage("TWLC", "myVote:+:" .. voteName, "RAID")
            else
                VoteButtonFrame.votes[name] = VoteButtonFrame.votes[name] - 1
                SendAddonMessage("TWLC", "myVote:-:" .. voteName, "RAID")
                VoteButtonFrame.myVote = ""
            end
        else
            -- lock all others
            VoteButtonFrame.playerFrames[i]:Disable()
        end
    end

    if (VoteButtonFrame.myVote == "") then
        -- unlockall
        local j = 0
        for name, votes in next, VoteButtonFrame.votes do
            j = j + 1
            VoteButtonFrame.playerFrames[j]:Enable()
        end
    end

    VoteButtonFrame:UpdateView()
end

function VoteButtonFrame:UpdateView()
    local i = 0
    local totalVotes = 0
    for name, votes in next, VoteButtonFrame.votes do
        i = i + 1
        totalVotes = totalVotes + votes
        VoteButtonFrame.playerFrames[i]:SetText(name .. " (" .. votes .. ")")
    end
end

function VoteButtonFrame:SendReset()
    VoteButtonFrame:ResetVars()
    SendAddonMessage("TWLC", "command:reset", "RAID")
end

function VoteButtonFrame:ResetVars()
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
    for name, votes in next, VoteButtonFrame.votes do
        i = i + 1
        VoteButtonFrame.playerFrames[i]:Hide()
    end
    VoteButtonFrame:Hide()
    VoteButtonFrame.playerFrames = {}
    VoteButtonFrame.votes = {}
    VoteButtonFrame.myVote = ""
    VoteButtonFrame:SetHeight(100)

    voterListFrame.text:SetText('Waiting for votes...')
    voterListFrame.voters = {}
    voterListFrame.waitingForVotes = false
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
                        voterListFrame.voters[arg4] = true
                    else
                        voterListFrame.voters[arg4] = false
                    end
                    local numberOfVoters = 0
                    for n, k in next, voterListFrame.voters do
                        if (k) then
                            numberOfVoters = numberOfVoters + 1
                        end
                    end
                    if (numberOfVoters == 1) then
                        voterListFrame.text:SetText(numberOfVoters .. ' vote')
                    else
                        voterListFrame.text:SetText(numberOfVoters .. ' votes')
                    end
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
        if (i[2] == UnitName('player')) then
            print("[LC] - " .. i[3] .. " (ver. " .. i[4] .. ")")
        end
    end
    if (string.find(t, 'command:', 1)) then
        local com = string.split(t, ":")
        if (com[2] == "reset") then
            VoteButtonFrame:ResetVars()
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
            VoteButtonFrame.votes[player] = 0
        end
        VoteButtonFrame:SetHeight(150 + k * 24)
        VoteButtonFrame:AddPlayers()
    end
    if (string.find(t, 'myVote:', 1)) then
        --                print(t)
        local vote = string.split(t, ':')
        local i = 0
        for name, votes in next, VoteButtonFrame.votes do
            if (name == vote[3]) then
                if (vote[2] == '+') then
                    VoteButtonFrame.votes[name] = VoteButtonFrame.votes[name] + 1
                else
                    VoteButtonFrame.votes[name] = VoteButtonFrame.votes[name] - 1
                end
            end
        end

        VoteButtonFrame:UpdateView()
    end
end

function lcWho()
    SendAddonMessage("TWLC", "command:who", "RAID")
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
