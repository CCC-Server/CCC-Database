local s,id=GetID()
function s.initial_effect(c)
	-- ① 패에서 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- ② 소환 성공 시 덱에서 세트
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,id+1)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- ③ 엑스트라 덱에서 특수 소환 시, 융합 몬스터 부활
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+2)
	e4:SetCondition(s.spcon2)
	e4:SetTarget(s.sptg2)
	e4:SetOperation(s.spop2)
	c:RegisterEffect(e4)
end

-- 카드군 필터 (네메시스 아티팩트 몬스터)
function s.nemesis_monster(c)
	return c:IsFaceup() and c:IsSetCard(0x764) and c:IsType(TYPE_MONSTER)
end

-- ① 특수 소환 조건
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.nemesis_monster,tp,LOCATION_MZONE,0,1,nil)
end

-- ② 세트 가능한 네메시스 아티팩트 마법/함정 필터
function s.setfilter(c)
	return c:IsSetCard(0x764) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end

-- ② 타겟: 덱에서 1장 세트
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
end

-- ② 작동: 세트
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g:GetFirst())
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ③ 트리거 조건: 엑스트라 덱에서 특수 소환된 네메시스 아티팩트 몬스터
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c)
		return c:IsSetCard(0x764) and c:IsSummonPlayer(tp) and c:IsSummonLocation(LOCATION_EXTRA)
	end,1,nil)
end

-- ③ 대상 필터: 묘지에 있는 네메시스 아티팩트 융합 몬스터 (레벨 8 이하)
function s.fufilter(c,e,tp)
	return c:IsSetCard(0x764) and c:IsType(TYPE_FUSION) and c:IsLevelBelow(8)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ③ 타겟: 최대 2장까지 선택
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.fufilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

-- ③ 작동: 특수 소환 후 엔드페이즈에 파괴 처리 등록
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.fufilter,tp,LOCATION_GRAVE,0,1,2,nil,e,tp)
	if #g==0 then return end
	for tc in aux.Next(g) do
		if Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP) then
			-- 엔드페이즈에 파괴
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetDescription(aux.Stringid(id,2))
			e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e1:SetCode(EVENT_PHASE+PHASE_END)
			e1:SetCountLimit(1)
			e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
			e1:SetLabelObject(tc)
			e1:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
				local tc=e:GetLabelObject()
				return tc and tc:IsOnField()
			end)
			e1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
				local tc=e:GetLabelObject()
				if tc then
					Duel.Destroy(tc,REASON_EFFECT)
				end
				e:Reset()
			end)
			Duel.RegisterEffect(e1,tp)
		end
	end
	Duel.SpecialSummonComplete()
end
