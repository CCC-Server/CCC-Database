Duel.LoadScript("skills_archive.lua")
--Dreamy Dream Dreamers
local s,id=GetID()
function s.initial_effect(c)
	aux.AddSkillProcedure(c,SKILL_COVER_ARCHIVE_START,false,nil,nil)
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_STARTUP)
	e1:SetCountLimit(1)
	e1:SetRange(LOCATION_SKILL)
	e1:SetOperation(s.flipop)
	c:RegisterEffect(e1)
	aux.GlobalCheck(s,function()
		--predraw
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(0)
		Duel.RegisterEffect(ge1,0)
	end)
end
function s.flipop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SKILL_FLIP,tp,id|(1<<32))
	Duel.Hint(HINT_CARD,tp,id)
	if Duel.GetFlagEffect(tp,id)==0 then
		--predraw
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PREDRAW)
		e1:SetCondition(s.prdcon)
		e1:SetOperation(s.prdop)
		Duel.RegisterEffect(e1,tp)
	end
	Duel.RegisterFlagEffect(ep,id,0,0,0)
end
function s.prdcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentChain()==0 and Duel.GetTurnPlayer()==tp
		and Duel.GetDrawCount(tp)>0 and (Duel.GetTurnCount()>1 or Duel.IsDuelType(DUEL_1ST_TURN_DRAW))
		and not Duel.GetDrawCount(tp)>Duel.GetLocationCount(tp,LOCATION_DECK)
end
function s.prdop(e,tp,eg,ep,ev,re,r,rp)
	--ask if you want to activate the skill or not
	if not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then return end
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,1))
	local ct=Duel.GetDrawCount(tp)
	local dg=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_DECK,0,nil)
	if ct>=#dg then return end
	local drg=dg:Select(tp,ct,ct,false,nil)
	--ask if you want to shuffle the deck and announce skill usage
	if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_CARD,tp,id)
		Duel.ShuffleDeck(tp)
		while #drg>0 do
			local tc=drg:RandomSelect(PLAYER_NONE,1):GetFirst()
			Duel.MoveSequence(tc,0)
			drg:Sub(tc)
		end
	else
		Duel.DisableShuffleCheck(true)
		--To fix later
		for tc in aux.Next(drg) do
			Duel.MoveSequence(tc,0)
		end
	end
end
