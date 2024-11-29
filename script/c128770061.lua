--M.A 링크 몬스터
local s,id=GetID()
function s.initial_effect(c)
	--링크 소환 조건
	c:EnableReviveLimit()
	Link.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x30d),2,99)

	--①: 상대 필드 특수 소환된 몬스터가 효과 발동 시, 800 LP 감소
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_CHAIN_SOLVING)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.lpcon)
	e1:SetOperation(s.lpop)
	c:RegisterEffect(e1)

	--②: 상대 효과로 필드에서 벗어났을 경우, 엑스트라 덱에서 싱크로 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

--①: LP 감소 조건
function s.lpcon(e,tp,eg,ep,ev,re,r,rp)
	local tc=re:GetHandler()
	return re:IsActiveType(TYPE_MONSTER) and tc:IsLocation(LOCATION_MZONE) and tc:IsControler(1-tp)
		and tc:IsSummonType(SUMMON_TYPE_SPECIAL) and Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)==LOCATION_MZONE
end

--①: LP 감소 처리
function s.lpop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.Damage(1-tp,800,REASON_EFFECT)
end

--②: 링크 소환된 이 카드가 상대 효과로 필드에서 벗어났는지 확인
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsSummonType(SUMMON_TYPE_LINK)
		and rp==1-tp
end

--②: 엑스트라 덱에서 레벨 7 이하의 "M.A" 싱크로 몬스터를 특수 소환
function s.filter(c,e,tp)
	return c:IsSetCard(0x30d) and c:IsType(TYPE_SYNCHRO) and c:IsLevelBelow(7) 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCountFromEx(tp)>0
		and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

--②: 특수 소환 처리
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCountFromEx(tp)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end
