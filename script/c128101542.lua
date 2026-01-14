-- 데드웨어 논리 폭탄
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 자신 필드에 "데드웨어" 몬스터가 존재할 경우, 자신 / 상대 필드에 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ②: 일반 소환 / 특수 소환되었을 경우 발동 (원래의 주인이 세트)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F) -- 강제 효과
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2b)

	-- ③: 묘지로 보내졌을 경우 발동 (상대의 패에 넣는다)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O) -- 선택 효과
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

-- ① 효과 로직
function s.spfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc55) -- "데드웨어" 카드군 번호
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		or Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	local b2=Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4)) -- 3:자신 필드, 4:상대 필드
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,3))
	elseif b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,4))+1
	else return end
	local target_player = (op==0) and tp or 1-tp
	Duel.SpecialSummon(c,0,tp,target_player,false,false,POS_FACEUP)
end

-- ② 효과 로직
function s.setfilter(c)
	return c:IsSetCard(0xc55) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local owner=e:GetHandler():GetOwner() -- 원래의 주인 확인
	if Duel.GetLocationCount(owner,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,owner,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(owner,s.setfilter,owner,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(owner,g:GetFirst())
	end
end

-- ③ 효과 로직
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		-- 1-tp는 현재 발동한 플레이어의 상대(즉, 이 카드의 원래 컨트롤러의 상대)를 의미합니다.
		-- 하지만 효과 텍스트가 "상대의 패"이므로, 효과 발동자(tp) 기준 상대를 지정합니다.
		Duel.SendtoHand(c,1-tp,REASON_EFFECT)
		Duel.ConfirmCards(tp,c)
	end
end