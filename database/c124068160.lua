--LP増強α
local s,id=GetID()
function s.initial_effect(c)
	--skill
	aux.AddPreDrawSkillProcedure(c,2,false,s.flipcon,s.flipop)
end
SKILL_LP_BOOST=id
s[0]=nil
s[1]=nil
function s.flipcon(e,tp,eg,ep,ev,re,r,rp)
	--opd check
	if Duel.GetFlagEffect(tp,id)>0 then return end
	--condition
	return Duel.GetCurrentChain()==0
end
function s.flipop(e,tp,eg,ep,ev,re,r,rp)
	--opd register
	Duel.RegisterFlagEffect(tp,id,0,0,0)
	if not s[tp] then s[tp]=Duel.GetLP(tp) end
	if not s[1-tp] then s[1-tp]=Duel.GetLP(1-tp) end
	--add LP
	Duel.Hint(HINT_SKILL_FLIP,tp,id|(1<<32))
	Duel.Hint(HINT_CARD,tp,id)
	Duel.SetLP(tp,Duel.GetLP(tp)+(s[tp]/4))
end
