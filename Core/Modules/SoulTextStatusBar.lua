SoulTextStatusBarMixin = {}

--Display modes, 100, 100%, 100/100
local DISPLAY_MODE={NUMERIC=0, PERCENT=1, VALUE_MAX=2}

function SoulTextStatusBarMixin:TextStatusBarInitialize()
	self:RegisterEvent("CVAR_UPDATE",self.TextStatusBarOnEvent)
	self:UpdateTextString()
end

function SoulTextStatusBarMixin:TextStatusBarOnEvent(event,...)
	if not SOUL_ShouldUpdate(self) then return end
	if ( event == "CVAR_UPDATE" ) then
		local cvar, value = ...;
		if cvar == "statusTextDisplay" then
			self.CenterText:Hide()
			self.RightText:Hide()
			self.LeftText:Hide()
			self:UpdateTextString()
		end
	end
end

function SoulTextStatusBarMixin:UpdateTextString()
	local value = self:GetValue();
	local _, valueMax = self:GetMinMaxValues();
	local displayMode = GetCVar("statusTextDisplay")
	if displayMode == "PERCENT" then
		self:UpdateTextStringWithValues(self.CenterText,value, valueMax, DISPLAY_MODE.PERCENT,self.zeroText);
	elseif displayMode == "NUMERIC" then
		self:UpdateTextStringWithValues(self.CenterText,value, valueMax, DISPLAY_MODE.VALUE_MAX,self.zeroText);
	elseif displayMode == "BOTH" then
		self:UpdateTextStringWithValues(self.LeftText,value, valueMax, DISPLAY_MODE.PERCENT,false);
		self:UpdateTextStringWithValues(self.RightText,value, valueMax, DISPLAY_MODE.NUMERIC,false);
	end
end

function SoulTextStatusBarMixin:UpdateTextStringWithValues(textString,value,valueMax,displayMode,zeroText)
	if ( tonumber(valueMax) ~= valueMax or valueMax > 0 ) then
		textString:Show();
		if ( value and valueMax > 0 ) then

			--special handling if we want to display something else at zero
			if ( value == 0 and zeroText ) then
				textString:SetText(zeroText);
				return;
			end
			
			if (displayMode == DISPLAY_MODE.NUMERIC) then
				if ( self.capNumericDisplay ) then
					value = AbbreviateLargeNumbers(value);
				end
				textString:SetText(value);
			elseif (displayMode == DISPLAY_MODE.PERCENT) then
				value = tostring(math.ceil((value / valueMax) * 100)) .. "%";
				textString:SetText(value);
			elseif (displayMode == DISPLAY_MODE.VALUE_MAX) then
				if ( self.capNumericDisplay ) then
					value = AbbreviateLargeNumbers(value);
					valueMax = AbbreviateLargeNumbers(valueMax);
				end
				textString:SetText(value.." / "..valueMax);
			end
		end
	else
		textString:Hide();
		textString:SetText("");
		self:SetValue(0);
	end
end