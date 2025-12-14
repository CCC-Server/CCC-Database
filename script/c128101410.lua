--Ojama Yellow Riding Armed Dragon
local s,id=GetID()
function s.initial_effect(c)
	--Link Summon
	c:EnableReviveLimit()
	-- 재료: 1 Level 3 이하의 "Armed Dragon" 몬스터 또는 1장의 "Ojama" 몬스터
	-- ⚠ 아래 0xf, 0x111 세트 코드는 사용 중인 DB에 맞게 조정해 주세요.
	Link.AddProcedure(c,s.matfilter,1,1)

	--① If this card is Link Summoned: add 1 "Ojama" or "Armed Dragon" card from Deck to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id) -- 이름이 같은 이 카드의 ①효과는 1턴에 1번
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--② If this card is sent to GY to activate a card effect: 
	--    WIND Dragon monsters you control gain 300 ATK this turn
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1}) -- 이름이 같은 이 카드의 ②효과는 1턴에 1번(①와 별도)
	e2:SetCondition(s.atkcon)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
end

--------------------------------
-- Link 소재 조건
--------------------------------
-- ⚠ 세트코드 주의:
-- 0xf   : "Ojama" (일반적으로 이렇게 쓰입니다)
-- 0x111 : "Armed Dragon" (DB에 따라 다를 수 있으니 필요하면 수정)
function s.matfilter(c,lc,sumtype,tp)
	return (
		-- Level 3 이하의 "Armed Dragon" 몬스터
		c:IsSetCard(0x111,lc,sumtype,tp) and c:IsLevelBelow(3)
	)
	or
		-- "Ojama" 몬스터 (레벨 제한 없음)
		c:IsSetCard(0xf,lc,sumtype,tp)
end

--------------------------------
-- ① 서치 효과
--------------------------------
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.thfilter(c)
	-- "Ojama" 카드 또는 "Armed Dragon" 카드
	return (c:IsSetCard(0xf) or c:IsSetCard(0x111)) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--------------------------------
-- ② 묘지로 보내졌을 때 ATK 업
--------------------------------
-- "이 카드가 카드의 효과를 발동하기 위해 묘지로 보내졌을 경우"
-- → 보통 '코스트로 보내짐' 체크: REASON_COST + 발동된 효과 re:IsActivated()
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return re and re:IsActivated()
		and (r&REASON_COST)~=0
		and (r&REASON_EFFECT)~=0
end

-- WIND / Dragon 몬스터만 공격력 상승
function s.atkfilter(e,c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_WIND) and c:IsRace(RACE_DRAGON)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 필드 전체에 적용되는 일시적인 공격력 상승 효과 생성
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.atkfilter)
	e1:SetValue(300)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
