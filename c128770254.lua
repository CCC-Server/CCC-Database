--드래곤 듀얼 트리니티 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--융합 소환 조건
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c,true,true,s.ffilter,3,3)

	--① 융합 소환 성공 시 : 드래곤족 듀얼 몬스터 2장 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	e1:SetCountLimit(1,{id,1})
	c:RegisterEffect(e1)

	--② 자신 / 상대 턴 : 한번 더 소환된 드래곤족 1장 직접 공격 허용
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCountLimit(1,{id,2})
	e2:SetTarget(s.dirtg)
	e2:SetOperation(s.dirop)
	c:RegisterEffect(e2)

	--③ 자신 / 상대 턴 : 다른 한번 더 소환된 드래곤족 1장에게 내성 부여
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e3:SetCountLimit(1,{id,3})
	e3:SetTarget(s.protg)
	e3:SetOperation(s.protop)
	c:RegisterEffect(e3)
end

--융합 소재: 드래곤족 듀얼 몬스터
function s.ffilter(c,fc,sumtype,tp,sub,mg,sg)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI)
end

--① 융합 소환 성공 체크
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

--① 특수 소환
function s.spfilter(c,e,tp)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_HAND,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_HAND)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<1 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK+LOCATION_HAND,0,1,2,nil,e,tp)
	-- 같은 이름의 카드는 1장만
	local sg=Group.CreateGroup()
	for tc in aux.Next(g) do
		if not sg:IsExists(Card.IsCode,1,nil,tc:GetCode()) then
			sg:AddCard(tc)
		end
	end
	if #sg>0 then
		Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
	end
end

--② 직접 공격 허용
function s.dirfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI)
		and c:IsSummonType(SUMMON_TYPE_NORMAL) and c:IsStatus(STATUS_EFFECT_ENABLED)
end
function s.dirtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and s.dirfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.dirfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.dirfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.dirop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DIRECT_ATTACK)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
end

--③ 내성 부여
function s.protfilter(c,e)
	return c:IsFaceup() and c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI)
		and c:IsSummonType(SUMMON_TYPE_NORMAL)
		and (not e or c~=e:GetLabelObject())
end
function s.protg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and s.protfilter(chkc,e) end
	if chk==0 then return Duel.IsExistingTarget(s.protfilter,tp,LOCATION_MZONE,0,1,nil,e) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,s.protfilter,tp,LOCATION_MZONE,0,1,1,nil,e)
	if #g>0 then
		e:SetLabelObject(g:GetFirst())
	end
end
function s.protop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) then
		--대상 내성
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e1:SetRange(LOCATION_MZONE)
		e1:SetValue(aux.tgoval)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		--전투 파괴 내성
		local e2=e1:Clone()
		e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
		e2:SetValue(1)
		tc:RegisterEffect(e2)
	end
end

