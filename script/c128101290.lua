local s,id=GetID()
function s.initial_effect(c)
	--①: Cyberse족 이외의 몬스터가 없을 때 패에서 특수 소환 + 링크1 앰포리어스 장착
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--②: 자신이 LP를 회복했을 때, 장착된 앰포리어스 링크 몬스터를 링크 소환 취급으로 특수 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_RECOVER)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE+LOCATION_SZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.sstg)
	e2:SetOperation(s.ssop)
	c:RegisterEffect(e2)
end
s.listed_series={0xc46}

--------------------------------------------------
-- ① Cyberse족 이외 몬스터가 없어야 발동
--------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	return g:FilterCount(function(c) return not c:IsRace(RACE_CYBERSE) end,nil)==0
end

function s.eqfilter(c,tp)
	return c:IsSetCard(0xc46) and c:IsType(TYPE_LINK) and c:GetLink()==1
		and not c:IsForbidden() and c:CheckUniqueOnField(tp)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.IsExistingMatchingCard(s.eqfilter,tp,LOCATION_EXTRA,0,1,nil,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if not c:IsRelateToEffect(e) then return end
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end

	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local tc=Duel.SelectMatchingCard(tp,s.eqfilter,tp,LOCATION_EXTRA,0,1,1,nil,tp):GetFirst()
	if not tc then return end

	-- 링크 몬스터를 장착 마법으로 취급
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_TYPE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	e1:SetValue(TYPE_SPELL+TYPE_EQUIP)
	tc:RegisterEffect(e1)

	-- 장착
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

--------------------------------------------------
-- ② 회복 시 장착된 링크 몬스터를 링크 소환 취급으로 특수 소환
--------------------------------------------------
function s.ssfilter(c,e,tp)
	return c:IsFaceup() and c:IsSetCard(0xc46)
		and c:IsType(TYPE_SPELL) -- 장착 마법 상태
		and c:GetOriginalType()&TYPE_LINK~=0 -- 원래 링크였던 카드만
		and c:GetEquipTarget()
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

	-- 원래 코드 저장
	local code=tc:GetOriginalCode()

	-- Extra Deck으로 되돌림
	if Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==0 then return end
	Duel.BreakEffect()

	-- Extra에서 원본 코드 찾기
	local g=Duel.GetMatchingGroup(function(c)
		return c:IsCode(code) and c:IsLocation(LOCATION_EXTRA)
			and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_LINK,tp,false,false)
	end,tp,LOCATION_EXTRA,0,nil)

	local sc=g:GetFirst()
	if not sc then return end

	-- 특수 소환 (링크 소환 취급)
	if Duel.SpecialSummon(sc,SUMMON_TYPE_LINK,tp,tp,false,false,POS_FACEUP)>0 then
		sc:CompleteProcedure()
	end
end
