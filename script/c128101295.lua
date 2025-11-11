--앰포리어스 서포트 카드 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--①: 이 턴에 LP를 회복했을 경우, 프리체인 특수 소환 + 링크1 장착
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0,TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--②: LP 회복 시 장착된 링크 몬스터를 엑덱으로 되돌리고 다시 링크소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_RECOVER)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.sscon)
	e2:SetTarget(s.sstg)
	e2:SetOperation(s.ssop)
	c:RegisterEffect(e2)

	--LP 회복 체크용 글로벌 등록
	aux.GlobalCheck(s,function()
		local ge=Effect.CreateEffect(c)
		ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge:SetCode(EVENT_RECOVER)
		ge:SetOperation(s.checkop)
		Duel.RegisterEffect(ge,0)
	end)
end
s.listed_series={0xc46} --"앰포리어스"

---------------------------------------------------------------
-- 🔹 LP 회복 체크
---------------------------------------------------------------
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	Duel.RegisterFlagEffect(ep,id,RESET_PHASE|PHASE_END,0,1)
end

---------------------------------------------------------------
-- ① 프리체인 특수 소환 + 링크1 장착
---------------------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFlagEffect(tp,id)>0
end

function s.eqfilter(c,tp)
	return c:IsSetCard(0xc46) and c:IsType(TYPE_LINK) and c:GetLink()==1
		and (c:IsLocation(LOCATION_EXTRA) or c:IsLocation(LOCATION_GRAVE))
		and not c:IsForbidden()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.IsExistingMatchingCard(s.eqfilter,tp,LOCATION_EXTRA+LOCATION_GRAVE,0,1,nil,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_EXTRA+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectMatchingCard(tp,s.eqfilter,tp,LOCATION_EXTRA+LOCATION_GRAVE,0,1,1,nil,tp)
	local tc=g:GetFirst()
	if not tc then return end

	-- 장착 마법으로 취급
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_TYPE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	e1:SetValue(TYPE_SPELL+TYPE_EQUIP)
	tc:RegisterEffect(e1)

	-- 장착 처리
	if Duel.Equip(tp,tc,c) then
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetCode(EFFECT_EQUIP_LIMIT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		e2:SetValue(function(e,sc) return sc==e:GetOwner() end)
		tc:RegisterEffect(e2)
	end
end

---------------------------------------------------------------
-- ② LP 회복 시 장착 링크를 엑덱으로 되돌리고 특소
---------------------------------------------------------------
function s.sscon(e,tp,eg,ep,ev,re,r,rp)
	return ep==tp
end

function s.ssfilter(c,e,tp)
	local ec=c:GetEquipTarget()
	return c:IsFaceup() and c:IsType(TYPE_SPELL) and c:IsSetCard(0xc46)
		and c:GetOriginalType()&TYPE_LINK~=0
		and ec and ec:IsControler(tp)
		and c:IsAbleToExtra()
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end

function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_SZONE) and s.ssfilter(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.ssfilter,tp,LOCATION_SZONE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.ssfilter,tp,LOCATION_SZONE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.ssop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end

	local code=tc:GetOriginalCode()
	if Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==0 then return end
	Duel.BreakEffect()

	-- 동일 코드의 몬스터를 엑덱에서 특소
	local sc=Duel.GetFirstMatchingCard(function(c)
		return c:IsCode(code) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_LINK,tp,false,false)
	end,tp,LOCATION_EXTRA,0,nil)
	if sc then
		Duel.SpecialSummon(sc,SUMMON_TYPE_LINK,tp,tp,false,false,POS_FACEUP)
		sc:CompleteProcedure()
	end
end
