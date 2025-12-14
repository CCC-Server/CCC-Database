local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon
	c:EnableReviveLimit()
	Link.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x769),1,1)

	-- E1: On Link Summon → Activate "Archeoseeker Dig Site" from Deck
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.accon)
	e1:SetOperation(s.acop)
	c:RegisterEffect(e1)

	-- E2: If sent from Extra Deck to GY → search 1 "Archeoseeker" card
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- E1 조건: 링크 소환 시
function s.accon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end
-- E1 실행: 필드 마법 직접 발동
function s.acop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstMatchingCard(function(c) return c:IsCode(128770399) end,tp,LOCATION_DECK,0,nil)
	if tc then
		Duel.ActivateFieldSpell(tc,e,tp,eg,ep,ev,re,r,rp)
	end
end

-- Dig Site 카드코드 (직접 발동용)
-- 위키에는 일반적으로 카드 코드 하드코딩이 필요
local DIG_SITE_CODE = 128770399 -- 이 자리에 "Archeoseeker Dig Site"의 실제 카드 코드를 넣어주세요

-- 필드 발동용 필터
function s.fieldfilter(c)
	return c:IsCode(DIG_SITE_CODE)
end

-- E2 조건: 엑스트라 덱에서 묘지로 보냄
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_EXTRA)
end
-- E2 타겟
function s.thfilter(c)
	return c:IsSetCard(0x769) and c:IsAbleToHand()
end
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
