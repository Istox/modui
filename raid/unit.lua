

    -- these were originally based on luna's raidframes
    -- credits to rhena

    local sb = [[Interface\AddOns\modui\statusbar\texture\sb.tga]]
    local bg = {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],}
    local f  = CreateFrame'Frame'
    local x  = UnitFactionGroup'player' == 'Alliance' and 'Horde' or 'Alliance'
    local xx = 4
    local bu = {}
    local a_offset, y_offset = 0, 0
    local roster = {
        [1] = {}, [2] = {}, [3] = {}, [4] = {},
        [5] = {}, [6] = {}, [7] = {}, [8] = {},
    }

    local showdebuffs = false                   -- TOGGLE DEBUFF ICONS
    local left2right  = true                    -- SET GROWTH DIRECTION

    local HealComm  = AceLibrary'HealComm-1.0'  -- healcomm
    f.proximity = ProximityLib:GetInstance'1'   -- proximitylib

    local cache = function(num)
        if num < 1 then
            for i = 1,  8 do _G['modraid_grp'..i]:Hide() end
            for i = 1, 40 do _G['modraid'..i]:Hide() end
        elseif RAID_SUBGROUP_LISTS then
            for i = 1,  8 do roster[i] = {} end
            for i = 1,  8 do
                for j = 1, 5 do
                    if RAID_SUBGROUP_LISTS[i][j] then
                        roster[i][j] = 'raid'..RAID_SUBGROUP_LISTS[i][j]
                    else
                        roster[i][j] = nil
                    end
				end
                table.sort(roster[i], function(a, b) return a < b end)
            end
        end
    end

    local format = function(index)
        for i = 1, 8 do
            local header = _G['modraid_grp'..i]
            if getn(roster[i]) > 0 then
                header:Show() header.text:SetText('∙ '..i..' ∙')
            else
                header:Hide()
            end
            for j, v in pairs(roster[i]) do
                local raid = bu[index]
                raid.unit = v
                if raid.unit then
                    raid:Show()
                end
                index = index + 1
            end
        end
        for i = index, 40 do bu[index]:Hide() end
    end

    local arrange = function(index)
        for i = 1, 8 do
            local header = _G['modraid_grp'..i]
            for j = 1, getn(roster[i]) do
                local raid = bu[index]
                if j == 1 then
                    raid:ClearAllPoints()
                    raid:SetPoint('TOP', header, 'BOTTOM', 0, -10)
                else
                    raid:ClearAllPoints()
                    raid:SetPoint('TOP', bu[index - 1], 'BOTTOM', 0, -10)
                end
                index = index + 1
            end
        end
    end

    local rosterupdate = function()
        local index = 1
        cache(GetNumRaidMembers())
        format(index)
        arrange(index)
    end

    local buffs = function(bu)
        local v = PROCESSBUFFSgetBuffs(UnitName(bu.unit))[1]
        if v and v.icon then
            bu.aura:Show()
            bu.aura.icon:SetTexture(v.icon)
            modSkinColor(bu.aura, v.border.r, v.border.g, v.border.b)
        else
            bu.aura:Hide()
            bu.aura.icon:SetTexture''
        end
    end

    local debuffs = function(arg1)
        if this.unit ~= arg1 or not this.unit then return end
        local _, _, dtype = UnitDebuff(this.unit, 1, 1)
        local lastfound = 1

        if dtype then
            local colour = DebuffTypeColor[dtype]
            modSkinColor(this, colour.r, colour.g, colour.b)
        else
            modSkinColor(this, .2, .2, .2)
        end

        for i = 1, 2 do
            local texture, _, dtype = UnitDebuff(this.unit, i)
            if texture and showdebuffs then
                local colour = DebuffTypeColor[dtype] or DebuffTypeColor['none']
                this.debuffs[i]:SetTexture(texture)
                this.debuffs[i]:Show()
                this.debuffs[i].border:SetVertexColor(colour.r, colour.g, colour.b)
                this.debuffs[i].border:Show()
            else
                this.debuffs[i]:SetTexture''
                this.debuffs[i]:Hide()
                this.debuffs[i].border:Hide()
            end
        end
    end

    local raidicon = function(bu)
        bu.ric:Hide() bu.name:Show()
        if bu.flag:IsShown() or bu.healv:IsShown() or bu.rez:IsShown() then bu.name:Hide() return end
        if UnitExists(bu.unit) then
            local i = GetRaidTargetIndex(bu.unit)
            if i then
                SetRaidTargetIconTexture(bu.ric, i)
                bu.ric:Show() bu.name:Hide()
            end
        end
    end

    local range = function(bu, time, seen, r, g, b)
        if time and seen < 3 then
            bu.hp:SetStatusBarColor(r, g, b)
        else
            bu.hp:SetStatusBarColor(r*.375, g*.375, b*.375)
        end
    end

    local heals = function(bu)
        local name = UnitName(bu.unit)
    	local heal = HealComm:getHeal(name)
        local rez  = HealComm:UnitisResurrecting(name)
    	local v, max = UnitHealth(bu.unit), UnitHealthMax(bu.unit)
    	local bu_w, bu_h = bu.hp:GetWidth(), bu.hp:GetHeight()
    	local hp_w, hp_h = bu_w*(v/max), bu_h*(v/max)
        if rez then bu.rez:Show() else bu.rez:Hide() end
    	if heal > 0 and v < max and not UnitIsDeadOrGhost(bu.unit) then
            local w = bu_w*(heal/max)
    		if (hp_w + w) > bu_w then w = bu_w - hp_w end
    		bu.heal:Show()
    		bu.heal:SetWidth(w)
    		bu.heal:SetHeight(bu_h)
    		bu.heal:ClearAllPoints()
    		bu.heal:SetPoint('TOPLEFT', bu.hp, hp_w, 0)
        else
            bu.heal:Hide()
    	end
    end

    local vheals = function(bu)
        local v = PROCESSCASTINGgetHeal(UnitName(this.unit))
        bu.healv:Hide()
        if v then
            if GetTime() < v.timeEnd then
                local y = -4
                if v.crit == 1 then
                    bu.healv:SetFont(STANDARD_TEXT_FONT, 16, 'MONOCHROMEOUTLINE')
                    y = 0
                else
                    bu.healv:SetFont(STANDARD_TEXT_FONT, 12, 'MONOCHROMEOUTLINE')
                    y = y + v.y
                    if y + v.y < y + 8 then v.y = v.y + .5 end
                end
                bu.healv:SetPoint('CENTER', bu, -1, y)
                if (v.timeEnd - GetTime()) < .6 then
                    bu.healv:SetAlpha(mod((v.timeEnd - GetTime()), 1))
                else
                    bu.healv:SetAlpha(.6)
                end
                bu.healv:SetText('+ '..v.amount..(v.crit == 1 and '!' or ''))
                bu.healv:Show()
            end
        end
	end

    local status = function(bu)
        bu.name:SetShadowColor(0, 0, 0)
        if not UnitIsConnected(this.unit) then
            bu.hp:SetStatusBarColor(.7, .7, .7)
            bu.hp:SetMinMaxValues(0, 1)
            bu.hp:SetValue(1)
            bu.name:SetTextColor(.1, .1, .1)
        elseif UnitIsDead(this.unit) then
            bu.name:SetTextColor(1, 0, 0)
        elseif UnitIsGhost(this.unit) then
            bu.name:SetShadowColor(.15, .15, .15)
            bu.name:SetTextColor(.5, .5, .5)
        else
            local _, class = UnitClass(this.unit)
            local colour   = class and RAID_CLASS_COLORS[class] or {r = .2, g = .2, b = .2}
            bu.name:SetTextColor(colour.r, colour.g, colour.b)
        end
    end

    local raidupdate = function()
        if this:IsShown() then
            if not UnitExists(this.unit) then this:Hide() return end
            local now            = GetTime()
            local hp, mana, name = this.hp, this.mana, this.name
            local power          = UnitPowerType(this.unit)
            local _, time        = f.proximity:GetUnitRange(this.unit)
            local seen           = now - (time or 100)
            local r, g, b        = name:GetTextColor()

            hp:SetMinMaxValues(0, UnitHealthMax(this.unit))
            hp:SetValue(UnitHealth(this.unit))

            mana:SetMinMaxValues(0, UnitManaMax(this.unit))
            mana:SetValue(UnitMana(this.unit))
            mana:SetStatusBarColor((power == 1 or power == 3) and 1 or 0,
                                    power == 1 and 0 or power == 3 and 1 or 0,
                                    power == 1 and 0 or power == 3 and 0 or 1)

            name:SetText(string.sub(UnitName(this.unit), 1, 6))

            buffs(this)
            raidicon(this)
            range(this, time, seen, r, g, b)
            heals(this)
            vheals(this)
            status(this)

            if power ~= 0 and UnitMana(this.unit) < 1 then
                hp:SetHeight(24) mana:Hide()
            else
                hp:SetHeight(16) mana:Show()
            end
        end
    end

    local display = function(t, y, a)
        Minimap.raid:Show()
        local time = GetTime()
        if a + a_offset < a + .6 then
            a = a + a_offset
            a_offset = a_offset + .005
            Minimap.raid:SetAlpha(a)
        end
        if y + y_offset < y + 12 then
            y = y + y_offset
            y_offset = y_offset + 2
            Minimap.raid:SetPoint('TOP', Minimap, 'BOTTOM', 2, -y)
        end
        if Minimap.raid:GetAlpha() == 1 and y_offset == 12 then this:SetScript('OnUpdate', nil) end
    end

    local flag = function(t, index)
        for i = 1, 8 do
            for j = 1, getn(roster[i]) do
                local raid = bu[index]
                if t == UnitName(raid.unit) then raid.flag:Show() break end
                index = index + 1
            end
        end
    end

    local unflag = function(t, index)
        for i = 1, 8 do
            for j = 1, getn(roster[i]) do
                local raid = bu[index]
                if t == UnitName(raid.unit) then raid.flag:Hide() end
                index = index + 1
            end
        end
    end

    local clearflag = function()
        for i = 1, 40 do _G['modraid'..i].flag:Hide() end
    end

    for i = 1, 8 do
        local header = CreateFrame('Button', 'modraid_grp'..i, UIParent)
        header:SetWidth(32) header:SetHeight(12)
        header:SetMovable(true) header:SetUserPlaced(true)
        header:RegisterForDrag'LeftButton' header:EnableMouse(true)
        header:Hide()

        header.text = header:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
        header.text:SetPoint('CENTER', header)
        header.text:SetJustifyH'CENTER'
        header.text:SetText'group'

        if i == 1 then
            if left2right then
                header:SetPoint('TOPLEFT', Minimap, 'BOTTOMLEFT', -138, -50)
            else
                header:SetPoint('TOPRIGHT', Minimap, 'BOTTOMRIGHT', -53, -50)
            end
        elseif i == (xx + 1) then
            header:SetPoint('TOPLEFT',  _G['modraid_grp'..(i - xx)], 'BOTTOMLEFT', 0, -180)
        else
            -- changed: might be an issue w/ logic?
            header:SetPoint(left2right and 'LEFT' or 'RIGHT', _G['modraid_grp'..(i - 1)], left2right and 'RIGHT' or 'LEFT', showdebuffs and (left2right and 44 or -44) or (left2right and 32 or -32), 0)
        end

        header:SetScript('OnDragStart', function() this:StartMoving() end)
        header:SetScript('OnDragStop',  function() this:StopMovingOrSizing() end)
    end

    for i = 1, 40 do
        bu[i] = CreateFrame('Button', 'modraid'..i, UIParent)
        bu[i]:SetWidth(53) bu[i]:SetHeight(24)
        bu[i]:SetBackdrop(bg)
        bu[i]:SetBackdropColor(0, 0, 0, 1)
        bu[i]:SetFrameLevel(0)
        bu[i]:Hide()

        modSkin(bu[i], 17.5)
        modSkinPadding(bu[i], 2)
        modSkinColor(bu[i], .2, .2, .2)

        bu[i].hp = CreateFrame('StatusBar', nil, bu[i])
        bu[i].hp:SetWidth(50) bu[i].hp:SetHeight(16)
        bu[i].hp:SetFrameLevel(0)
        bu[i].hp:SetMinMaxValues(0, 100)
        bu[i].hp:SetValue(100)
        bu[i].hp:SetStatusBarTexture(sb)
        bu[i].hp:SetStatusBarColor(0, 1, 0)
        bu[i].hp:SetPoint('TOP', bu[i])

        bu[i].mana = CreateFrame('StatusBar', nil, bu[i])
        bu[i].mana:SetWidth(50) bu[i].mana:SetHeight(5)
        bu[i].mana:SetFrameLevel(0)
        bu[i].mana:SetMinMaxValues(0, 100)
        bu[i].mana:SetValue(100)
        bu[i].mana:SetStatusBarTexture(sb)
        bu[i].mana:SetPoint('TOP', bu[i].hp, 'BOTTOM', 0, -1)

        bu[i].name = bu[i]:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
        bu[i].name:SetPoint('TOP', bu[i], 0, -3)
        bu[i].name:SetJustifyH'CENTER'

        bu[i].heal = CreateFrame('StatusBar', nil, bu[i].hp)
        bu[i].heal:SetWidth(1) bu[i].heal:SetHeight(16)
        bu[i].heal:SetFrameLevel(0)
        bu[i].heal:SetMinMaxValues(0, 1)
        bu[i].heal:SetValue(1)
        bu[i].heal:SetStatusBarTexture(sb)
        bu[i].heal:SetStatusBarColor(0, 1, 0, .7)

        bu[i].healv = bu[i]:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
        bu[i].healv:SetTextColor(0, .6, 0, .6)
        bu[i].healv:SetPoint('CENTER', bu[i], 0, -4)

        bu[i].ric = bu[i]:CreateTexture(nil, 'OVERLAY')
        bu[i].ric:SetWidth(17) bu[i].ric:SetHeight(17)
        bu[i].ric:SetTexture[[Interface\TargetingFrame\UI-RaidTargetingIcons]]
        bu[i].ric:SetPoint('CENTER', bu[i])

        bu[i].rez = bu[i]:CreateTexture(nil, 'OVERLAY', nil, 7)
        bu[i].rez:SetWidth(24) bu[i].rez:SetHeight(24)
        bu[i].rez:SetTexture[[Interface\AddOns\modui\raid\texture\Raid-Icon-Rez.tga]]
        bu[i].rez:SetPoint('CENTER', bu[i])
        bu[i].rez:Hide()

        bu[i].flag = bu[i]:CreateTexture(nil, 'OVERLAY', nil, 7)
        bu[i].flag:SetWidth(24) bu[i].flag:SetHeight(24)
        bu[i].flag:SetTexture('Interface\\WorldStateFrame\\'..x..'Flag')
        bu[i].flag:SetPoint('CENTER', bu[i])
        bu[i].flag:Hide()

        bu[i].aura = CreateFrame('Button', nil, bu[i])
        bu[i].aura:SetWidth(19) bu[i].aura:SetHeight(19)
        bu[i].aura:SetPoint('CENTER', bu[i], 'BOTTOM', 0, 6)
        bu[i].aura:SetFrameLevel(2)
        bu[i].aura:EnableMouse(false)
        bu[i].aura:Hide()

        bu[i].aura.icon = bu[i].aura:CreateTexture(nil, 'BACKGROUND', 0, -7)
        bu[i].aura.icon:SetAllPoints()
        bu[i].aura.icon:SetAlpha(.7)

        modSkin(bu[i].aura, 12.5)
        modSkinPadding(bu[i].aura, 2)
        modSkinColor(bu[i].aura, .2, .2, .2)

        bu[i].debuffs = {}

        for j = 1, 2 do
            bu[i].debuffs[j] = bu[i]:CreateTexture(nil, 'BACKGROUND')
            bu[i].debuffs[j]:SetWidth(10) bu[i].debuffs[j]:SetHeight(10)
            bu[i].debuffs[j]:Hide()

            bu[i].debuffs[j].border = bu[i]:CreateTexture(nil, 'ARTWORK')
            bu[i].debuffs[j].border:SetWidth(12) bu[i].debuffs[j].border:SetHeight(12)
            bu[i].debuffs[j].border:SetPoint('CENTER', bu[i].debuffs[j])
            bu[i].debuffs[j].border:SetTexture[[Interface\Buttons\UI-Debuff-Overlays]]
            bu[i].debuffs[j].border:SetTexCoord(.296875, .5703125, 0, .515625)
            bu[i].debuffs[j].border:Hide()

            if j == 1 then
                bu[i].debuffs[j]:SetPoint('TOPLEFT', bu[i], 'TOPRIGHT', 5, -2)
            else
                bu[i].debuffs[j]:SetPoint('TOP', bu[i].debuffs[1], 'BOTTOM', 0, -1)
            end
        end

        bu[i]:RegisterEvent'UNIT_AURA'     -- init
        bu[i]:SetScript('OnEvent',  function() debuffs(arg1) end)
        bu[i]:SetScript('OnClick',  function() if CursorHasItem() then DropItemOnUnit(this.unit) else TargetUnit(this.unit) end end)
        bu[i]:SetScript('OnEnter',  function() UnitFrame_OnEnter() GameTooltipStatusBar:Hide() end)
        bu[i]:SetScript('OnLeave',  UnitFrame_OnLeave)
        bu[i]:SetScript('OnUpdate', raidupdate)
    end

    Minimap.raid = CreateFrame('Button', 'modMinimap_RaidSpawn', Minimap)
    Minimap.raid:SetWidth(20) Minimap.raid:SetHeight(100)
    Minimap.raid:SetPoint('TOP', Minimap, 'BOTTOM')
    Minimap.raid:Hide()

    Minimap.raid.text = Minimap.raid:CreateFontString(nil, 'OVERLAY')
    Minimap.raid.text:SetFont(STANDARD_TEXT_FONT, 24, 'OUTLINE')
    Minimap.raid.text:SetPoint('CENTER', Minimap.raid)
    Minimap.raid.text:SetText'+'
    Minimap.raid.text:SetTextColor(0, 1, 0)

    Minimap.raid:SetScript('OnEnter', function()
        GameTooltip:SetOwner(this, 'ANCHOR_TOPRIGHT', -30, -60)
        GameTooltip:SetText'Click to show/hide Raid Frames'
        Minimap.raid.text:SetTextColor(1, 1, 0)
        GameTooltip:Show()
    end)

    Minimap.raid:SetScript('OnLeave', function()
        Minimap.raid.text:SetTextColor(0, 1, 0)
        GameTooltip:Hide()
    end)

    Minimap.raid:SetScript('OnClick', function()
        local t = this.text:GetText()
        if t == '+' then
            this.text:SetText'–'
            rosterupdate()
        elseif t == '–' then
            this.text:SetText'+'
            for i = 1,  8 do _G['modraid_grp'..i]:Hide() end
            for i = 1, 40 do bu[i]:Hide() end
        end
    end)

    f:RegisterEvent'VARIABLES_LOADED'
    f:RegisterEvent'PLAYER_ENTERING_WORLD'
    f:RegisterEvent'CHAT_MSG_SYSTEM'  f:RegisterEvent'RAID_ROSTER_UPDATE'
    f:RegisterEvent'CHAT_MSG_BG_SYSTEM_ALLIANCE' f:RegisterEvent'CHAT_MSG_BG_SYSTEM_HORDE'
    f:SetScript('OnEvent', function()
        if event == 'VARIABLES_LOADED' then
            if not MODUI_RAID_XY then
                MODUI_RAID_XY = {'TOP', Minimap, 'BOTTOM', 2, -70}
            end
        elseif (event == 'PLAYER_ENTERING_WORLD' and UnitInRaid'player')
        or (event == 'CHAT_MSG_SYSTEM' and string.find(arg1, 'You have joined a raid group')) then
            local t = GetTime() + 60
            local y = -20
            local a = .5
            Minimap.raid.text:SetText'+'
            f.reset = true
            f:SetScript('OnUpdate', function() display(t, y, a) end)
            f:UnregisterEvent'PLAYER_ENTERING_WORLD'
        elseif event == 'RAID_ROSTER_UPDATE' then
            if Minimap.raid.text:GetText() == '–' then rosterupdate() end
            if GetNumRaidMembers() < 1 or not UnitInRaid'player' then
                for i = 1, 8 do _G['modraid_grp'..i]:Hide() end
                Minimap.raid:Hide() f.reset = true
            end
        elseif event == 'CHAT_MSG_BG_SYSTEM_ALLIANCE' or event == 'CHAT_MSG_BG_SYSTEM_HORDE' then
            local s = arg1
            local index = 1
            if string.find(s, 'The Alliance Flag was picked up')
            or string.find(s, '+ Alliance Flag') then
                local t = gsub(s, 'The Alliance Flag was picked up by (.+)!', '%1')
                clearflag() flag(t, index)
            elseif string.find(s, 'The Horde flag was picked up')
            or string.find(s, '+ Horde Flag') then
                local t = gsub(s, 'The Horde flag was picked up by (.+)!', '%1')
                clearflag() flag(t, index)
            elseif string.find(s, 'The Alliance Flag was dropped') then
                local t = gsub(s, 'The Alliance Flag was dropped by (.+)!', '%1')
                unflag(t, index)
            elseif string.find(s, '- Alliance Flag') then
                local t = gsub(s, '- Alliance Flag — (.+).', '%1')
                unflag(t, index)
            elseif string.find(s, 'captured the Alliance flag!') then
                local t = gsub(s, '(.+) captured the Alliance flag!', '%1')
                unflag(t, index)
            elseif string.find(s, 'The Horde flag was dropped') then
                local t = gsub(s, 'The Horde flag was dropped by (.+)!', '%1')
                unflag(t, index)
            elseif string.find(s, '- Horde Flag') then
                local t = gsub(s, '- Horde Flag — (.+).', '%1')
                unflag(t, index)
            elseif string.find(s, 'captured the Horde flag!') then
                local t = gsub(s, '(.+) captured the Horde flag!', '%1')
                unflag(t, index)
            end
        end
    end)


    --
