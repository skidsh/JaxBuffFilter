JaxBuffFilter = LibStub("AceAddon-3.0"):NewAddon("JaxBuffFilter", "AceEvent-3.0", "AceHook-3.0","AceConsole-3.0")
local defaults = {
  profile = {
	  hiddenBuffs = {}
  }
}

function JaxBuffFilter:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("jaxBuffFilterDB", defaults, true)
	self:SetupOptions()
end

function JaxBuffFilter:IsBuffNameBlocked(name)
	local found = false;
	table.foreach(self.db.profile.hiddenBuffs, function(index, blockedName)
		if (blockedName == name) then			
			found = true;
		end
	end)
	return found;
end

oldForEachAura = AuraUtil.ForEachAura;

do
	local function ForEachAuraHelper(unit, filter, func, continuationToken, ...)
		-- continuationToken is the first return value of UnitAuraSlots()
		local n = select('#', ...);
		for i=1, n do
			local slot = select(i, ...);
			local data = UnitAuraBySlot(unit, slot);
			local name = select(1, data);
			if unit == "player" or not JaxBuffFilter:IsBuffNameBlocked(name) then
				if func(UnitAuraBySlot(unit, slot)) then
					-- if func returns true then no further slots are needed, so don't return continuationToken
					return nil;
				end
			else
				if func(name, nil, select(3, UnitAuraBySlot(unit, slot))) then
					-- if func returns true then no further slots are needed, so don't return continuationToken
					return nil;
				end
			end
		end
		return continuationToken;
	end

	function AuraUtil.ForEachAura(unit, filter, maxCount, func)
		if (filter ~= "HELPFUL") then oldForEachAura(unit, filter, maxCount, func); return end
		if maxCount and maxCount <= 0 then
			return;
		end
		local continuationToken;
		repeat
			-- continuationToken is the first return value of UnitAuraSltos
			continuationToken = ForEachAuraHelper(unit, filter, func, UnitAuraSlots(unit, filter, maxCount, continuationToken));
		until continuationToken == nil;
	end
end