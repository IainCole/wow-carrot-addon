
local _, ns = ...

local APPNAME = "Carrot"
local APPDESC = "Would you like a carrot?"

Carrot = LibStub("AceAddon-3.0"):NewAddon(APPNAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(APPNAME)
local LSM = LibStub("LibSharedMedia-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

-- Library constants
local SOUND = LSM.MediaType and LSM.MediaType.SOUND or "sound"

local isInitialized = false

local soundOptions = {
    mmmbop = "mmmbop",
	dangerzone5 = "dangerzone5",
}

local soundPaths = {
    [soundOptions.mmmbop] = "Interface/AddOns/Carrot/Media/Sounds/mmmbop.ogg"
	[soundOptions.dangerzone5] = "Interface/AddOns/Carrot/Media/Sounds/danger_zone_5.ogg"
}

local soundChannels =  {
    ["default"] = "Default",
    ["ambience"] = "Ambience",
    ["dialog"] = "Dialog",
    ["master"] = "Master",
    ["music"] = "Music",
    ["sfx"] = "Sound"
}

local handles = {
    ["mmmbop"] = nil
}

local sharedSoundOptions = nil

local CHANNEL_DEFAULT = "default"

function Carrot:Verbose(...)
    if self.db.profile.verbose == false then return end
    self:Printf(...)
end

function Carrot:Debug(...)
    if self.db.profile.debug == false then return end
    self:Printf(...)
end

local defaults = {
    profile = {

        -- General
        disabled = false,
        debug = false,
        soundChannel = CHANNEL_DEFAULT, -- Default sound channel
    }
}

local options = {
    name = APPNAME,
    handler = Carrot,
    type = "group",
    childGroups = "tab",
    desc = APPNAME,
    get = "GetConfig",
    set = "SetConfig",
    args = {
        general = {
            type = "group",
            name = "General",
            order = 1,
            args={
                general = {
                    type = "group",
                    name = "General Options",
                    order = 10,
                    inline = true,
                    args = {
                        disabled = {
                            order = 10,
                            type = "toggle",
                            name = L["Disabled"],
                            desc = L["Disables or enables the addon"]
                        },
                        debug = {
                            order = 30,
                            type = "toggle",
                            name = L["Debug"],
                            desc = L["Enables or disables debug logging"]
                        },
                        soundChannel = {
                            order = 30,
                            type = "select",
                            name = L["Channel"],
                            desc = L["Default sound channel"],
                            values = "SoundChannels"
                        },
                    }
                }
            }
        }
    }
}

function Carrot:InitializeOptions(root)
    return root
end

function Carrot:SoundChannels()
    return soundChannels
end

function Carrot:GetConfig(info)
    self:Debug("GetConfig %s", tostring(info[#info]))
    return self.db.profile[info[#info]]
end

function Carrot:SetConfig(info, value)
    self:Debug("SetConfig %s=%s", tostring(info[#info]), tostring(value))
    self.db.profile[info[#info]] = value
    self:ApplyOptions()
end


function Carrot:ApplyOptions()
    
end

function Carrot:OnInitialize()

    if self.isInitialized == true then
        return
    end

    self.db = LibStub("AceDB-3.0"):New("CarrotDB", defaults, true)

    LSM:Register(SOUND, soundOptions.mmmbop, soundPaths[soundOptions.mmmbop])
	LSM:Register(SOUND, soundOptions.dangerzone5, soundPaths[soundOptions.dangerzone5])

    if self.options == nil then
        self.options = self:InitializeOptions(options)
        LibStub("AceConfig-3.0"):RegisterOptionsTable(APPNAME, options)
        self.optionsFrame = ACD:AddToBlizOptions(APPNAME, APPNAME)
    end

    self:ApplyOptions()

    self:RegisterChatCommand("carrot", "ChatCommand")

    self.isInitialized = true
end

function Carrot:ChatCommand()
    self:Debug("/carrot was invoked")
    InterfaceOptionsFrame_OpenToCategory(APPDESC)
    InterfaceOptionsFrame_OpenToCategory(APPDESC)
end

function Carrot:OnEnable()
    Carrot:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function Carrot:OnDisable()
    self:Debug("OnDisable")
    Carrot:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function Carrot:COMBAT_LOG_EVENT_UNFILTERED(...)
    if self.db.profile.disabled == true then
        self:Debug("Add-on is disabled")
        return
    end

	local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName = CombatLogGetCurrentEventInfo()

	if subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_AURA_REMOVED" then
        -- MMMBop
        if spellId == 1022 and destGUID == UnitGUID("player") then
            if subevent == "SPELL_AURA_REMOVED" then
                if handles.mmmbop then StopSound(handles.mmmbop) end
                return
            end

            local sound = LSM:Fetch(SOUND, soundOptions.mmmbop, false)

            local soundChannel = self.db.profile.soundChannel or CHANNEL_DEFAULT
            if soundChannel == CHANNEL_DEFAULT then soundChannel = soundChannels.dialog end
    
            if handles.mmmbop then StopSound(handles.mmmbop) end
    
            -- Play the sound
            self:Debug("Playing %s", tostring(sound))
            local willPlay, handle = PlaySoundFile(sound, soundChannel)
            if willPlay then
                handles.mmmbop = handle
            end

            return
        end
    end
end