--차원경찰 레스토
local s,id=GetID()
function s.initial_effect(c)
	--synchro summon
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(s.synfilter),1,1,Synchro.NonTunerEx(s.synfilter),1,99)
	c:EnableReviveLimit()
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1,false,124331036)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_HANDES+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)	
end

--Part of "Dimension Cap" archetype
s.listed_series={0xda2}

function s.synfilter(c)
	return c:IsRace(RACE_BEASTWARRIOR) or c:IsRace(RACE_WARRIOR)
end
function s.confilter(c)
	return c:IsFaceup() and c:IsSetCard(0xda2)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.confilter,tp,LOCATION_ONFIELD,0,1,e:GetHandler())
end
function s.opfilter(c)
	return (c:IsLocation(LOCATION_GRAVE) and c:IsMonster()) or (c:IsLocation(LOCATION_EXTRA) and c:IsFaceup())
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.IsExistingMatchingCard(s.opfilter,tp,0,LOCATION_GRAVE+LOCATION_EXTRA,1,nil) and Duel.GetLocationCount(1-tp,LOCATION_SZONE)>0 end
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(1-tp,LOCATION_SZONE)==0 then return end
	if not Duel.IsExistingMatchingCard(s.opfilter,tp,0,LOCATION_GRAVE+LOCATION_EXTRA,1,nil) then return end
	local tc=Duel.SelectMatchingCard(tp,s.opfilter,tp,0,LOCATION_GRAVE+LOCATION_EXTRA,1,1,nil):GetFirst()
	if Duel.MoveToField(tc,tp,1-tp,LOCATION_SZONE,POS_FACEUP,true) then
		--Treated as a Continuous Spell
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetValue(TYPE_SPELL|TYPE_CONTINUOUS)
		e1:SetReset(RESET_EVENT|(RESETS_STANDARD&~RESET_TURN_SET))
		tc:RegisterEffect(e1)
	end
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp
end
function s.spfilter(c,e,tp)
	return c:IsFaceup() and c:IsOriginalType(TYPE_MONSTER) and c:IsContinuousSpell() and c:IsAbleToHand()
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,1-tp,LOCATION_SZONE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.spfilter,1-tp,LOCATION_SZONE,0,nil,e,1-tp)
	if #g>0 and Duel.GetMatchingGroupCount(Card.IsDiscardable,tp,0,LOCATION_HAND,e:GetHandler())>0 and Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
		and Duel.SelectYesNo(1-tp,aux.Stringid(id,0)) then
		Duel.DiscardHand(1-tp,nil,1,1,REASON_EFFECT+REASON_DISCARD)
		Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_RTOHAND)
		local sg=g:Select(1-tp,1,1,nil)
		Duel.SendtoHand(sg,1-tp,REASON_EFFECT)
	end
end