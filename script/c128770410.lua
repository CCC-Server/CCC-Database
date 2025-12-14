--가제트 타운
local s,id=GetID()
function s.initial_effect(c)
	---------------------------------------
	--①: 발동 시 가제트 카드 서치
	---------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH) -- 카드명으로 1턴 1회 발동
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	---------------------------------------
	--②: 가제트 몬스터 어드밴스 소환 시 릴리스 1개 감소
	---------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SUMMON_PROC)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_HAND,0)
	e2:SetCondition(s.ntcon)
	e2:SetOperation(s.ntop)
	c:RegisterEffect(e2)

	---------------------------------------
	--③: 파괴되어 묘지로 갔을 때 → 가제트 서치 + 일반 소환 선택
	---------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCondition(s.thsumcon)
	e3:SetTarget(s.thsumtg)
	e3:SetOperation(s.thsumop)
	e3:SetCountLimit(1,{id,1}) -- 카드명의 ③번 효과 1턴 1회
	c:RegisterEffect(e3)
end

-------------------------------------
-- ①: 발동 시 가제트 서치
-------------------------------------
function s.thfilter(c)
	return c:IsSetCard(0x51) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) 
	end
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

-------------------------------------
-- ②: 릴리스 1개 줄이기 (레벨 5 이상 가제트)
-------------------------------------
function s.ntcon(e,c,minc)
	if c==nil then return true end
	return c:IsSetCard(0x51) and c:IsLevelAbove(5) and Duel.CheckTribute(c,0)
end
function s.ntop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectTribute(tp,c,0,1,nil)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
end

-------------------------------------
-- ③: 파괴 시 가제트 서치 + 일반 소환 선택
-------------------------------------
function s.thsumcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_DESTROY) and c:IsPreviousLocation(LOCATION_ONFIELD)
end
function s.thsumfilter(c)
	return c:IsSetCard(0x51) and c:IsAbleToHand() and c:IsSummonable(true,nil)
end
function s.thsumtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.thsumfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_HAND,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_HAND)
end
function s.thsumop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thsumfilter,tp,
		LOCATION_DECK+LOCATION_GRAVE+LOCATION_HAND,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
		Duel.BreakEffect()
		if tc:IsSummonable(true,nil) and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.Summon(tp,tc,true,nil)
		end
	end
end
