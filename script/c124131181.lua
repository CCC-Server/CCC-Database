--링크된 엑조디아
local WIN_REASON_LINKED_EXODIA=0x810
local s,id=GetID()
function s.initial_effect(c)
	--link summon
	c:EnableReviveLimit()
	Link.AddProcedure(c,nil,3,3)
	--win
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EVENT_ADJUST)
	e1:SetOperation(s.winop)
	c:RegisterEffect(e1)
end
s.listed_names={id+1,id+2,id+3,id+4}
function s.check(g)
	local a1=false
	local a2=false
	local a3=false
	local a4=false
	local tc=g:GetFirst()
	for tc in aux.Next(g) do
		local code=tc:GetCode()
		if code==id+1 then a1=true
			elseif code==id+2 then a2=true
			elseif code==id+3 then a3=true
			elseif code==id+4 then a4=true
		end
		if tc:GetOriginalCode()==id then a5=true end
	end
	return a1 and a2 and a3 and a4 and a5
end
function s.winop(e,tp,eg,ep,ev,re,r,rp)
	local g1=Duel.GetFieldGroup(tp,LOCATION_MZONE,0)
	local g2=Duel.GetFieldGroup(tp,0,LOCATION_MZONE)
	local wtp=s.check(g1)
	local wntp=s.check(g2)
	if wtp and not wntp then
		Duel.ConfirmCards(1-tp,g1)
		Duel.Win(tp,WIN_REASON_LINKED_EXODIA)
	elseif not wtp and wntp then
		Duel.ConfirmCards(tp,g2)
		Duel.Win(1-tp,WIN_REASON_LINKED_EXODIA)
	elseif wtp and wntp then
		Duel.ConfirmCards(1-tp,g1)
		Duel.ConfirmCards(tp,g2)
		Duel.Win(PLAYER_NONE,WIN_REASON_LINKED_EXODIA)
	end
end
