Duel.LoadScript("skills_archive.lua")
--LP増強α
local s,id=GetID()
function s.initial_effect(c)
	aux.AddSkillProcedure(c,2,false,nil,nil)
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_STARTUP)
	e1:SetCountLimit(1)
	e1:SetRange(0x5f)
	e1:SetLabel(0)
	e1:SetOperation(s.flipop)
	c:RegisterEffect(e1)
end
s[0]=nil
s[1]=nil
function s.flipop(e,tp,eg,ep,ev,re,r,rp)
	--activate
	Duel.Hint(HINT_SKILL_FLIP,tp,id|(1<<32))
	Duel.Hint(HINT_CARD,tp,id)
	local c=e:GetHandler()
	if Duel.GetFlagEffect(tp,id)==0 then
		--starting LP
		if not s[tp] then s[tp]=Duel.GetLP(tp) end
		if not s[1-tp] then s[1-tp]=Duel.GetLP(1-tp) end
		--add LP
		Duel.SetLP(tp,Duel.GetLP(tp)+(s[tp]/4))
	end
	Duel.RegisterFlagEffect(ep,id,0,0,0)
end
