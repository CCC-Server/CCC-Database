--Scripted by Edopro Lua Card Script Maker
local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon procedure
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTunerEx(Card.IsAttribute,ATTRIBUTE_FIRE),1,99)

	-- E1: On Synchro Summon, Set specific Spell/Trap from Deck
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.setcon)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	-- E2: Quick Effect - Laval GY recycle + bounce
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetTarget(s.bouncetg)
	e2:SetOperation(s.bounceop)
	c:RegisterEffect(e2)

	-- E3: Quick Effect during opponent's turn - Tag out into Laval Synchro
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.spcon)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- E1 Condition: Only if Synchro Summoned
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.setfilter(c)
	return (c:IsCode(72142276) or c:IsCode(74845897)) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g:GetFirst())
	end
end

-- E2: Laval recycle + bounce
function s.tdfilter(c)
	return c:IsSetCard(0x39) and c:IsAbleToDeck()
end
function s.bouncetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_GRAVE,0,1,nil)
			and Duel.IsExistingTarget(nil,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g1=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g2=Duel.SelectTarget(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
end
function s.bounceop(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	local tg1=tg:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
	local tg2=tg:Filter(Card.IsLocation,nil,LOCATION_ONFIELD)
	if #tg1>0 and Duel.SendtoDeck(tg1,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		Duel.BreakEffect()
		Duel.SendtoHand(tg2,nil,REASON_EFFECT)
	end
end

-- E3: Condition – Opponent’s turn
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp
end
function s.spcfilter(c,exclude)
	return c:IsSetCard(0x39) and c:IsAbleToRemoveAsCost() and c~=exclude
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToRemoveAsCost() and Duel.IsExistingMatchingCard(s.spcfilter,tp,LOCATION_GRAVE,0,1,nil,c)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.spcfilter,tp,LOCATION_GRAVE,0,1,1,nil,c)
	g:AddCard(c)  -- 자기 자신도 같이 제외
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(0x39) and c:IsType(TYPE_SYNCHRO) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
		g:GetFirst():CompleteProcedure()
	end
end

