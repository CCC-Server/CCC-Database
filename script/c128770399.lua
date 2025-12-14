local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e0)

	-- E1: Archeoseeker monsters cannot be targeted by opponent's effects during Main Phase
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetRange(LOCATION_FZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetCondition(s.tgcon)
	e1:SetTarget(s.tgtg)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)

	-- E2: Archeoseeker battle → opponent cannot activate cards/effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(0,1)
	e2:SetValue(s.actlimit)
	c:RegisterEffect(e2)

	-- E3: If your Archeoseeker is destroyed by battle → Summon different Type
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DESTROYED)
	e3:SetRange(LOCATION_FZONE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- E1 조건: 메인 페이즈
function s.tgcon(e)
	return Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2
end
function s.tgtg(e,c)
	return c:IsSetCard(0x769)
end

-- E2: 전투 중일 때, 상대는 효과 발동 불가
function s.cfilter(e,re,tp)
	local ph=Duel.GetCurrentPhase()
	if ph~=PHASE_DAMAGE and ph~=PHASE_DAMAGE_CAL then return false end
	local tc=Duel.GetAttacker()
	local bc=Duel.GetAttackTarget()
	if not tc or not bc then return false end
	if tc:IsControler(tp) and tc:IsSetCard(0x769) then return true end
	if bc and bc:IsControler(tp) and bc:IsSetCard(0x769) then return true end
	return false
end
function s.actlimit(e,re,tp)
	return s.cfilter(e,re,tp)
end

-- E3: 전투로 파괴된 내 Archeoseeker → 타입이 다른 Archeoseeker 특수 소환
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c)
		return c:IsPreviousControler(tp) and c:IsSetCard(0x769) and c:IsType(TYPE_MONSTER)
	end,1,nil)
end
function s.spfilter(c,e,tp,except_type)
	return c:IsSetCard(0x769) and c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and c:GetRace()~=except_type
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local rc=eg:Filter(function(c)
		return c:IsPreviousControler(tp) and c:IsSetCard(0x769)
	end,nil):GetFirst()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp,rc:GetRace()) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
	e:SetLabel(rc:GetRace())
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local race=e:GetLabel()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp,race)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
