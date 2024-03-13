--Declaration
if not Unimplemented then
	Unimplemented = {}
end
--constants
CARD_UNIMPLEMENTED          = 0x7580910
HINTMSG_UNIMPLEMENTED       = aux.Stringid(0x7580910,0)
--unimplemented card proc
Card.Unimplemented = function(c)
	if not c then
		Debug.PrintStacktrace()
		Debug.Message("Error: Unimplemented.Card should be used with Card parameter")
		Debug.Message("(카드 변수와 함께 사용되어야 합니다)")
		return
	end
	if not c:IsStatus(STATUS_INITIALIZING) then
		Debug.PrintStacktrace()
		Debug.Message("Error: Unimplemented.Card should be used on initializing")
		Debug.Message("(카드 초기화 단계에서 사용되어야 합니다)")
		return
	end
	local code=c:GetCode()
	local setcodes={Duel.GetCardSetcodeFromCode(code)}
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetValue(CARD_UNIMPLEMENTED)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_ADD_CODE)
	e2:SetValue(code)
	c:RegisterEffect(e2)
	for _,v in pairs(setcodes) do
		if v>0 then
			local e3=e1:Clone()
			e3:SetCode(EFFECT_ADD_SETCODE)
			e3:SetCondition(function(e) return e:GetHandler():IsCode(CARD_UNIMPLEMENTED,code) end)
			e3:SetValue(v)
			c:RegisterEffect(e3)
		end
	end
end
