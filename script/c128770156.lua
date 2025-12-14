--Highland Synchro-1
local s,id=GetID()
function s.initial_effect(c)
	 c:EnableReviveLimit()
	-- 싱크로 소환: 튜너 1장 이상 + 튜너 이외 하이랜드 몬스터 1장 이상
	Synchro.AddProcedure(c,
		aux.FilterBoolFunction(Card.IsType,TYPE_TUNER),1,1,		  -- 튜너 1장
		aux.FilterBoolFunction(Card.IsSetCard,0x755),1,99			-- 비튜너 하이랜드 1장 이상
	)
	--① 싱크로 소환 성공 시 덱에서 패
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(function(e,tp,eg,ep,ev,re,r,rp) return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO) end)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--② 상대 카드 1장 효과 무효
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end
s.listed_series={0x755}

--① 덱에서 패
function s.thfilter(c) return c:IsSetCard(0x755) and c:IsAbleToHand() end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--② 효과 무효
function s.deckhand_allunique(tp)
	local g=Duel.GetFieldGroup(tp,LOCATION_DECK+LOCATION_HAND,0)
	return g:GetClassCount(Card.GetCode)==#g
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return re:GetHandler():IsOnField() and re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local ct=1
	if s.deckhand_allunique(tp) then ct=2 end
	for i=1,ct do
		Duel.NegateEffect(ev)
	end
end
