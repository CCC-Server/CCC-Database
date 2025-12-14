--기동요새 스트랭스 홀드
local s,id=GetID()
function s.initial_effect(c)
	--①: 발동 → 몬스터로 취급 후 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	--②: 어드밴스 가제트 3장 이상 존재 시 상대 효과 1턴 1번 무효화
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.negcon)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	--③: 파괴되거나 묘지로 갔을 때 → 레벨4 이하 가제트 서치
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.thcon)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

--몬스터 특성 설정
function s.monster_stat(c)
	c:AddMonsterAttribute(TYPE_EFFECT+TYPE_TRAP)
	c:AddMonsterAttribute(TYPE_NORMAL+TYPE_TRAP)
end

--①: 몬스터로서 특수 소환
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,id,0x51,TYPES_EFFECT_TRAP_MONSTER,2000,0,4,RACE_MACHINE,ATTRIBUTE_EARTH) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,id,0x51,TYPES_EFFECT_TRAP_MONSTER,2000,0,4,RACE_MACHINE,ATTRIBUTE_EARTH) then return end
	c:AddMonsterAttribute(TYPE_EFFECT+TYPE_TRAP)
	Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP)
end

--②: 어드밴스 가제트 3장 이상 존재 시 → 상대 효과 1턴 1번 무효화
function s.negfilter(c)
	return c:IsSetCard(0x51) and c:IsSummonType(SUMMON_TYPE_ADVANCE)
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if rp==tp or not Duel.IsChainDisablable(ev) then return false end
	local g=Duel.GetMatchingGroup(s.negfilter,tp,LOCATION_MZONE,0,nil)
	return g:GetCount()>=3
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end

--③: 묘지로 보내졌을 때 → 레벨4 이하 가제트 서치
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_DESTROY) or c:IsPreviousLocation(LOCATION_ONFIELD)
end
function s.thfilter(c)
	return c:IsSetCard(0x51) and c:IsLevelBelow(4) and c:IsAbleToHand()
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
