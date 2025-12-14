--Highland Recovery (예시 이름)
local s,id=GetID()
function s.initial_effect(c)
	--① 패에서 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)
	--② 소환 성공시 LP 회복
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_RECOVER)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,2})
	e2:SetTarget(s.rectg)
	e2:SetOperation(s.recop)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2b)
	--③ 묘지로 갔을 때 서치
local e3=Effect.CreateEffect(c)
e3:SetDescription(aux.Stringid(id,2))
e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
e3:SetProperty(EFFECT_FLAG_DELAY)  -- 🔹 타이밍 놓치지 않게 추가
e3:SetCode(EVENT_TO_GRAVE)
e3:SetCountLimit(1,{id,3})
e3:SetTarget(s.thtg)
e3:SetOperation(s.thop)
c:RegisterEffect(e3)
end
s.listed_series={0x755}

--① 패특소 조건
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x755)
end
function s.spcon(e,c)
	if c==nil then return true end
	return Duel.IsExistingMatchingCard(s.cfilter,c:GetControler(),LOCATION_ONFIELD,0,1,nil)
end

--덱/패 카드명이 모두 다른지 체크
function s.deckhand_allunique(tp)
	local dg=Duel.GetFieldGroup(tp,LOCATION_DECK,0)
	local hg=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	for dc in aux.Next(dg) do
		if hg:IsExists(Card.IsCode,1,nil,dc:GetCode()) then
			return false
		end
	end
	return true
end

--② LP 회복
function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk)
	local val=1000
	if s.deckhand_allunique(tp) then val=1500 end
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,val)
	e:SetLabel(val)
end
function s.recop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Recover(tp,e:GetLabel(),REASON_EFFECT)
end

--③ 서치 (하이랜드 마/함)
function s.thfilter(c)
	return c:IsSetCard(0x755) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and c:IsAbleToHand()
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
