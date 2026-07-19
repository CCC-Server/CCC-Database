-- 칸티고 트라시메
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 패의 레벨 5 이상 몬스터 2장까지 공개하고 효과 발동
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost1)
	e1:SetTarget(s.tg1)
	e1:SetOperation(s.op1)
	c:RegisterEffect(e1)
	
	-- ②: 패에서 공개 중일 때 자체 특수 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_HAND)
	e2:SetCondition(s.spcon)
	c:RegisterEffect(e2)

	-- ②: 패에서 공개 중일 때 레벨 5/10 몬스터 내성
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_REMOVE)
	e3:SetRange(LOCATION_HAND)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetCondition(s.pubcon)
	e3:SetTarget(s.protg)
	e3:SetValue(s.proval)
	c:RegisterEffect(e3)

	local e4=e3:Clone()
	e4:SetCode(EFFECT_CANNOT_TO_HAND)
	c:RegisterEffect(e4)

	local e5=e3:Clone()
	e5:SetCode(EFFECT_CANNOT_TO_DECK)
	c:RegisterEffect(e5)
end

s.listed_series={0xfa9}

-- [① 코스트] 최대 2장까지 공개
function s.cfilter(c)
	return c:IsLevelAbove(5) and not c:IsPublic()
end

function s.cost1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	-- 자기 자신은 공개 대상에 포함됨 (최대 2장, 최소 1장)
	local g=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_HAND,0,c)
	if chk==0 then return not c:IsPublic() and (#g>=0) end -- 0장(자신만) 혹은 1장 추가 선택 가능
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local sg=g:Select(tp,0,1,nil) -- 자신 외에 0~1장을 추가 선택
	sg:AddCard(c)
	Duel.ConfirmCards(1-tp,sg)
	for tc in aux.Next(sg) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_PUBLIC)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
	end
end

-- [① 타겟 지정]
function s.setfilter(c)
	return c:IsSetCard(0xfa9) and c:IsSpellTrap() and c:IsSSetable()
end

function s.tg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

-- [① 특수 소환 필터]
function s.ssfilter(c,e,tp)
	return c:GetFlagEffect(id)>0 and c:IsRace(RACE_WARRIOR) and c:IsLevel(5) 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- [① 효과 처리]
function s.op1(e,tp,eg,ep,ev,re,r,rp)
	local sg=Duel.GetMatchingGroup(s.ssfilter,tp,LOCATION_HAND,0,nil,e,tp)
	if #sg>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local spc=sg:Select(tp,1,1,nil)
		if Duel.SpecialSummon(spc,0,tp,tp,false,false,POS_FACEUP)>0 then
			local tg=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_DECK,0,nil)
			if #tg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then -- 세트 여부 확인
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
				local sc=tg:Select(tp,1,1,nil)
				Duel.BreakEffect()
				Duel.SSet(tp,sc:GetFirst())
			end
		end
	end
end

-- [② 공통 로직]
function s.pubcon(e) return e:GetHandler():IsPublic() end
function s.spcon(e,c)
	if c==nil then return true end
	return e:GetHandler():IsPublic() and Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)>0
end
function s.protg(e,c)
	return c:IsFaceup() and (c:IsLevel(5) or c:IsLevel(10))
end
function s.proval(e,re,rp)
	return rp~=e:GetHandlerPlayer() and re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end