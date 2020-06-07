local LootRes = CreateFrame("Frame", "LootRes", GameTooltip)
LootRes:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
LootRes:RegisterEvent("CHAT_MSG_WHISPER")
LootRes:RegisterEvent("CHAT_MSG_SYSTEM")

local rollsOpen = false --rolls
local rollers = {} --list of people who rolled
local maxRoll = 0 --max recorded roll
local reservedNames = "";

local secondsToRoll = 7
local T = 1 --start
local C = secondsToRoll --count to
local lastRolledItem = "" --offspec roll
local offspecRoll = false

LootRes:SetScript("OnEvent", function()

    if (event) then
        if (event == 'CHAT_MSG_WHISPER') then
            if (arg1 == '-mcres') then
                LootRes:CheckMCRes(arg1, arg2)
            elseif (string.find(arg1, '-mcres ', 1)) then
                LootRes:ReserveItem(arg1, arg2)
            end
        elseif (event == 'CHAT_MSG_SYSTEM' and rollsOpen) then
            LootRes:CheckRolls(arg1)
        end
    end

    local score, r, g, b = LootRes:ScanUnit("mouseover")
    if score and r and g and b then
        --        LootRes:AddLine("LootRes1: " .. score, r, g, b)
        --        LootRes:Show()
    end
end)

function LootRes:ReserveItem(text, player)


    local newItem = LootResReplace(text, "-mcres ", "")
    local itemName, _, itemRarity, _, _, _, _, itemSlot, _ = GetItemInfo(newItem)

    print(itemName)

    --    if (lootres_reserves[player] )
end


function LootRes:CheckMCRes(arg1, arg2)

    local foundRes = false

    for playerName, item in next, LootRes:lootres_reserves() do
        if (playerName == arg2) then
            SendChatMessage("LootRes: Your MC Res : [" .. item .. "]", "WHISPER", "Common", arg2);
            foundRes = true
        end
    end

    if (not foundRes) then
        SendChatMessage("LootRes: Your MC Res : -Nothing Reserved-", "WHISPER", "Common", arg2);
    end
end


LootRes:SetScript("OnShow", function()

    local reservedNumber = 0
    if GameTooltip.itemLink then
        local _, _, itemLink = string.find(GameTooltip.itemLink, "(item:%d+:%d+:%d+:%d+)");

        local itemName, _, itemRarity, _, _, _, _, itemSlot, _ = GetItemInfo(itemLink)

        for playerName, item in next, LootRes:lootres_reserves() do
            if (string.lower(itemName) == string.lower(item)) then
                reservedNumber = reservedNumber + 1
            end
        end

        if (itemRarity >= 4) then

            GameTooltip:AddLine("Soft-Reserved List (" .. reservedNumber .. ")")

            if (reservedNumber > 0) then
                for playerName, item in next, LootRes:lootres_reserves() do
                    if (string.lower(itemName) == string.lower(item)) then
                        GameTooltip:AddLine(playerName, 1, 1, 1)
                    end
                end
            end

            --        GameTooltip:AddLine("test", 1, 1, 1)
        end

        GameTooltip:Show()
    end
end)

LootRes:SetScript("OnHide", function()
    GameTooltip.itemLink = nil
end)

function LootRes:ScanUnit(target)
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

SLASH_LOOTRES1 = "/lootres"
SlashCmdList["LOOTRES"] = function(cmd)
    if (cmd) then
        if (cmd == 'print') then
            LootRes:PrintReserves()
        end
        if (cmd == 'load') then
            LootRes:LoadFromText()
        end
        if (cmd == 'check') then
            LootRes:CheckReserves()
        end
        if (string.find(cmd, "search", 1)) then
            LootRes:SearchPlayerOrItem(cmd)
        end
    end
end
function LootRes:LoadFromText()
    local pasteData = loadstring(EditBox1:GetText())
    print(pasteData)
end

function LootRes:PrintReserves()
    local longString = ''
    for playerName, item in next, LootRes:lootres_reserves() do
        longString = longString .. playerName .. ":" .. item .. "|"
    end
    print(longString);
end

function LootRes:SearchPlayerOrItem(search)
    print("*" .. LootResReplace(search, "search ", "") .. "*")
end

function LootResReplace(text, search, replace)
    if (search == replace) then return text; end
    local searchedtext = "";
    local textleft = text;
    while (strfind(textleft, search, 1)) do
        searchedtext = searchedtext .. strsub(textleft, 1, strfind(textleft, search, 1) - 1) .. replace;
        textleft = strsub(textleft, strfind(textleft, search, 1) + strlen(search));
    end
    if (strlen(textleft) > 0) then
        searchedtext = searchedtext .. textleft;
    end
    return searchedtext;
end

local timerChannel = "RAID_WARNING"
-- GUILD RAID_WARNING SAY



local rollTimer = CreateFrame("Frame")
rollTimer:Hide()
rollTimer:SetScript("OnShow", function()
    this.startTime = math.floor(GetTime());
end)

rollTimer:SetScript("OnUpdate", function()
    if (math.floor(GetTime()) == math.floor(this.startTime) + 1) then
        if (T ~= secondsToRoll + 1) then
            SendChatMessage("LootRes: " .. (C - T + 1) .. "", "RAID")
        end
        rollTimer:Hide()
        if (T < C + 1) then
            T = T + 1
            rollTimer:Show()
        elseif (T == secondsToRoll + 1) then
            SendChatMessage("LootRes: Closed", timerChannel)
            rollTimer:Hide()
            T = 1
            rollsOpen = false

            if (maxRoll ~= 0) then
                local winners = {}
                local winnersNo = 0;
                --                print('LootRes: Winner roll')
                for index, pr in rollers do
                    if (tonumber(pr) == tonumber(maxRoll)) then
                        winners[index] = pr
                        winnersNo = winnersNo + 1
                        --print('LootRes: ' .. index .. ' with a ' .. pr)
                    end
                end
                if (winnersNo == 1) then
                    for index, pr in winners do
                        local nice = ""
                        if (pr == 69) then nice = "(nice)" end
                        if (pr == 1) then nice = "(oof)" end
                        if (pr == 100) then nice = "(yeet)" end
                        if (reservedNames ~= "") then
                            SendChatMessage("LootRes: Highest roll by " .. index .. " with " .. pr .. nice .. " (" .. reservedNames .. " reserved this item)", timerChannel)
                        else
                            SendChatMessage("LootRes: Highest roll by " .. index .. " with " .. pr .. nice, timerChannel)
                        end
                    end
                else --tie
                    local tieRollers = ""
                    local tieRoll = 0
                    for index, pr in winners do
                        tieRollers = tieRollers .. " " .. index
                        tieRoll = pr
                    end
                    local nice = ""
                    if (tieRoll == 69) then nice = "(nice)" end
                    if (tieRoll == 1) then nice = "(oof)" end
                    if (tieRoll == 100) then nice = "(yeet)" end
                    if (reservedNames ~= "") then
                        SendChatMessage("LootRes: Highest roll by " .. tieRollers .. " with " .. tieRoll .. nice .. " TIE (" .. reservedNames .. " reserved this item)", timerChannel)
                    else
                        SendChatMessage("LootRes: Highest roll by " .. tieRollers .. " with " .. tieRoll .. nice .. " TIE", timerChannel)
                    end
                end
            else
                --                print('LootRes: No rolls recorded')
                SendChatMessage("LootRes: No rolls recorded.", timerChannel)
            end

            -- reset stuff
            maxRoll = 0
            rollers = {}

        else
            print(T)
        end
    else
        --        print(math.floor(GetTime()) .. " == " .. (math.floor(this.startTime) + 1) .. " check failed");
        --        rollTimer:Hide()
    end
end)

function LootRes:CheckRolls(arg)
    if (string.find(arg, "rolls", 1) and string.find(arg, "(1-100)")) then
        local r = string.split(arg, " ")

        if (not rollers[r[1]]) then
            rollers[r[1]] = tonumber(r[3])
            if (tonumber(r[3]) > tonumber(maxRoll)) then
                maxRoll = tonumber(r[3])
            end
        end
    end
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

function PrintFromTooltip()

    if (rollsOpen) then
        SendChatMessage("ROLLS Canceled ! Restarting.", timerChannel);
    end

    if GameTooltip.itemLink then
        --        local _, _, itemID = string.find(GameTooltip.itemLink, "item:(%d+):%d+:%d+:%d+")
        local _, _, itemLink = string.find(GameTooltip.itemLink, "(item:%d+:%d+:%d+:%d+)");
        local itemName, _, itemRarity, _, _, _, _, itemSlot, _ = GetItemInfo(itemLink)

        local reservedNumber = 0;

        for playerName, item in next, LootRes:lootres_reserves() do
            if (string.lower(itemName) == string.lower(item)) then
                reservedNumber = reservedNumber + 1
            end
        end
        reservedNames = "";
        rollTimer:Hide()

        T = 1 --start
        C = secondsToRoll --count to

        rollers = {}
        maxRoll = 0

        offspecRoll = lastRolledItem == itemName

        lastRolledItem = itemName

        if (reservedNumber > 0) then
            -- RESERVED
            for playerName, item in next, LootRes:lootres_reserves() do
                if (string.lower(itemName) == string.lower(item)) then
                    reservedNames = reservedNames .. " " .. playerName;
                end
            end
            SendChatMessage(reservedNames .. " ROLL FOR " .. GameTooltip.itemLink .. " " .. secondsToRoll .. " Seconds", timerChannel);
            rollTimer:Show()
            rollsOpen = true

        else
            -- NOT RESERVED

            if (offspecRoll) then
                SendChatMessage("OFF SPEC ROLL " .. GameTooltip.itemLink .. " " .. secondsToRoll .. " Seconds", timerChannel);
                lastRolledItem = ""
            else
                --                SendChatMessage("LootRes: No reservations found for " .. GameTooltip.itemLink, timerChannel);
                SendChatMessage("MAIN SPEC ROLL " .. GameTooltip.itemLink .. " " .. secondsToRoll .. " Seconds (not reserved)", timerChannel);
            end

            rollTimer:Show()
            rollsOpen = true
        end
    end
end

function LootRes:CheckReserves()
    for n, i in next, LootRes:lootres_reserves() do
        print(" checking " .. i)
        local itemName = GetItemInfo(i)
--        if (i) then
            print(itemName)
--        else
--            print(i .. " has errors")
--        end
    end
end

function LootRes:lootres_reserves()
    return {
        ["Tyrelys"] = "Band of Accuria",
        ["Laughadin"] = "Judgement Legplates",
        ["Momo"] = "Choker of the Fire Lord",
        ["Chlo"] = "Cloak of the Shrouded Mists",
        ["Justherczeg"] = "Choker of the Fire Lord",
        ["Aurrius"] = "Robe of Volatile Power",
        ["Smersh"] = "Nightslayer Cover",
        ["Halyeth"] = "Quick Strike Ring",
        ["Er"] = "Cauterizing Band",
        ["Faralynn"] = "Wild Growth Spaulders",
        ["Ruari"] = "Cloak of the Shrouded Mists",
        ["Leyvar"] = "Onslaught Girdle",
        ["Edward"] = "Felheart Horns",
        ["Wither"] = "Giantstalker's Epaulets",
        ["Chlothar"] = "Quick Strike Ring",
        ["Faustus"] = "Azuresong Mageblade",
        ["Smultron"] = "Band of Accuria",
        ["Motorboat"] = "Choker of the Fire Lord",
        ["Raymundo"] = "Giantstalker's Breastplate",
        ["Vaedath"] = "Breastplate of Might",
        ["Astrld"] = "Band of Accuria",
        ["Leoni"] = "Striker's Mark",
        ["Camil"] = "Ring of Spell Power",
        ["Karaja"] = "Felheart Gloves",
        ["Furryslayer"] = "Choker of the Fire Lord",
        ["Adrasteia"] = "Essence of the Pure Flame",
        ["Dispatch"] = "Choker of Enlightenment",
    }
end
