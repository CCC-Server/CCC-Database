local s,id=GetID()
function s.initial_effect(c)
	--엑시즈 소환
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x763),8,2)
	c:EnableReviveLimit()

	--① 엑시즈 소환 성공 시: 덱에서 "네메시스 퍼펫 로이드" 특소
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	--② 소재 1개 제거 후: "네메시스 퍼펫" 전부 직접 공격 가능
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.cost)
	e2:SetOperation(s.diract)
	c:RegisterEffect(e2)

	--③ 전투 데미지 발생 시: 소재 일반 몬스터 다수 특소 후 엔드 페이즈 파괴
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DAMAGE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.spcon2)
	e3:SetTarget(s.sptg2)
	e3:SetOperation(s.spop2)
	c:RegisterEffect(e3)
end

s.listed_series={0x763}
s.listed_names={128770303} -- "네메시스 퍼펫 로이드"의 가상 코드

------------------------------------------
--① 엑시즈 소환 성공 시 특수 소환
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end
function s.spfilter(c,e,tp)
	return c:IsCode(128770303) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

------------------------------------------
--② 소재 제거 후 직접 공격 허용
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.dirfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x763)
end
function s.diract(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.dirfilter,tp,LOCATION_MZONE,0,nil)
	local tc=g:GetFirst()
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DIRECT_ATTACK)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
end

------------------------------------------
--③ 전투 데미지 발생 시: 소재 일반 몬스터 다수 특소
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return ep~=tp
end
function s.spfilter2(c,e,tp)
	return c:IsSetCard(0x763) and c:IsType(TYPE_NORMAL)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_ATTACK)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:GetOverlayGroup():IsExists(s.spfilter2,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_OVERLAY)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=c:GetOverlayGroup():Filter(s.spfilter2,nil,e,tp)
	if #g==0 then return end
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if #g>ft then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		g=g:Select(tp,ft,ft,nil)
	end
	local sg=Group.CreateGroup()
	for tc in aux.Next(g) do
		if Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP_ATTACK) then
			sg:AddCard(tc)
		end
	end
	Duel.SpecialSummonComplete()
	-- 엔드 페이즈 파괴
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetCountLimit(1)
	e1:SetLabelObject(sg)
	e1:SetOperation(s.desop)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	if g then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
