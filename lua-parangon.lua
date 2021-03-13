---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Khalar.
--- DateTime: 13/03/2021 14:19
---
---
local parangon = {

    config = {
        db_name = 'R1_Eluna',

        pointsPerLevel = 1,
        minLevel = 1,

        expMulti = 1,
        expMax = 500,

        pveKill = 100,
        pvpKill = 10,

        levelDiff = 10,

        maxStat = 255,
    },

    spells = {
        [7464] = {'|TInterface\\icons\\inv_potion_161:30:30:-18:0|t', 'Strenght' },
        [7471] = {'|TInterface\\icons\\inv_potion_165:30:30:-18:0|t', 'Agility' },
        [7477] = {'|TInterface\\icons\\inv_potion_160:30:30:-18:0|t', 'Stamina' },
        [7468] = {'|TInterface\\icons\\inv_potion_163:30:30:-18:0|t', 'Intellect' }
    },
}

parangon.account = {}

function Player:setParangonInfo(strength, agility, stamina, intellect)
    self:SetData('parangon_stats_7464', strength)
    self:SetData('parangon_stats_7471', agility)
    self:SetData('parangon_stats_7477', stamina)
    self:SetData('parangon_stats_7468', intellect)
end

function parangon.onServerStart(event)
    CharDBExecute('CREATE DATABASE IF NOT EXISTS `'..parangon.config.db_name..'`;')
    CharDBExecute('CREATE TABLE IF NOT EXISTS `'..parangon.config.db_name..'`.`account_parangon` (`account_id` INT(11) NOT NULL, `level` INT(11) DEFAULT 1, `exp` INT(11) DEFAULT 0, PRIMARY KEY (`account_id`) );');
    CharDBExecute('CREATE TABLE IF NOT EXISTS `'..parangon.config.db_name..'`.`characters_parangon` (`account_id` INT(11) NOT NULL, `guid` INT(11) NOT NULL, `strength` INT(11) DEFAULT 0, `agility` INT(11) DEFAULT 0, `stamina` INT(11) DEFAULT 0, `intellect` INT(11) DEFAULT 0, PRIMARY KEY (`account_id`, `guid`));');
    io.write('Eluna :: Parangon System start \n')
end
RegisterServerEvent(14, parangon.onServerStart)

function parangon.setStats(player)
    local pLevel = player:GetLevel()

    if pLevel >= parangon.config.minLevel then
        for spell, _ in pairs(parangon.spells) do
            player:RemoveAura(spell)
            player:AddAura(spell, player)
            player:GetAura(spell):SetStackAmount(player:GetData('parangon_stats_'..spell))
        end
    end
end

function parangon.setStatsInformation(player, stat, value, flags)
    local pCombat = player:IsInCombat()
    if (not pCombat) then
        local pLevel = player:GetLevel()
        if (pLevel >= parangon.config.minLevel) then

            if not tonumber(value) or value < 0 then
                player:SendNotification('Please enter a valid number.')
                return false
            end

            if (flags and player:GetData('parangon_stats_'..stat) + value > parangon.config.maxStat) then
                player:SendNotification('You can no longer add points.')
                return false
            end

            if flags then
                if ((player:GetData('parangon_points') - value) >= 0) then
                    player:SetData('parangon_stats_'..stat, (player:GetData('parangon_stats_'..stat) + value))
                    player:SetData('parangon_points', (player:GetData('parangon_points') - value))

                    player:SetData('parangon_points_spend', (player:GetData('parangon_points_spend') + value))
                else
                    player:SendNotification('You have no more points to award.')
                    return false
                end
            else
                if (player:GetData('parangon_stats_'..stat) > 0) then
                    player:SetData('parangon_stats_'..stat, (player:GetData('parangon_stats_'..stat) - value))
                    player:SetData('parangon_points', (player:GetData('parangon_points') + value))

                    player:SetData('parangon_points_spend', (player:GetData('parangon_points_spend') - value))
                else
                    player:SendNotification('You have no points to take out.')
                    return false
                end
            end
        else
            player:SendNotification('You don\'t have the level required to do that.')
        end
    else
        player:SendNotification('You can\'t do this in combat.')
    end
end

function parangon.onLogin(event, player)
    local pAcc = player:GetAccountId()
    local getParangonCharInfo = CharDBQuery('SELECT strength, agility, stamina, intellect FROM `'..parangon.config.db_name..'`.`characters_parangon` WHERE account_id = '..pAcc)
    if getParangonCharInfo then
        player:setParangonInfo(getParangonCharInfo:GetUInt32(0), getParangonCharInfo:GetUInt32(1), getParangonCharInfo:GetUInt32(2), getParangonCharInfo:GetUInt32(3))
        player:SetData('parangon_points', getParangonCharInfo:GetUInt32(0) + getParangonCharInfo:GetUInt32(1) + getParangonCharInfo:GetUInt32(2) + getParangonCharInfo:GetUInt32(3))
    else
        local pGuid = player:GetGUIDLow()
        CharDBExecute('INSERT INTO `'..parangon.config.db_name..'`.`characters_parangon` VALUES ('..pAcc..', '..pGuid..', 0, 0, 0, 0)')
        player:setParangonInfo(0, 0, 0, 0)
    end
    player:SetData('parangon_points_spend', 0)

    if not parangon.account[pAcc] then
        parangon.account[pAcc] = {
            level = 1,
            exp = 0,
            exp_max = 0,
        }

        local getParangonAccInfo = AuthDBQuery('SELECT level, exp FROM `'..parangon.config.db_name..'`.`account_parangon` WHERE account_id = '..pAcc)
        if getParangonAccInfo then
            parangon.account[pAcc].level = getParangonAccInfo:GetUInt32(0)
            parangon.account[pAcc].exp = getParangonAccInfo:GetUInt32(1)
            parangon.account[pAcc].exp_max = parangon.config.expMax * parangon.account[pAcc].level
        else
            AuthDBExecute('INSERT INTO `'..parangon.config.db_name..'`.`account_parangon` VALUES ('..pAcc..', 1, 0)')
        end
    end

    parangon.setStats(player)
    player:SetData('parangon_points', (parangon.account[pAcc].level * parangon.config.pointsPerLevel) - player:GetData('parangon_points'))
end
RegisterPlayerEvent(3, parangon.onLogin)

function parangon.getPlayers(event)
    for _, player in pairs(GetPlayersInWorld()) do
        parangon.onLogin(event, player)
    end
    io.write('Eluna :: Parangon System start \n')
end
RegisterServerEvent(33, parangon.getPlayers)

function parangon.onLogout(event, player)
    local pAcc = player:GetAccountId()
    local pGuid = player:GetGUIDLow()
    local strength, agility, stamina, intellect = player:GetData('parangon_stats_7464'), player:GetData('parangon_stats_7471'), player:GetData('parangon_stats_7477'), player:GetData('parangon_stats_7468')
    CharDBExecute('REPLACE INTO `'..parangon.config.db_name..'`.`characters_parangon` VALUES ('..pAcc..', '..pGuid..', '..strength..', '..agility..', '..stamina..', '..intellect..')')

    if not parangon.account[pAcc] then
        parangon.account[pAcc] = {
            level = 1,
            exp = 0,
            exp_max = 0,
        }
    end

    local level, exp = parangon.account[pAcc].level, parangon.account[pAcc].exp
    AuthDBExecute('REPLACE INTO `'..parangon.config.db_name..'`.`account_parangon` VALUES ('..pAcc..', '..level..', '..exp..')')
end
RegisterPlayerEvent(4, parangon.onLogout)

function parangon.setPlayers(event)
    for _, player in pairs(GetPlayersInWorld()) do
        parangon.onLogout(event, player)
    end
end
RegisterServerEvent(16, parangon.setPlayers)

function parangon.setExp(player, victim)
    local pLevel = player:GetLevel()
    local vLevel = victim:GetLevel()
    local pAcc = player:GetAccountId()

    if (vLevel - pLevel <= parangon.config.levelDiff) and (vLevel - pLevel >= 0) or (pLevel - vLevel <= parangon.config.levelDiff) and (pLevel - vLevel >= 0) then
        local isPlayer = GetGUIDEntry(victim:GetGUID())
        if (isPlayer == 0) then
            parangon.account[pAcc].exp = parangon.account[pAcc].exp + parangon.config.pvpKill
            player:SendBroadcastMessage('Your victim gives you '..parangon.config.pvpKill..' Parangon experience points.')
        else
            parangon.account[pAcc].exp = parangon.account[pAcc].exp + parangon.config.pveKill
            player:SendBroadcastMessage('Your victim gives you '..parangon.config.pveKill..' Parangon experience points.')
        end
    end

    if parangon.account[pAcc].exp >= parangon.account[pAcc].exp_max then
        player:SetParangonLevel(1)
    end
end

function parangon.onKillCreatureOrPlayer(event, player, victim)
    local pLevel = player:GetLevel()

    if (pLevel >= parangon.config.minLevel) then
        local pGroup = player:GetGroup()
        local vLevel = victim:GetLevel()
        if pGroup then
            for _, player in pairs(pGroup:GetMembers()) do
                parangon.setExp(player, victim)
            end
        else
            parangon.setExp(player, victim)
        end
    end
end
RegisterPlayerEvent(6, parangon.onKillCreatureOrPlayer)
RegisterPlayerEvent(7, parangon.onKillCreatureOrPlayer)

function Player:SetParangonLevel(level)
    local pAcc = self:GetAccountId()

    parangon.account[pAcc].level = parangon.account[pAcc].level + level
    parangon.account[pAcc].exp = 0
    parangon.account[pAcc].exp_max = parangon.config.expMax * parangon.account[pAcc].level
    self:SetData('parangon_points', (((parangon.account[pAcc].level * parangon.config.pointsPerLevel) - self:GetData('parangon_points')) + self:GetData('parangon_points') - self:GetData('parangon_points_spend')))

    self:CastSpell(self, 24312, true)
    self:RemoveAura( 24312 )
    self:SendNotification('|CFF00A2FFYou have just passed a level of Paragon.\nCongratulations, you are now level '..parangon.account[pAcc].level..'!')
end

function parangon.onGossipHello(event, player, object)
    player:GossipClearMenu()

    local pName = player:GetName()
    local pAccId = player:GetAccountId()

    player:GossipSetText("      "..pName.." 's Parangon\n\nLevel : "..parangon.account[pAccId].level.."\n\nExperience : "..parangon.account[pAccId].exp.."\nMax Experience : "..parangon.account[pAccId].exp_max.."\n\n      Your points available :  |CFFBC0000"..player:GetData('parangon_points'))

    for stat_id, stat_info in pairs(parangon.spells) do
        player:GossipMenuAddItem(4, stat_info[1].."|CFF9100BC[ "..player:GetData('parangon_stats_'..stat_id).."  / "..parangon.config.maxStat.." ]|r |- "..stat_info[2], 1, stat_id, false, "")
    end

    player:GossipMenuAddItem(4, "|TInterface\\icons\\spell_holy_powerinfusion:30:30:-18:0|tReset all my points", 1, 300, false, "")
    player:GossipSendMenu(0x7FFFFFFF, object, 1)
end
RegisterPlayerGossipEvent(1, 1, parangon.onGossipHello)

function parangon.onGossipSelect(event, player, object, sender, intid, code)
    if ((intid == 7464) or (intid == 7471) or (intid == 7477) or (intid == 7468)) then
        player:SetData('temp_data_statid', intid)

        player:GossipClearMenu()

        player:GossipMenuAddItem(4, "|TInterface\\icons\\achievement_pvp_g_10:30:30:-18:0|tAdd points", 1, 100, true, "")
        player:GossipMenuAddItem(4, "|TInterface\\icons\\achievement_pvp_o_11:30:30:-18:0|tRemove points", 1, 200, true, "")
        player:GossipMenuAddItem(4, "|TInterface\\icons\\spell_holy_powerinfusion:30:30:-18:0|tReset my points", 1, 300, false, "")

        player:GossipMenuAddItem(4, "< back <", 1, 400, false, "")

        player:GossipSendMenu(0x7FFFFFFF, player, 1)
    end

    if (intid == 100 or intid == 200) then
        local flags = false
        if (intid == 100) then flags = true  end

        if tonumber(code) then
            parangon.setStatsInformation(player, player:GetData('temp_data_statid'), tonumber(code), flags)
            player:SetData('temp_data_statid', nil)
        else
            player:SendNotification('You can only enter numbers')
        end
        parangon.setStats(player)
        parangon.onGossipHello(event, player, player)
    end

    if intid == 300 then
        if player:GetData('temp_data_statid') then
            parangon.setStatsInformation(player, player:GetData('temp_data_statid'), player:GetData('parangon_stats_'..player:GetData('temp_data_statid')), false)
        else
            for stat_id, _ in pairs(parangon.spells) do
                parangon.setStatsInformation(player, stat_id, player:GetData('parangon_stats_'..stat_id), false)
            end
        end
        parangon.setStats(player)
        parangon.onGossipHello(event, player, player)
    end

    if (intid == 400) then
        parangon.onGossipHello(event, player, player)
    end
end
RegisterPlayerGossipEvent(1, 2, parangon.onGossipSelect)

function parangon.onCommand(event, player, command)
    if command == 'parangon' then
        parangon.onGossipHello(event, player, player)
        return false
    end
end
RegisterPlayerEvent(42, parangon.onCommand)