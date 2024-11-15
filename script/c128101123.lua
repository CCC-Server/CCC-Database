-- 운마물 - 아이 오브 더 스트림즈
local s,id=GetID()
function s.initial_effect(c)
	-- Quick Effect Special Summon and Release
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Continuous Effect to Replace Destruction with Counter Removal
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.desreptg)
	e2:SetValue(s.desrepval)
	e2:SetOperation(s.desrepop)
	c:RegisterEffect(e2)
end

-- Filter for Special Summon / Release
function s.spcfilter(c,tp)
	return (c:IsSetCard(0x18) and c:IsReleasableByEffect() and c:IsFaceup()) 
		or (c:GetCounter(0x1019)>0 and c:IsFaceup()) -- 포그 카운터가 있는 경우도 포함
end

-- Special Summon Targeting
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.spcfilter(chkc,tp) end
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingTarget(s.spcfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectTarget(tp,s.spcfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_RELEASE,g,1,0,0)
end

-- Special Summon Operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.Release(tc,REASON_EFFECT)>0 then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- Destruction Replace Filter (For "운마물" Monsters or Fog Counter Monsters)
function s.repfilter(c,tp)
	return c:IsFaceup() and c:IsLocation(LOCATION_MZONE) 
		and c:IsControler(tp) 
		and (c:IsSetCard(0x18) or c:GetCounter(0x1019)>0) -- 운마물 몬스터 또는 포그 카운터가 있는 경우
		and c:IsReason(REASON_BATTLE+REASON_EFFECT) 
		and not c:IsReason(REASON_REPLACE)
end

-- Destruction Replace Targeting
function s.desreptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return eg:IsExists(s.repfilter,1,nil,tp)
		and Duel.IsCanRemoveCounter(tp,1,0,0x1019,1,REASON_EFFECT) end
	return Duel.SelectEffectYesNo(tp,c,96)
end

-- Destruction Replace Value
function s.desrepval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end

-- Destruction Replace Operation (Remove Counter)
function s.desrepop(e,tp,eg,ep,ev,re,r,rp)
	Duel.RemoveCounter(tp,1,0,0x1019,1,REASON_EFFECT+REASON_REPLACE)
end
