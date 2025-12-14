-- Highland Selector
local s,id=GetID()
function s.initial_effect(c)
	-- ① 발동
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.actcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

---------------------------------------
--		[ 발동 조건 ] 
-- 덱 + 패의 모든 카드명이 서로 달라야 함
---------------------------------------

function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(tp,LOCATION_DECK+LOCATION_HAND,0)
	local names = {}
	for tc in aux.Next(g) do
		local code = tc:GetCode()
		if names[code] then 
			return false 
		end
		names[code] = true
	end
	return true
end

---------------------------------------
--		[ 서치 타겟 ]
---------------------------------------

function s.thfilter(c)
	return c:IsSetCard(0x755) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,3,nil) 
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

---------------------------------------
--		[ 발동 처리 ]
-- ① 덱에서 하이랜드 카드 3장 공개
-- ② 상대가 1장 선택 → 패로
-- ★ 발동 후 actcon 비활성화 (중요)
---------------------------------------

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- (1) 카드 3장 공개 → 상대가 1장 선택
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if #g<3 then return end

	local sg=g:RandomSelect(1-tp,3)
	Duel.ConfirmCards(1-tp,sg)

	local sel=sg:RandomSelect(1-tp,1)
	if #sel>0 then
		Duel.SendtoHand(sel,nil,REASON_EFFECT)
		Duel.ShuffleHand(tp)
	end

	-- (2) ★ 핵심: 발동 조건(actcon) 즉시 비활성화
	-- 이 효과가 남아있으면 엔진이 체인판단 중 계속 덱 검사해서 다른 마법 발동이 막힘
	local c=e:GetHandler()
	c:ResetEffect(id,RESET_CARD)
end
