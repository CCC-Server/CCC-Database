--Armed Revolution
local s,id=GetID()
function s.initial_effect(c)
	--------------------------------
	-- 발동: "Armed Dragon" 서치 + (옵션) 드로우
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- 이름이 같은 카드의 발동은 1턴에 1번
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--------------------------------
-- 공용: "Armed Dragon" 세트 (0x111 가정)
--------------------------------
function s.adcard(c)
	return c:IsSetCard(0x111)
end

--------------------------------
-- 코스트: 패의 "Armed Dragon" 몬스터를 보내는 것은 선택사항
-- "You can also activate this card by sending 1 "Armed Dragon" monster..." 구현
--------------------------------
function s.costfilter(c)
	return s.adcard(c) and c:IsType(TYPE_MONSTER) and c:IsAbleToGraveAsCost()
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	-- 옵션: 패의 "Armed Dragon" 몬스터를 묘지로 보내고 발동할지 여부
	e:SetLabel(0)
	if Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND,0,1,nil)
		and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND,0,1,1,nil)
		if #g>0 then
			Duel.SendtoGrave(g,REASON_COST)
			e:SetLabel(1) -- 코스트로 보냈다는 표시
		end
	end
end

--------------------------------
-- 서치 / 드로우
--------------------------------
function s.thfilter(c)
	return s.adcard(c) and c:IsAbleToHand()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	if e:GetLabel()==1 then
		-- 코스트로 "Armed Dragon"을 보냈다면 드로우도 표시
		Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
	end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- ① 덱에서 "Armed Dragon" 카드 1장 서치
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		if Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,g)
		end
	else
		return
	end
	-- 코스트로 "Armed Dragon"을 보냈다면 1장 드로우
	if e:GetLabel()==1 then
		if Duel.IsPlayerCanDraw(tp,1) then
			Duel.BreakEffect()
			Duel.Draw(tp,1,REASON_EFFECT)
		end
	end
end
