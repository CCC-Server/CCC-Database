--네메시스 아티팩트 - ??? (예시 ID)
local s,id=GetID()
function s.initial_effect(c)
	--① 일반/특수 소환 성공시 서치
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)
	--② 융합 소재로 사용된 네메시스 아티팩트 융합 몬스터에게 내성 부여
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_BE_MATERIAL)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.efcon)
	e3:SetOperation(s.efop)
	c:RegisterEffect(e3)
end

----------------------------------------------------
--① 소환 성공 시 서치
----------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(0x764) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.lv8filter(c)
	return c:IsFaceup() and c:IsSetCard(0x764) and c:IsLevel(8)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ct=1
	if Duel.IsExistingMatchingCard(s.lv8filter,tp,LOCATION_MZONE,0,1,nil) then
		ct=2
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,ct,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

----------------------------------------------------
--② 융합 소재로 사용된 경우
----------------------------------------------------
function s.efcon(e,tp,eg,ep,ev,re,r,rp)
	return r & REASON_FUSION ~= 0
end
function s.efop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	if not (rc and rc:IsSetCard(0x764) and rc:IsType(TYPE_FUSION)) then return end
	--전투로 파괴되지 않음
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	rc:RegisterEffect(e1,true)
	--효과로 파괴되지 않음
	local e2=e1:Clone()
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	rc:RegisterEffect(e2,true)
end
