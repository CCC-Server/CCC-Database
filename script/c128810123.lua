--드래고니아-폭룡왕의 어명
local s,id=GetID()
function s.initial_effect(c)
	-- 일반 마법 발동
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- 카드명당 1턴 1장 발동 제한
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={0xc05} -- "드래고니아" 세트코드 (예시)

-- 엑스트라 덱에서 공개할 "드래고니아" 싱크로 몬스터
function s.revealfilter(c)
	return c:IsSetCard(0xc05) and c:IsType(TYPE_SYNCHRO) and not c:IsPublic()
end
-- 덱에서 서치할 같은 속성의 "드래고니아" 몬스터
function s.thfilter(c,att)
	return c:IsSetCard(0xc05) and c:IsType(TYPE_MONSTER) and c:IsAttribute(att) and c:IsAbleToHand()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.revealfilter,tp,LOCATION_EXTRA,0,1,nil)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- ① 엑스트라 덱에서 공개
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.revealfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	if #g==0 then return end
	Duel.ConfirmCards(1-tp,g)
	local att=g:GetFirst():GetAttribute()
	Duel.ShuffleExtra(tp)
	-- ② 같은 속성의 "드래고니아" 몬스터 서치
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local sg=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,att)
	if #sg>0 then
		if Duel.SendtoHand(sg,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,sg)
			-- ③ 패 1장 덱 맨 위로 되돌리기
			if Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
				local tg=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_HAND,0,1,1,nil)
				if #tg>0 then
					Duel.SendtoDeck(tg,nil,SEQ_DECKTOP,REASON_EFFECT)
				end
			end
		end
	end
end