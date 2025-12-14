--Spellcraft ???  (임시 카드명)
local s,id=GetID()
function s.initial_effect(c)
	------------------------------------------------------------
	--① 패에서 특수 소환
	------------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id) --① : 1턴 1번
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	------------------------------------------------------------
	--② 덱 되돌리고 서치 + 가마솥 마력카운터
	------------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1,id+100) --② : 1턴 1번 (ID 다르게)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end


------------------------------------------------------------
--①: 자신 필드에 "스펠크래프트" 몬스터가 존재할 경우 패에서 특소
------------------------------------------------------------
function s.spfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x761)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end


------------------------------------------------------------
--②: 패의 마법사족 1장 덱 되돌리고 → 다른 이름의 레벨 4 이하 스펠크래프트 서치
------------------------------------------------------------
function s.costfilter(c)
	return c:IsRace(RACE_SPELLCASTER) and c:IsAbleToDeckAsCost()
end
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND,0,1,1,nil)
	e:SetLabel(g:GetFirst():GetCode())   -- 되돌린 카드명 기억
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
end

function s.thfilter(c,code)
	return c:IsSetCard(0x761)
		and c:IsLevelBelow(4)
		and not c:IsCode(code)
		and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local code=e:GetLabel()
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil,code) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.cowfilter(c)
	return c:IsFaceup() and c:IsCode(128770286) -- 가마솥
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local code=e:GetLabel()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,code)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)

		--가마솥이 있으면 카운터 +1
		local tc=Duel.GetFirstMatchingCard(s.cowfilter,tp,LOCATION_SZONE,0,nil)
		if tc then
			tc:AddCounter(0x1,1)  -- 가마솥이 사용하는 카운터 ID=0x1 예시
		end
	end
end
