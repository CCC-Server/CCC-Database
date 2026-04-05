--스타토치 아카데미 의식 지원 함정
local s,id=GetID()
local SET_STAR_TORCH=0xc57

function s.initial_effect(c)
	--🔥 발동 (필수)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--①
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_SZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.rttg)
	e1:SetOperation(s.rtop)
	c:RegisterEffect(e1)

	--②
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.rscon)
	e2:SetTarget(s.rstg)
	e2:SetOperation(s.rsop)
	c:RegisterEffect(e2)

	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2b)
end

--공통 필터
function s.stfilter(c)
	return c:IsSetCard(SET_STAR_TORCH) and c:IsFaceup()
end

function s.ritualfilter(c,e,tp)
	return c:IsRace(RACE_CYBERSE) and c:IsType(TYPE_RITUAL)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end

-------------------------------------------------
--① 효과
-------------------------------------------------
function s.rttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.stfilter(chkc) end
	if chk==0 then
		return Duel.IsExistingTarget(s.stfilter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.ritualfilter,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.stfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND|LOCATION_GRAVE)
end

function s.rtop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or Duel.Destroy(tc,REASON_EFFECT)==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.ritualfilter,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,1,nil,e,tp)
	local rc=g:GetFirst()
	if rc and Duel.SpecialSummon(rc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
		--전투 파괴 내성
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		rc:RegisterEffect(e1)
	end
end

-------------------------------------------------
--② 효과
-------------------------------------------------
function s.rscon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c) return not c:IsType(TYPE_RITUAL) and c:IsFaceup() end,1,nil)
end

function s.relfilter(c)
	return c:IsReleasable()
end

function s.rstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.ritualfilter,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,nil,e,tp)
	end
end

function s.rsop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local rg=Duel.SelectMatchingCard(tp,s.ritualfilter,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,1,nil,e,tp)
	local rc=rg:GetFirst()
	if not rc then return end

	local lv=rc:GetLevel()

	--기본 릴리스
	local mg=Duel.GetMatchingGroup(s.relfilter,tp,LOCATION_HAND|LOCATION_MZONE,0,nil)

	--상대 필드 엑스트라 몬스터 존재 시 → 상대 릴리스 허용
	if Duel.IsExistingMatchingCard(function(c)
		return c:IsSummonType(SUMMON_TYPE_SPECIAL) and c:IsLocation(LOCATION_MZONE)
	end,tp,0,LOCATION_MZONE,1,nil) then
		local og=Duel.GetMatchingGroup(s.relfilter,tp,0,LOCATION_MZONE,nil)
		mg:Merge(og)
	end

	--레벨 합 선택
	local sg=aux.SelectUnselectGroup(mg,e,tp,1,99,function(g)
		return g:GetSum(Card.GetLevel)>=lv
	end,1,tp,HINTMSG_RELEASE)

	if #sg==0 then return end

	Duel.Release(sg,REASON_EFFECT)

	--의식 소환
	if Duel.SpecialSummon(rc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
		--필드 바운스
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
		local tg=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
		if #tg>0 then
			Duel.SendtoHand(tg,nil,REASON_EFFECT)
		end
	end
end